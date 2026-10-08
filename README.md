# Billing document validation for SAP S/4HANA Cloud Public Edition

Project documentation is in [DOCUMENTATION.md](DOCUMENTATION.md). This file is the activation and configuration runbook.

On-stack ABAP Cloud application that runs every custom billing check through one engine. Configurable field rules are maintained in a Fiori elements app. Coded checks are plug-in classes switched on from the same app. Thin BAdI adapters turn a failed check into the block each released billing hook actually supports.

Target release: SAP Cloud ERP / S/4HANA Cloud Public Edition 2602 or later, so `SD_BIL_PBD_ACTION_CHECK` exists. Creation and cancellation adapters also work on 2508. ABAP language version: ABAP for Cloud Development.

This repository cannot activate the objects. Activation is in ABAP Development Tools against the tenant.

## What a failed check can stop

Public cloud has no general check-before-save for a final billing document (SAP KBA 3227690). Changing a billing document in Manage Billing Documents is not covered. Release to accounting is not covered by a sales-billing BAdI. A billing-content rule that must stop posting has to be a creation rule or a preliminary-billing rule. Accounting-only checks stay in Manage Substitution/Validation Rules.

| Checkpoint | Code | Released BAdI | What a blocking error does |
| --- | --- | --- | --- |
| Create billing document | `CREATE` | `SD_BIL_DATA_TRANSFER` | Rejects the current item. Earlier items in the same run are already accepted, so a whole-document rule belongs on preliminary billing. |
| Finalize preliminary billing document | `PBD_FINAL` | `SD_BIL_PBD_ACTION_CHECK` | Returns an error and blocks finalization. Header and items are both available. |
| Create billing document from preliminary | `PBD_CREATE` | `SD_BIL_PBD_ACTION_CHECK` | Blocks creation of the billing document. |
| Auto-finalize | `PBD_AUTO` | `SD_BIL_PBD_ACTION_CHECK` | Blocks auto-finalize. The preliminary document stays in progress. |
| Preliminary billing approval | `APPROVAL` | `SD_BIL_APM_SET_APPROVAL_REASON` | Does not reject. Sets the approval reason on the rule so the standard workflow stops finalization. |
| Cancel billing document | `CANCEL` | `SD_BIL_FLEX_CANCELLATION` | Rejects the cancellation. Clearing status is not available for FI-CA, external finance, or Central Finance documents created before 2102. |
| Customer add or change | `CUSTOMER` | `CMD_VALIDATE_CUSTOMER` | Stops save in Manage Customer Master Data. `CUST_ADD` is create only. `CUST_UPD` is change only. |
| Material add or change | `MATERIAL` | `BD_CMD_PROD_DATA_API_CHECK_2` | Stops save in Manage Product Master Data. `MAT_ADD` is create only. `MAT_UPD` is change only. |

An empty checkpoint on a rule or plug-in means the check runs at every billing checkpoint. It does not run when a customer or a material is saved. A warning is written to the application log and does not block. On a customer save the released BAdI shows every returned message as an error, so a customer warning is logged and is not sent back to the app.

`SD_BIL_DATA_TRANSFER` is called once per item. Document-level rules on create do not wait for a last item. They either read the preceding document (`I_SalesOrderItem` in the preceding plug-in) or they are configured for a preliminary-billing checkpoint, which sees the whole document.

## Import

