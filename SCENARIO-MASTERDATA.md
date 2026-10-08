# Quality-tenant scenario: customer and material save

Run this after the billing validation objects are active and class `ZCL_BILVAL_SETUP` has been executed once. The rules are entered in the same app, configuration `BILVAL`.

Use sales area **1010 / 10 / 00**, company code 1010, and plant 1010. On a US starter system, use **1710 / 10 / 00**, plant 1710, and read the profit center from product `TG11` in plant 1710.

These checks run when someone saves a customer or a material. They do not use billing copy control. Leave customer `10100001` unchanged. Create a new customer for this test.

## 1. Enter the rules

Deactivate plug-ins `ZERO_PRICE` and `PRECEDING`, and deactivate rule `R-ZERO` if it is still active from the billing scenario.

### Customer

| Field | Value |
| --- | --- |
| Rule ID | `R-CUST-AAG` |
| Description | Domestic customers use account group 01 |
| Checkpoint | `CUSTOMER` |
| Outcome | `BLOCK` |
| Severity | `E` |
| Message text | Domestic sales area 1010 needs account assignment group 01. |
| Active | yes |
| Sequence | `20` |

`CUSTOMER` runs on add and on change. `CUST_ADD` is create only. `CUST_UPD` is change only.

Conditions, all item scope:

| Position | Scope | Field | Operator | Value |
| --- | --- | --- | --- | --- |
| 1 | `I` | `RECORDTYPE` | `EQ` | `SALES` |
| 2 | `I` | `SALESORGANIZATION` | `EQ` | `1010` |
| 3 | `I` | `DISTRIBUTIONCHANNEL` | `EQ` | `10` |
| 4 | `I` | `DIVISION` | `EQ` | `00` |
| 5 | `I` | `CUSTOMERACCOUNTASSIGNMENTGROUP` | `NE` | `01` |

### Material

| Field | Value |
| --- | --- |
| Rule ID | `R-MAT-PC` |
| Description | Plant 1010 needs a profit center |
| Checkpoint | `MATERIAL` |
| Outcome | `BLOCK` |
| Severity | `E` |
| Message text | Plant 1010 needs a profit center. |
| Active | yes |
| Sequence | `30` |

`MATERIAL` runs on add and on change. `MAT_ADD` is create only. `MAT_UPD` is change only.

| Position | Scope | Field | Operator | Value |
| --- | --- | --- | --- | --- |
| 1 | `I` | `PLANT` | `EQ` | `1010` |
| 2 | `I` | `PROFITCENTER` | `INIT` | |

## 2. Connect the customer check

App **Custom Logic**. Create an implementation of BAdI **Validate Customer** (`CMD_VALIDATE_CUSTOMER`) for the customer master context.

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

Publish it. If the editor does not know one of the right-hand names, open the method signature and pass the sales-area table into `sales` and the company-code table into `companies`. Keep the left-hand names. This BAdI runs in **Manage Customer Master Data**. It does not run in Maintain Business Partner.

## 3. Connect the material check

In ABAP Development Tools, create an enhancement implementation for BAdI `BD_CMD_PROD_DATA_API_CHECK_2`. Implementing class: `ZCL_BILVAL_BADI_PRODUCT`. Runtime behavior: Active.

If that class does not activate, the released interface name in your tenant is different. Change the interface on `ZCL_BILVAL_BADI_PRODUCT` to the name ADT shows, and pass the product data table and the message table into `validate_product`.

## 4. Add a customer

App **Manage Customer Master Data**. Create an organization customer in sales area 1010 / 10 / 00. Use customer `10100001` only as a reference for the usual values (country, company code, reconciliation account, payment terms). Set the account assignment group of sales area 1010 / 10 / 00 to `02`.

Save.

### Expected result

- The customer is not saved.
- The message is `Domestic sales area 1010 needs account assignment group 01.`

Set the account assignment group to `01` and save again. The customer is saved. Write down the new customer number.

If the customer with group `02` is saved, the Custom Logic call is not receiving the sales-area table. Fix the `sales` parameter and repeat.

## 5. Change that customer

Open the customer from step 4. Change the account assignment group from `01` to `03`. Save.

### Expected result

- The change is not saved.
- The same message is shown.

Set the group back to `01` and save. The change is saved.

## 6. Add a material

In **Manage Product Master Data**, open `TG11` and write down the profit center on plant 1010. On a standard Best Practice client it is often `YB600`.

Create a trading good, for example `TG-BILVAL`, with the same product type and product group as `TG11`. Extend plant 1010 and leave the profit center empty. Save.

### Expected result

- The material is not saved.
- The message is `Plant 1010 needs a profit center.`

Enter the profit center you wrote down from `TG11` and save again. The material is saved.

## 7. Change that material

Open `TG-BILVAL`. Clear the profit center on plant 1010. Save.

### Expected result

- The change is not saved.
- The same message is shown.

Put the profit center back and save. The change is saved.

## 8. What you should have at the end

| Check | Where | Result |
| --- | --- | --- |
| Account assignment group not 01 | New customer, sales area 1010 / 10 / 00 | Save stops on add and on change |
| Account assignment group 01 | Same customer | Save continues |
| Empty profit center | `TG-BILVAL`, plant 1010 | Save stops on add and on change |
| Profit center filled | Same material | Save continues |

Deactivate `R-CUST-AAG` and `R-MAT-PC` when you are finished, unless those checks should stay in the quality tenant. A billing rule with an empty checkpoint does not run during these saves.
