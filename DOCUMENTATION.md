# Billing and master-data validation

On-stack application for SAP S/4HANA Cloud Public Edition (SAP Cloud ERP). It checks billing documents, customers, and materials with rules maintained in one Fiori elements app. Coded checks are plug-ins switched on from the same app.

Language version: ABAP for Cloud Development. Target release: 2602 or later, so the preliminary-billing check exists. Billing creation and cancellation also run on 2508.

The code in this folder does not run by itself. It runs only after it is pulled into the development system and activated there.

## What it is for

Billing clerks, customer-master clerks, and product-master clerks keep using the standard apps. A failed rule stops the save those apps already perform. People who maintain the rules use a separate app and do not need to post invoices.

| Moment | App the user is in | What a blocking rule does |
| --- | --- | --- |
| Create billing document | Create Billing Documents | Rejects the current item. The item stays billing-due. Other items in the same run can still be invoiced. |
| Finalize a preliminary billing document | Manage Preliminary Billing Documents | Stops finalization. Header and items are both available. |
| Create a billing document from a preliminary document | Manage Preliminary Billing Documents | Stops creation of the invoice. |
| Auto-finalize | Preliminary billing | Leaves the preliminary document in progress. |
| Approval of a preliminary billing document | Manage Preliminary Billing Documents | Does not reject. Sets the approval reason so the standard workflow stops finalization. |
| Cancel a billing document | Cancel Billing Documents | Rejects the cancellation. |
| Add or change a customer | Manage Customer Master Data | Stops the save. |
| Add or change a material | Manage Product Master Data | Stops the save. |

## What it does not stop

- A change to a billing document that was already saved.
- Release of a billing document to accounting, including billing types that post as soon as they are created.
- The classic Maintain Business Partner app. Customer rules run in Manage Customer Master Data only.
- A customer warning. That BAdI shows every returned message as an error, so a warning is written to the application log and is not sent back to the screen.
- A rule with no conditions. It is logged and skipped, so an unfinished rule cannot block every document.
- An unknown field or an unknown plug-in at runtime. The rule or plug-in is logged and skipped. The app itself refuses an unknown field or plug-in when the rule is saved.

Public cloud has no general check-before-save for a final billing document (SAP KBA 3227690). A check that must stop an invoice has to run at creation or on a preliminary billing document.

## How a check runs

```text
Standard app save
        |
        v
Released BAdI  ----->  adapter class  ----->  engine
                                                |
                          rules (customizing tables) and active plug-ins
                                                |
                                                v
                          block, approval reason, or application log
```

One engine evaluates every check. The adapters only translate the BAdI data into that engine and translate the result back into the flag or message the BAdI understands.

Rules run first, in ascending sequence. Active plug-ins run after the rules, also in ascending sequence. All conditions on one rule are combined with AND. Filters that you leave empty match every document: billing type, sales organization, company code, sold-to party, item category.

Severity `E` blocks. Severity `W` is logged and does not block, except on a customer save, where warnings are only logged. Outcome `BLOCK` rejects. Outcome `REQUIRE_APPROVAL` is for checkpoint `APPROVAL` and needs an approval reason.

Comparisons are numeric when both values are numbers, so `10` is greater than `9`. Other comparisons ignore case. A zero amount or a zero date matches `INIT`.

An empty checkpoint means every billing checkpoint. It does not run when a customer or a material is saved. Customer fields are evaluated only on customer checkpoints. Material fields are evaluated only on material checkpoints. A `YY1_` custom field is accepted without a code change once it is published in Custom Fields and enabled for the BAdI context.

Create versus change for a customer is decided by reading `I_Customer`. For a material it is decided by reading `I_Product`. If that read fails, only the combined checkpoint runs (`CUSTOMER` or `MATERIAL`), not the add-only or change-only checkpoint.

Billing creation calls the check once per item. A rule that needs every item on the document belongs on preliminary billing. The preceding-document plug-in can also read the sales order, because the billing BAdI does not wait for a last item.

## Checkpoints

