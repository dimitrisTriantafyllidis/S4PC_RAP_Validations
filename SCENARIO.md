# Quality-tenant scenario: unpriced item on a domestic invoice

Customer and material save checks are in [SCENARIO-MASTERDATA.md](SCENARIO-MASTERDATA.md).

Run this in a quality system after the ABAP objects are active, service binding `ZUI_BILVAL_O4` is published, and class `ZCL_BILVAL_SETUP` has been executed once. Use sales area **1010 / 10 / 00** (company code 1010, plant 1010). If your tenant is the US starter system, use **1710 / 10 / 00**, plant 1710, and sold-to **17100001** everywhere this scenario says 10100001.

The story: customer 10100001 orders two trading goods. TG11 has a normal price and may be invoiced. TG12 is free of charge (net amount 0) and must not be invoiced. A second check, on preliminary billing, stops finalization when the invoice does not contain every sales-order item.

## 1. Confirm the master data

In the quality tenant, open these apps and check that the rows exist. Do not create new customers or products if these standard Best Practice values are already there.

| Object | Value | App |
| --- | --- | --- |
| Sold-to / payer / ship-to | `10100001` | Manage Customer Master Data |
| Products | `TG11`, `TG12` | Manage Product Master Data |
| Sales area | `1010` / `10` / `00` | Manage Customer Master Data, sales area |
| Plant / shipping point | `1010` / `1010` | Manage Product Master Data, plant |
| Order type | `OR` | Manage Sales Orders - Version 2 |
| Delivery type | `LF` | Create Outbound Deliveries |
| Billing type | `F2` | Create Billing Documents |
| Item category | `TAN` | shown on the sales order item |

`TG11` and `TG12` must be sold from plant 1010 with unrestricted stock. If stock is zero, post a goods receipt of 100 PC for each product in Post Goods Movement (movement type 561) into storage location 101A, or use whatever storage location your plant uses for trading goods.

## 2. Make the validation run on this flow

`SD_BIL_DATA_TRANSFER` runs only when copying control points at your routine. For `TAN`, billing is delivery-related, so the routine has to be on the delivery-to-billing copy control, not only on the order.

1. Configuration activity **Define Custom Routines for Data Transfer to Billing Documents** (102865): routine `3009001`, enhancement id `ZBILVAL_TRANSFER`.
2. Configuration activity **Define Copying Control for Delivery Document to Billing Document**: delivery type `LF`, billing type `F2`, item category `TAN`. Set the data-transfer routine to `3009001` at item level.
3. In the validation app, open configuration `BILVAL`. Plug-ins `ZERO_PRICE` and `PRECEDING` stay inactive for the first two billing runs.

## 3. Enter this rule

In the validation app, on configuration `BILVAL`, create one rule:

| Field | Value |
| --- | --- |
| Rule ID | `R-ZERO` |
| Description | Reject a free-of-charge billing item |
| Checkpoint | `CREATE` |
| Outcome | `BLOCK` |
| Severity | `E` |
| Billing type | `F2` |
| Sales organization | `1010` |
| Message text | Item net amount is zero. Maintain a price before invoicing. |
| Active | yes |
| Sequence | `10` |

Condition:

| Position | Scope | Field | Operator | Value |
| --- | --- | --- | --- | --- |
| 1 | `I` | `NETAMOUNT` | `EQ` | `0` |

Save. An unknown field name is rejected by the app itself. `NETAMOUNT` on scope `I` is the item net amount.

## 4. Create the sales order

App: **Manage Sales Orders - Version 2**.

| Header | Value |
| --- | --- |
| Order type | `OR` |
| Sold-to party | `10100001` |
| Customer reference | `BILVAL-ZERO-01` |

| Item | Product | Quantity | What you do to the price |
| --- | --- | --- | --- |
| 10 | `TG11` | 10 PC | Leave the determined price. Net value must be greater than 0. |
| 20 | `TG12` | 5 PC | Add a manual 100% discount so the item net value becomes 0.00. |