1. In the tenant, create software component `ZBD_BILVAL` (or use the component you already develop in) and clone it in ABAP Development Tools.
2. Link this repository with abapGit and pull into a package whose ABAP language version is ABAP for Cloud Development. Suggested package name: `ZBD_BILVAL`.
3. Activate in this order:
   - Tables `ZBILVAL_CONFIG`, `ZBILVAL_RULE`, `ZBILVAL_COND`, `ZBILVAL_PLUGIN`, and message class `ZBILVAL_MSG`.
   - CDS views, metadata extensions, behavior definitions, and behavior pool `ZBP_I_BILVALCONFIG`.
   - Engine, field catalog, factory, log, plug-ins, query providers, master-data classes (`ZCL_BILVAL_MD_LOOKUP`, `ZCL_BILVAL_MD_MAPPER`, `ZCL_BILVAL_MD_CUSTOMER`, `ZCL_BILVAL_MD_PRODUCT`), and `ZCL_BILVAL_SETUP`.
   - Service binding `ZUI_BILVAL_O4` after the views are active.
   - The four billing BAdI classes, `ZCL_BILVAL_BADI_PRODUCT`, and `ZTC_BILVAL_ENGINE` last. They reference released interfaces and will not activate until the method names match the tenant. See [Align the BAdI methods](#align-the-badi-methods). The unit test calls the customer and material checkers, so those master-data classes must be active first. `ZCL_BILVAL_BADI_PRODUCT` is not used by the unit test.
4. Publish service binding `ZUI_BILVAL_O4` locally (OData V4, UI).
5. In ADT, run class `ZCL_BILVAL_SETUP` as an ABAP application (F9). It creates configuration row `BILVAL` and inactive plug-in rows `ZERO_PRICE` and `PRECEDING`.

`ZTC_BILVAL_ENGINE` is the ABAP Unit suite. Run it from ADT after the BAdI classes activate. It covers operators, filters, severity, unknown fields, plug-in order, the zero-amount plug-in, the preceding-document plug-in, item rejection, and preliminary-billing action mapping. It does not call a BAdI.

## Fiori app and catalog

The service binding exposes one configuration object with two lists: rules (and their conditions) and plug-ins.

Create these objects in ABAP Development Tools. They are tenant IAM objects and are not in this repository.

1. New IAM app, for example `ZBILVAL_RULE_UI`, type UI, based on service binding `ZUI_BILVAL_O4`, main entity `BillingValidationConfig`.
2. New business catalog `ZBILVAL_BC`. Assign the IAM app to that catalog.
3. Assign the catalog to a business role for the people who maintain billing rules.

Billing clerks who post invoices do not need this catalog. The BAdI reads the customizing tables directly.

Rules are customizing (delivery class C). In ADT, create a Business Configuration Maintenance Object named `ZBILVAL_CONFIG` for CDS entity `ZI_BilValConfig` and service binding `ZUI_BILVAL_O4`. That object is what records rule changes on a customizing transport. The generator in ADT can create this object from the tables if you prefer to regenerate the UI; keep the validations in `ZBP_I_BILVALCONFIG`.

Create application log object `ZBILVAL` with subobject `RUN` (ADT: New, Application Log Object). Errors and warnings are saved there. If the log object does not exist yet, billing still continues; the log write is caught.

## Configurable rules

Open the configuration object `BILVAL`. Add a rule, then add conditions on the object page. All conditions on one rule are AND. Rules run in ascending sequence, then active plug-ins run in ascending sequence.

- Scope `H` is the header. Scope `I` is the item.
- Operators: `INIT`, `NOT_INIT`, `EQ`, `NE`, `GT`, `LT`, `GE`, `LE`, `BETWEEN`, `IN_LIST` (comma-separated), `FIELD_EQ`.
- Comparisons are numeric when both values are numbers, so `10` is greater than `9`. Other comparisons are case-insensitive. A zero amount or a zero date matches `INIT`.
- Filters that you leave empty match every document: billing type, sales organization, company code, sold-to party, item category.
- Severity `E` blocks through the adapter. Severity `W` is logged only.
- Outcome `BLOCK` rejects. Outcome `REQUIRE_APPROVAL` is for checkpoint `APPROVAL` and needs an approval reason. An approval checkpoint also requires an approval reason on a blocking rule, because that hook cannot reject.
- The field value help lists the catalog in `ZCL_BILVAL_FIELDS`. A name that starts with `YY1_` is accepted without a code change. Any other unknown field cannot be saved. If one is inserted directly into the table, the run skips that rule and logs a warning.
- Customer fields (`CUSTOMERNAME`, `COUNTRY`, `ACCOUNTGROUP`, `TAXNUMBER`, `PAYMENTTERMS`, `INCOTERMS`, `RECONCILIATIONACCT`, `RECORDTYPE`) are evaluated only on `CUSTOMER`, `CUST_ADD`, and `CUST_UPD`. Material fields (`PRODUCTTYPE`, `PRODUCTGROUP`, `BASEUNIT`, `PLANT`, `PROFITCENTER`, `PURCHASINGGROUP`, header `MATERIAL`) are evaluated only on `MATERIAL`, `MAT_ADD`, and `MAT_UPD`. A rule that uses one of these fields on a billing checkpoint is skipped.
- `RECORDTYPE` is `SALES` for a customer sales area and `COMPANY` for a customer company code. A sales-area rule needs an item condition on `RECORDTYPE`. The sales-organization filter on the rule header is filled only when the customer has one sales area.
- A rule with no conditions does not match. It is logged and skipped, so an unfinished rule cannot block every invoice.

Publish custom fields in the Custom Fields app on the Sales: Billing Document context, and enable them for the billing BAdI business context, before a `YY1_` rule can see a value.

## Plug-ins

Both sample plug-ins are inserted inactive by `ZCL_BILVAL_SETUP`.

- `ZERO_PRICE` rejects an item whose net amount is zero.
- `PRECEDING` reads `I_SalesOrderItem`. On a complete document (preliminary billing) it rejects when a sales-order item is missing from the billing items. On create, where only the current item is known, it rejects when that item is not on the sales order. A failed read is a warning and does not block billing.

To add a plug-in:

1. Implement `ZIF_BILVAL_CHECK`.
2. Add a constant, a catalog row, and a `WHEN` branch in `ZCL_BILVAL_FACTORY`. ABAP for Cloud Development does not allow `CREATE OBJECT` from a configured class name, so the factory is the only place that constructs plug-ins.
3. Activate the class, then run `ZCL_BILVAL_SETUP` again or create the plug-in row in the app. Leave it inactive until you have tested it.
4. An unknown plug-in id cannot be saved. At runtime an unknown id is logged and skipped.

## Align the BAdI methods

Before the first activation, open the released interface in ADT (Released Objects, or the BAdI in the Business Accelerator Hub under On-Stack Extensibility) and rename the method if it differs. Keep the `apply` call. The parameter names below are the ones used in working Custom Logic examples and in the BAdI documentation. Copy the standard data into the result structures before any rejection flag is set. An empty result structure clears the billing fields.

Do not also implement the same filter in the Custom Logic app. One implementation owns each filter. The approval BAdI allows only one implementation in the system.

### Create: `ZCL_BILVAL_BADI_TRANSFER`

- Enhancement spot `ES_PF_BILLING_DT`, BAdI `SD_BIL_DATA_TRANSFER`, interface `IF_SD_BIL_DATA_TRANSFER`.
- Method implemented as `change_data`.
- Filter value: `ZBILVAL_TRANSFER`.
- Copies `bil_doc`, `bil_doc_item`, and `bil_doc_item_contr` into `bil_doc_res`, `bil_doc_item_res`, and `bil_doc_item_contr_res`.
- On a blocking error, sets `billingdocumentitemisrejected` and `billgdocitmrejectionreasontext`.

### Cancel: `ZCL_BILVAL_BADI_CANCEL`

- Same enhancement spot, BAdI `SD_BIL_FLEX_CANCELLATION`, interface `IF_SD_BIL_FLEX_CANCELLATION`.
- Method implemented as `check_cancellation`.
- Copies `cancellation_bil_doc` to `cancellation_bil_doc_res`.
- On a blocking error, sets `bil_doc_canc_is_rejected` and `rejection_reason_text`.
- Header fields only. Item rules do not see items on this hook.

### Approval: `ZCL_BILVAL_BADI_APPROVAL`

- Enhancement spot `ES_SD_BIL_EXTEND`, BAdI `SD_BIL_APM_SET_APPROVAL_REASON`, interface `IF_SD_BIL_APM_SET_APPR_REASON`.
- Method implemented as `set_approval_reason`.
- Reads `billingprocdocument` and `billingprocdocumentitem`.
- Sets `billingprocdocapprovalreason` when a matching rule has an approval reason. It does not reject.

### Preliminary billing check: `ZCL_BILVAL_BADI_PBD`

- BAdI `SD_BIL_PBD_ACTION_CHECK`, interface `IF_SD_BIL_PBD_ACTION_CHECK` (Cloud ERP 2602). Confirm the enhancement spot in the tenant; it is not the same object as the older data-transfer spot.
- Method implemented as `check`.
- Reads `billingprocdocument`, `billingprocdocumentitem`, and `action`.
- Appends a row with `messagetype = 'E'` and `messagetext` to `messages` when the check blocks.
- Action text containing `AUTO` maps to `PBD_AUTO`, `CREAT` to `PBD_CREATE`, and `FINAL` to `PBD_FINAL`. Anything else is treated as finalize.
- If the released item parameter is a structure rather than a table, pass it to `apply` as `item` instead of `items`. If the message parameter uses different component names, map `reason_text` onto those components. The check logic stays in `apply`.

### Customer save: `ZCL_BILVAL_MD_CUSTOMER`

`CMD_VALIDATE_CUSTOMER` is the released check for Manage Customer Master Data (F0850A). It runs on add and on change. It does not run in the classic Maintain Business Partner app.

Create the implementation in the Custom Logic app, business context for the customer core view, BAdI Validate Customer (`CMD_VALIDATE_CUSTOMER`). Publish this call, and pass the sales-area table and the company-code table under the names shown in that method signature:

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

If a parameter name differs, keep the left-hand side (`sales`, `companies`, `validation_messages`) and replace the right-hand side with the parameter from the signature. A sales-area rule does nothing until `sales` receives the sales-area table.

Create versus change is decided by reading `I_Customer`. When that read fails, only rules with checkpoint `CUSTOMER` run.

### Material save: `ZCL_BILVAL_BADI_PRODUCT`

BAdI `BD_CMD_PROD_DATA_API_CHECK_2` (Extended Checks for Product Master Tables) runs when Manage Product Master Data saves a material, on add and on change.

In ADT, create an enhancement implementation for that BAdI and use implementing class `ZCL_BILVAL_BADI_PRODUCT`. Set the runtime behavior to Active. The class calls `ZCL_BILVAL_MD_PRODUCT`.

The released method is `CHECK_DATA`, with `it_data` and `ct_message`. If activation says the interface or the method has another name, change that line in `ZCL_BILVAL_BADI_PRODUCT` and pass the product table and the message table into `validate_product`. Plant rows are read from the table component that contains `PLANT`.

Create versus change is decided by reading `I_Product`. When that read fails, only rules with checkpoint `MATERIAL` run. Use `MATERIAL` when the same check applies to both add and change.

## Configuration that code cannot transport

Register the BAdI filter values as routines, then assign the routines in copying control for every flow you bill. A routine that is not assigned never runs.

Data transfer, configuration activity Define Custom Routines for Data Transfer to Billing Documents (102865):

1. Register routine `3009001` (any free number from `3000000` to `3009999`).
2. Assign enhancement id `ZBILVAL_TRANSFER` to that routine.
3. Assign routine `3009001` in copying control for each combination you use:
   - Sales document to billing document (activity 102762), for example OR to F2, and the item categories you bill.
   - Delivery to billing document.
   - Billing document to billing document, for credit memos and debit memos.
   - Intercompany billing, if you use it.

Cancellation, configuration activity Define Custom Routines for Flexible Billing Document Cancellation:

1. Register a routine, for example `3009002`.
2. Assign the cancellation enhancement id you entered on `ZCL_BILVAL_BADI_CANCEL`.
3. Assign that routine to the billing types that may be cancelled.

Approval:

1. Define an approval request reason, for example `0001`, and assign it to preliminary billing documents.
2. Use that reason on rules with checkpoint `APPROVAL`.
3. In Manage Preliminary Billing Documents Workflows, publish a workflow whose start condition is that reason before you activate the rule. An approval reason without a published workflow leaves the document waiting for an approver that will never be notified.

## Manual test

Use a copy of a real billing chain in a quality tenant. Run `ZCL_BILVAL_SETUP` first.

1. Rule, checkpoint `CREATE`, severity `E`, item scope, field `NETAMOUNT`, operator `EQ`, value `0`. Create a billing document that contains a zero-amount item. The item is rejected and the reason text is the rule message. Other items in the run can still be billed.
2. Change that rule to severity `W` and repeat. The item is billed. Application log object `ZBILVAL`, subobject `RUN`, contains the warning.
3. In the app, try to save a condition with field `NOT_A_FIELD`. The save fails. Billing is not involved.
4. Rule, checkpoint `PBD_FINAL`, severity `E`, header scope, field `SOLDTOPARTY`, operator `EQ`, and a sold-to you can bill. Create a preliminary billing document for that sold-to and finalize it. Finalization stops with the rule message. A different sold-to finalizes.
5. Repeat with checkpoints `PBD_CREATE` and `PBD_AUTO` if you use those actions.
6. Rule, checkpoint `APPROVAL`, outcome `REQUIRE_APPROVAL`, approval reason `0001`, and a sold-to condition. Publish the workflow first. Finalizing the preliminary billing document sets the approval reason and starts the workflow instead of posting the invoice.
7. Rule, checkpoint `CANCEL`, header field `CLEARINGSTATUS`, operator `EQ`, and the status value shown on a cleared invoice in Manage Billing Documents. Cancelling that invoice is rejected. Cancelling an open invoice is allowed. Skip this test when the document is in FI-CA or external finance.
8. Deactivate the zero-amount rule. Activate plug-in `ZERO_PRICE` and repeat step 1. Deactivate the plug-in again.
9. Activate plug-in `PRECEDING`. Bill only one item of a two-item sales order into a preliminary billing document and finalize. Finalization reports the missing sales-order item. Create-from-due-list only checks the current item, because the other billing items are not in that call.
10. Release a billing document to accounting with a rule that would have failed at creation. Posting is not stopped by this app. Put that rule on `CREATE` or `PBD_FINAL` if it must stop the invoice.

## Rules the engine will not block

- A change to an existing billing document.
- Release to financial accounting, including billing types that post immediately. There is no released sales-billing check in that save, and the new billing document is not readable from a released CDS view while that same save is still open.
- A whole-document condition evaluated only on `SD_BIL_DATA_TRANSFER`. Use preliminary billing for that condition, or a plug-in that reads the preceding document.