| Code | When it runs |
| --- | --- |
| `CREATE` | Billing document creation |
| `PBD_FINAL` | Finalize preliminary billing document |
| `PBD_CREATE` | Create billing document from preliminary |
| `PBD_AUTO` | Auto-finalize |
| `APPROVAL` | Preliminary billing approval |
| `CANCEL` | Cancel billing document |
| `CUSTOMER` | Customer add and change |
| `CUST_ADD` | Customer add only |
| `CUST_UPD` | Customer change only |
| `MATERIAL` | Material add and change |
| `MAT_ADD` | Material add only |
| `MAT_UPD` | Material change only |

Use `CUSTOMER` or `MATERIAL` when the same check applies to both add and change.

## Where each check is hooked

| Checkpoint | BAdI | Class |
| --- | --- | --- |
| `CREATE` | `SD_BIL_DATA_TRANSFER`, filter `ZBILVAL_TRANSFER` | `ZCL_BILVAL_BADI_TRANSFER` |
| `PBD_FINAL`, `PBD_CREATE`, `PBD_AUTO` | `SD_BIL_PBD_ACTION_CHECK` | `ZCL_BILVAL_BADI_PBD` |
| `APPROVAL` | `SD_BIL_APM_SET_APPROVAL_REASON` | `ZCL_BILVAL_BADI_APPROVAL` |
| `CANCEL` | `SD_BIL_FLEX_CANCELLATION` | `ZCL_BILVAL_BADI_CANCEL` |
| `CUSTOMER`, `CUST_ADD`, `CUST_UPD` | `CMD_VALIDATE_CUSTOMER` | `ZCL_BILVAL_MD_CUSTOMER`, called from Custom Logic |
| `MATERIAL`, `MAT_ADD`, `MAT_UPD` | `BD_CMD_PROD_DATA_API_CHECK_2` | `ZCL_BILVAL_BADI_PRODUCT` |

`SD_BIL_DATA_TRANSFER` runs only when copying control points at routine `3009001`. For item category `TAN` the invoice is created from the delivery, so the routine has to be on delivery-to-billing copy control (`LF` to `F2`), not only on the order.

Do not implement the same BAdI filter again in the Custom Logic app. One implementation owns each filter. The approval BAdI allows only one implementation in the system.

Method names on the billing and product classes must match the released interface in the tenant before those classes activate. The behavior of each class stays in its `apply` or `validate_product` method. [README.md](README.md) lists the parameter names to align.

The customer check is published in Custom Logic:

```abap
NEW zcl_bilval_md_customer( )->validate_customer(
  EXPORTING
    partner_key = i_cmd_bp_object_key
    general     = it_customer_gen
    sales       = it_customer_sales_area
    companies   = it_customer_company
  CHANGING
    validation_messages = ct_validationmessage ).
```

If a parameter name in the signature differs, keep the left-hand side and replace the right-hand side. A sales-area rule does nothing until `sales` receives the sales-area table.

## Rules and plug-ins

Open configuration `BILVAL` in the validation app. Add a rule, then add its conditions on the object page.

| Property | Meaning |
| --- | --- |
| Checkpoint | When the rule runs. Empty means every billing checkpoint. |
| Outcome | `BLOCK` or `REQUIRE_APPROVAL` |
| Severity | `E` blocks. `W` is logged. |
| Filters | Billing type, sales organization, company code, sold-to, item category. Empty matches all. |
| Scope `H` | Header field |
| Scope `I` | Item, sales area, company code, or plant |
| Operators | `INIT`, `NOT_INIT`, `EQ`, `NE`, `GT`, `LT`, `GE`, `LE`, `BETWEEN`, `IN_LIST`, `FIELD_EQ` |

`RECORDTYPE` is `SALES` on a customer sales area and `COMPANY` on a customer company code. A sales-area rule needs a condition on `RECORDTYPE`. The sales-organization filter on the rule is filled only when the customer has one sales area, so a sales-area check should use an item condition.

Two plug-ins are delivered inactive:

| Plug-in | Behavior |
| --- | --- |
| `ZERO_PRICE` | Rejects an item whose net amount is zero. |
| `PRECEDING` | On preliminary billing, rejects the document when a sales-order item is missing. On ordinary billing creation, checks only that the current item exists on the sales order. A failed read is a warning and does not block. |