Open item 20, go to **Price Details**, and add the manual discount your pricing procedure allows (often a customer discount you can edit). The item net value on the sales order must show **0.00 EUR** before you continue. Item 10 must show a positive net value. Write down the sales order number.

If the pricing procedure does not allow the net value to reach zero, stop and use a different manual condition. A price of 0.01 does not match this rule.

## 5. Deliver and bill

1. App **Create Outbound Deliveries**: shipping point `1010`, the sales order from step 4. Create one delivery for both items.
2. App **Pick Outbound Delivery** or **Change Outbound Delivery**: pick the full quantity of both items.
3. Post goods issue.
4. App **Create Billing Documents**: billing due list, billing type `F2`. Select only this delivery and choose **Create Billing Documents**.

### Expected result

- Item 10 (`TG11`) is invoiced. A billing document of type `F2` exists for 10 PC.
- Item 20 (`TG12`) is rejected and stays in the billing due list. The log or the billing worklist shows: `Item net amount is zero. Maintain a price before invoicing.`
- The rejection is temporary. The delivery item is still due until you give it a price or deactivate the rule.

Write down the billing document number. In **Manage Billing Documents**, that invoice contains `TG11` only.

If both items are invoiced, the routine is not assigned on `LF` / `F2` / `TAN`, or the item 20 net amount was not actually 0.

## 6. Turn the same rule into a warning

In the validation app, set rule `R-ZERO` severity to `W` and save.

On the same delivery, item 20 is still due. In **Create Billing Documents**, bill that remaining item.

### Expected result

- A second `F2` invoice is created for `TG12`, 5 PC, net amount 0.00.
- The invoice is saved. The message does not stop it.
- App **Application Logs**: object `ZBILVAL`, subobject `RUN`. The external id contains `CREATE`. The warning text is the rule message.

Set severity back to `E` when you are finished with this step, and deactivate rule `R-ZERO` before the plug-in tests so the two checks are not stacked.

## 7. Whole order on a preliminary billing document

Skip this section when preliminary billing is not active in the tenant (scope item 1MC).

Deactivate `R-ZERO`. In the validation app, set plug-in `PRECEDING` to active, checkpoint `PBD_FINAL`, sequence `10`.

Create a second sales order:

| Header | Value |
| --- | --- |
| Order type | `OR` |
| Sold-to party | `10100001` |
| Customer reference | `BILVAL-PRE-01` |

| Item | Product | Quantity | Price |
| --- | --- | --- | --- |
| 10 | `TG11` | 2 PC | Standard price, net value greater than 0 |
| 20 | `TG12` | 1 PC | Standard price, net value greater than 0 |

Deliver and post goods issue for both items, same as step 5.

In **Create Preliminary Billing Documents**, select only item 10 of this delivery. Leave item 20 unbilled. Open the preliminary billing document in **Manage Preliminary Billing Documents** and choose **Finalize**.

### Expected result

- Finalization stops.
- The message names sales order item `000020` as missing from the billing document.
- The preliminary billing document stays open. Item 20 is still due.
- Create a second preliminary billing document for item 20 as well, or add the missing item if your process allows it, then finalize. With both sales-order items present, finalization continues.

Deactivate plug-in `PRECEDING` after this test. On ordinary **Create Billing Documents**, this plug-in only checks that the current item exists on the sales order. It cannot see the other billing items in that call, so the completeness check belongs on preliminary billing.

## 8. What you should have at the end

| Check | Document | Result |
| --- | --- | --- |
| Block zero net amount | First delivery, item `TG12` | Stays in the billing due list while severity is `E` |
| Invoice the priced item | First delivery, item `TG11` | `F2` invoice posted for 10 PC |
| Warning only | Same `TG12` item after severity `W` | Invoice is created, log `ZBILVAL` / `RUN` has the warning |
| Missing sales-order item | Preliminary billing with only item 10 | Finalize is blocked until item 20 is included |

Release to accounting of an invoice that was already saved is outside this scenario. This application does not stop that posting.
