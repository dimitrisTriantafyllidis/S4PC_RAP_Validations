INTERFACE zif_bilval_check
  PUBLIC.

  TYPES:
    ty_checkpoint      TYPE c LENGTH 10,
    ty_outcome         TYPE c LENGTH 20,
    ty_severity        TYPE c LENGTH 1,
    ty_scope           TYPE c LENGTH 1,
    ty_operator        TYPE c LENGTH 10,
    ty_rule_id         TYPE c LENGTH 10,
    ty_plugin_id       TYPE c LENGTH 30,
    ty_field_name      TYPE c LENGTH 30,
    ty_item_number     TYPE c LENGTH 6,
    ty_approval_reason TYPE c LENGTH 4,
    ty_document        TYPE c LENGTH 10,
    ty_action          TYPE c LENGTH 20.

  CONSTANTS:
    BEGIN OF checkpoint,
      create     TYPE ty_checkpoint VALUE 'CREATE',
      pbd_final  TYPE ty_checkpoint VALUE 'PBD_FINAL',
      pbd_create TYPE ty_checkpoint VALUE 'PBD_CREATE',
      pbd_auto   TYPE ty_checkpoint VALUE 'PBD_AUTO',
      approval   TYPE ty_checkpoint VALUE 'APPROVAL',
      cancel     TYPE ty_checkpoint VALUE 'CANCEL',
      customer   TYPE ty_checkpoint VALUE 'CUSTOMER',
      cust_add   TYPE ty_checkpoint VALUE 'CUST_ADD',
      cust_upd   TYPE ty_checkpoint VALUE 'CUST_UPD',
      material   TYPE ty_checkpoint VALUE 'MATERIAL',
      mat_add    TYPE ty_checkpoint VALUE 'MAT_ADD',
      mat_upd    TYPE ty_checkpoint VALUE 'MAT_UPD',
    END OF checkpoint.

  CONSTANTS:
    BEGIN OF outcome,
      block            TYPE ty_outcome VALUE 'BLOCK',
      require_approval TYPE ty_outcome VALUE 'REQUIRE_APPROVAL',
    END OF outcome.

  CONSTANTS:
    BEGIN OF severity,
      error   TYPE ty_severity VALUE 'E',
      warning TYPE ty_severity VALUE 'W',
    END OF severity.

  CONSTANTS:
    BEGIN OF scope,
      header TYPE ty_scope VALUE 'H',
      item   TYPE ty_scope VALUE 'I',
    END OF scope.

  CONSTANTS:
    BEGIN OF operator,
      is_initial     TYPE ty_operator VALUE 'INIT',
      is_not_initial TYPE ty_operator VALUE 'NOT_INIT',
      eq             TYPE ty_operator VALUE 'EQ',
      ne             TYPE ty_operator VALUE 'NE',
      gt             TYPE ty_operator VALUE 'GT',
      lt             TYPE ty_operator VALUE 'LT',
      ge             TYPE ty_operator VALUE 'GE',
      le             TYPE ty_operator VALUE 'LE',
      between        TYPE ty_operator VALUE 'BETWEEN',
      in_list        TYPE ty_operator VALUE 'IN_LIST',
      field_eq       TYPE ty_operator VALUE 'FIELD_EQ',
    END OF operator.

  TYPES:
    BEGIN OF ty_custom_field,
      field_name TYPE ty_field_name,
      value      TYPE string,
    END OF ty_custom_field,
    ty_custom_fields TYPE HASHED TABLE OF ty_custom_field WITH UNIQUE KEY field_name.

  TYPES:
    BEGIN OF ty_header,
      billing_document            TYPE ty_document,
      billing_type                TYPE c LENGTH 4,
      sales_organization          TYPE c LENGTH 4,
      distribution_channel        TYPE c LENGTH 2,
      division                    TYPE c LENGTH 2,
      company_code                TYPE c LENGTH 4,
      sold_to_party               TYPE c LENGTH 10,
      payer                       TYPE c LENGTH 10,
      billing_date                TYPE d,
      net_amount                  TYPE p LENGTH 15 DECIMALS 2,
      tax_amount                  TYPE p LENGTH 15 DECIMALS 2,
      currency                    TYPE c LENGTH 5,
      posting_status              TYPE c LENGTH 1,
      clearing_status             TYPE c LENGTH 1,
      reference_document          TYPE ty_document,
      reference_document_category TYPE c LENGTH 4,
      approval_reason             TYPE ty_approval_reason,
      custom_fields               TYPE ty_custom_fields,
    END OF ty_header.

  TYPES:
    BEGIN OF ty_item,
      billing_document_item           TYPE ty_item_number,
      material                        TYPE c LENGTH 40,
      item_category                   TYPE c LENGTH 4,
      quantity                        TYPE p LENGTH 13 DECIMALS 3,
      net_amount                      TYPE p LENGTH 15 DECIMALS 2,
      tax_amount                      TYPE p LENGTH 15 DECIMALS 2,
      customer_account_assignment     TYPE c LENGTH 2,
      material_account_assignment     TYPE c LENGTH 2,
      reference_document              TYPE ty_document,
      reference_item                  TYPE ty_item_number,
      sales_document                  TYPE ty_document,
      sales_document_item             TYPE ty_item_number,
      custom_fields                   TYPE ty_custom_fields,
    END OF ty_item,
    ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_context,
      checkpoint        TYPE ty_checkpoint,
      action            TYPE ty_action,
      complete_document TYPE abap_bool,
      has_current_item  TYPE abap_bool,
      header            TYPE ty_header,
      current_item      TYPE ty_item,
      items             TYPE ty_items,
    END OF ty_context.

  TYPES:
    BEGIN OF ty_message,
      severity        TYPE ty_severity,
      rule_id         TYPE ty_rule_id,
      plugin_id       TYPE ty_plugin_id,
      message_text    TYPE string,
      item            TYPE ty_item_number,
      approval_reason TYPE ty_approval_reason,
      outcome         TYPE ty_outcome,
    END OF ty_message,
    ty_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_condition,
      position      TYPE n LENGTH 3,
      scope         TYPE ty_scope,
      field_name    TYPE ty_field_name,
      operator      TYPE ty_operator,
      value_low     TYPE c LENGTH 80,
      value_high    TYPE c LENGTH 80,
      compare_field TYPE ty_field_name,
    END OF ty_condition,
    ty_conditions TYPE STANDARD TABLE OF ty_condition WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_rule,
      rule_id            TYPE ty_rule_id,
      checkpoint         TYPE ty_checkpoint,
      outcome            TYPE ty_outcome,
      severity           TYPE ty_severity,
      billing_type       TYPE c LENGTH 4,
      sales_organization TYPE c LENGTH 4,
      company_code       TYPE c LENGTH 4,
      item_category      TYPE c LENGTH 4,
      sold_to_party      TYPE c LENGTH 10,
      message_text       TYPE c LENGTH 220,
      active_flag        TYPE abap_bool,
      sequence           TYPE i,
      approval_reason    TYPE ty_approval_reason,
      conditions         TYPE ty_conditions,
    END OF ty_rule,
    ty_rules TYPE STANDARD TABLE OF ty_rule WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_plugin_cfg,
      plugin_id       TYPE ty_plugin_id,
      checkpoint      TYPE ty_checkpoint,
      active_flag     TYPE abap_bool,
      sequence        TYPE i,
      approval_reason TYPE ty_approval_reason,
    END OF ty_plugin_cfg,
    ty_plugin_cfgs TYPE STANDARD TABLE OF ty_plugin_cfg WITH EMPTY KEY.

  METHODS validate
    IMPORTING context       TYPE ty_context
    RETURNING VALUE(result) TYPE ty_messages.

ENDINTERFACE.