A new plug-in is a class that implements `ZIF_BILVAL_CHECK`, a branch in `ZCL_BILVAL_FACTORY`, and a row in the app. ABAP for Cloud Development does not create objects from a configured class name, so the factory is the only place that constructs plug-ins.

## Who needs access

| Person | Access |
| --- | --- |
| Someone who maintains rules | Business catalog `ZBILVAL_BC`, IAM app `ZBILVAL_RULE_UI`, service binding `ZUI_BILVAL_O4` |
| Billing clerk, customer clerk, product clerk | The standard apps only. The checks read the customizing tables directly. |

The rule UI is the Fiori elements app generated from service binding `ZUI_BILVAL_O4`. There is no separate UI5 project. Users open `BillingValidationConfig` and then the single row `BILVAL`.

## Deployment

Two deliveries leave the development system. They are imported in this order: code first, then customizing.

| What | Where it is built | How it moves |
| --- | --- | --- |
| ABAP classes, tables, CDS, service binding | Development system, client 080, software component `ZBD_BILVAL` | Release the software component. Test imports it, then production. |
| Rules, copy-control routines, business role, Custom Logic | Development system, client 100 | Customizing transport, after the code is in the target system |

### Into the development system

1. Push this folder to a Git remote the SAP system can reach over HTTPS.
2. In ABAP Development Tools, clone software component `ZBD_BILVAL` and pull the repository with abapGit into package `ZBD_BILVAL`.
3. Activate in the order in [README.md](README.md), publish `ZUI_BILVAL_O4`, and run `ZCL_BILVAL_SETUP` once.
4. Create the IAM app, catalog, business configuration maintenance object `ZBILVAL_CONFIG`, and application log `ZBILVAL` / `RUN`.
5. Assign routine `3009001` in copying control, register the cancellation routine, and publish the customer check in Custom Logic.
6. Enter rules in the app. Save them on a customizing transport.

The folder on a PC does not execute the checks. After the pull has succeeded and the same commit is on the Git remote, that local copy can be deleted. Keep the remote. The next change starts from it.

### What stays

Keep the SAP development system and package `ZBD_BILVAL`. Test and production receive a released copy. The next correction still starts in development. Deleting the package in development and releasing that deletion removes the validations from test and production as well.

## Tests already written

| Document | What it walks through |
| --- | --- |
| [SCENARIO.md](SCENARIO.md) | Quality-tenant invoice: priced item `TG11` is billed, free-of-charge item `TG12` is rejected, then a warning, then a preliminary-billing completeness check |
| [SCENARIO-MASTERDATA.md](SCENARIO-MASTERDATA.md) | New customer in sales area 1010 / 10 / 00 must use account assignment group `01`. Material `TG-BILVAL` in plant 1010 must have a profit center. Both are tested on add and on change. |

`ZTC_BILVAL_ENGINE` is the ABAP Unit suite. Run it from ADT after the billing BAdI classes activate. It does not call a BAdI and it does not post a document.

Messages that do run are in application log object `ZBILVAL`, subobject `RUN`. If that log object is missing, billing still continues. The log write is caught.

## Main objects

| Object | Role |
| --- | --- |
| `ZBILVAL_CONFIG`, `ZBILVAL_RULE`, `ZBILVAL_COND`, `ZBILVAL_PLUGIN` | Customizing tables |
| `ZI_BILVALCONFIG` and the projection `ZC_BILVALCONFIG` | RAP business configuration |
| `ZUI_BILVAL_O4` | OData V4 UI service binding |
| `ZCL_BILVAL_ENGINE` | Evaluates rules and plug-ins |
| `ZCL_BILVAL_FIELDS` | Field catalog and checkpoints |
| `ZCL_BILVAL_FACTORY` | Constructs plug-ins |
| `ZCL_BILVAL_SETUP` | Inserts configuration `BILVAL` and the inactive sample plug-ins |
| `ZCL_BILVAL_BADI_TRANSFER`, `_PBD`, `_APPROVAL`, `_CANCEL` | Billing adapters |
| `ZCL_BILVAL_MD_CUSTOMER` | Customer save |
| `ZCL_BILVAL_BADI_PRODUCT` | Material save |
| `ZBILVAL_MSG` | Message class used when a master-data save is rejected |
