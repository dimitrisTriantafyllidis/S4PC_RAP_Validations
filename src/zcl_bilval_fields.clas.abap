CLASS zcl_bilval_fields DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_field,
        field_name  TYPE zif_bilval_check=>ty_field_name,
        scope       TYPE zif_bilval_check=>ty_scope,
        description TYPE c LENGTH 60,
        area        TYPE c LENGTH 1,
      END OF ty_field,
      ty_fields TYPE STANDARD TABLE OF ty_field WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_code,
        code_group  TYPE c LENGTH 15,
        code        TYPE c LENGTH 20,
        description TYPE c LENGTH 60,
      END OF ty_code,
      ty_codes TYPE STANDARD TABLE OF ty_code WITH EMPTY KEY.

    CLASS-METHODS get_catalog
      RETURNING VALUE(result) TYPE ty_fields.

    CLASS-METHODS get_codes
      RETURNING VALUE(result) TYPE ty_codes.

    CLASS-METHODS exists
      IMPORTING
        field_name    TYPE zif_bilval_check=>ty_field_name
        scope         TYPE zif_bilval_check=>ty_scope
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_checkpoint
      IMPORTING value         TYPE zif_bilval_check=>ty_checkpoint
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_operator
      IMPORTING value         TYPE zif_bilval_check=>ty_operator
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_outcome
      IMPORTING value         TYPE zif_bilval_check=>ty_outcome
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_severity
      IMPORTING value         TYPE zif_bilval_check=>ty_severity
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_scope
      IMPORTING value         TYPE zif_bilval_check=>ty_scope
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS checkpoint_applies
      IMPORTING
        configured    TYPE zif_bilval_check=>ty_checkpoint
        current       TYPE zif_bilval_check=>ty_checkpoint
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_master_checkpoint
      IMPORTING value         TYPE zif_bilval_check=>ty_checkpoint
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS field_fits_checkpoint
      IMPORTING
        field_name    TYPE zif_bilval_check=>ty_field_name
        scope         TYPE zif_bilval_check=>ty_scope
        checkpoint    TYPE zif_bilval_check=>ty_checkpoint
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS get_value
      IMPORTING
        context       TYPE zif_bilval_check=>ty_context
        field_name    TYPE zif_bilval_check=>ty_field_name
        scope         TYPE zif_bilval_check=>ty_scope
        item          TYPE zif_bilval_check=>ty_item OPTIONAL
      EXPORTING
        unknown       TYPE abap_bool
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS custom_value
      IMPORTING
        fields        TYPE zif_bilval_check=>ty_custom_fields
        field_name    TYPE zif_bilval_check=>ty_field_name
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_bilval_fields IMPLEMENTATION.

  METHOD get_catalog.
    result = VALUE #(
      ( field_name = 'BILLINGDOCUMENT'                scope = zif_bilval_check=>scope-header description = 'Billing Document' )
      ( field_name = 'BILLINGTYPE'                    scope = zif_bilval_check=>scope-header description = 'Billing Type' )
      ( field_name = 'SALESORGANIZATION'              scope = zif_bilval_check=>scope-header description = 'Sales Organization' area = 'S' )
      ( field_name = 'DISTRIBUTIONCHANNEL'            scope = zif_bilval_check=>scope-header description = 'Distribution Channel' area = 'S' )
      ( field_name = 'DIVISION'                       scope = zif_bilval_check=>scope-header description = 'Division' area = 'S' )
      ( field_name = 'COMPANYCODE'                    scope = zif_bilval_check=>scope-header description = 'Company Code' area = 'S' )
      ( field_name = 'SOLDTOPARTY'                    scope = zif_bilval_check=>scope-header description = 'Sold-to Party' area = 'S' )
      ( field_name = 'PAYER'                          scope = zif_bilval_check=>scope-header description = 'Payer' )
      ( field_name = 'BILLINGDATE'                    scope = zif_bilval_check=>scope-header description = 'Billing Date' )
      ( field_name = 'NETAMOUNT'                      scope = zif_bilval_check=>scope-header description = 'Header Net Amount' )
      ( field_name = 'TAXAMOUNT'                      scope = zif_bilval_check=>scope-header description = 'Header Tax Amount' )
      ( field_name = 'CURRENCY'                       scope = zif_bilval_check=>scope-header description = 'Currency' )
      ( field_name = 'POSTINGSTATUS'                  scope = zif_bilval_check=>scope-header description = 'Posting Status' )
      ( field_name = 'CLEARINGSTATUS'                 scope = zif_bilval_check=>scope-header description = 'Clearing Status' )
      ( field_name = 'REFERENCEDOCUMENT'              scope = zif_bilval_check=>scope-header description = 'Reference Document' )
      ( field_name = 'REFERENCEDOCUMENTCATEGORY'      scope = zif_bilval_check=>scope-header description = 'Reference Document Category' )
      ( field_name = 'APPROVALREASON'                 scope = zif_bilval_check=>scope-header description = 'Approval Reason' )
      ( field_name = 'BILLINGDOCUMENTITEM'            scope = zif_bilval_check=>scope-item   description = 'Billing Item' )
      ( field_name = 'MATERIAL'                       scope = zif_bilval_check=>scope-item   description = 'Material' area = 'S' )
      ( field_name = 'ITEMCATEGORY'                   scope = zif_bilval_check=>scope-item   description = 'Item Category' )
      ( field_name = 'QUANTITY'                       scope = zif_bilval_check=>scope-item   description = 'Quantity' )
      ( field_name = 'NETAMOUNT'                      scope = zif_bilval_check=>scope-item   description = 'Item Net Amount' )
      ( field_name = 'TAXAMOUNT'                      scope = zif_bilval_check=>scope-item   description = 'Item Tax Amount' )
      ( field_name = 'CUSTOMERACCOUNTASSIGNMENTGROUP' scope = zif_bilval_check=>scope-item   description = 'Customer Account Assignment Group' area = 'S' )
      ( field_name = 'MATERIALACCOUNTASSIGNMENTGROUP' scope = zif_bilval_check=>scope-item   description = 'Material Account Assignment Group' )
      ( field_name = 'REFERENCEDOCUMENT'              scope = zif_bilval_check=>scope-item   description = 'Item Reference Document' )
      ( field_name = 'REFERENCEITEM'                  scope = zif_bilval_check=>scope-item   description = 'Item Reference Item' )
      ( field_name = 'SALESDOCUMENT'                  scope = zif_bilval_check=>scope-item   description = 'Sales Document' )
      ( field_name = 'SALESDOCUMENTITEM'              scope = zif_bilval_check=>scope-item   description = 'Sales Document Item' )
      ( field_name = 'CUSTOMERNAME'                   scope = zif_bilval_check=>scope-header description = 'Customer Name' area = 'C' )
      ( field_name = 'COUNTRY'                        scope = zif_bilval_check=>scope-header description = 'Country' area = 'C' )
      ( field_name = 'ACCOUNTGROUP'                   scope = zif_bilval_check=>scope-header description = 'Customer Account Group' area = 'C' )
      ( field_name = 'TAXNUMBER'                      scope = zif_bilval_check=>scope-header description = 'Tax Number' area = 'C' )
      ( field_name = 'MATERIAL'                       scope = zif_bilval_check=>scope-header description = 'Material' area = 'M' )
      ( field_name = 'PRODUCTTYPE'                    scope = zif_bilval_check=>scope-header description = 'Product Type' area = 'M' )
      ( field_name = 'PRODUCTGROUP'                   scope = zif_bilval_check=>scope-header description = 'Product Group' area = 'M' )
      ( field_name = 'BASEUNIT'                       scope = zif_bilval_check=>scope-header description = 'Base Unit' area = 'M' )
      ( field_name = 'SALESORGANIZATION'              scope = zif_bilval_check=>scope-item   description = 'Sales Organization' area = 'S' )
      ( field_name = 'DISTRIBUTIONCHANNEL'            scope = zif_bilval_check=>scope-item   description = 'Distribution Channel' area = 'S' )
      ( field_name = 'DIVISION'                       scope = zif_bilval_check=>scope-item   description = 'Division' area = 'S' )
      ( field_name = 'COMPANYCODE'                    scope = zif_bilval_check=>scope-item   description = 'Company Code' area = 'S' )
      ( field_name = 'PAYMENTTERMS'                   scope = zif_bilval_check=>scope-item   description = 'Payment Terms' area = 'C' )
      ( field_name = 'INCOTERMS'                      scope = zif_bilval_check=>scope-item   description = 'Incoterms' area = 'C' )
      ( field_name = 'RECONCILIATIONACCT'             scope = zif_bilval_check=>scope-item   description = 'Reconciliation Account' area = 'C' )
      ( field_name = 'RECORDTYPE'                     scope = zif_bilval_check=>scope-item   description = 'SALES or COMPANY' area = 'C' )
      ( field_name = 'PLANT'                          scope = zif_bilval_check=>scope-item   description = 'Plant' area = 'M' )
      ( field_name = 'PROFITCENTER'                   scope = zif_bilval_check=>scope-item   description = 'Profit Center' area = 'M' )
      ( field_name = 'PURCHASINGGROUP'                scope = zif_bilval_check=>scope-item   description = 'Purchasing Group' area = 'M' ) ).
  ENDMETHOD.

  METHOD get_codes.
    result = VALUE #(
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-create     description = 'Create billing document' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-pbd_final  description = 'Finalize preliminary billing document' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-pbd_create description = 'Create billing document from preliminary' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-pbd_auto   description = 'Auto-finalize preliminary billing document' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-approval   description = 'Preliminary billing approval' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-cancel     description = 'Cancel billing document' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-customer   description = 'Customer add or change' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-cust_add   description = 'Create customer' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-cust_upd   description = 'Change customer' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-material   description = 'Material add or change' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-mat_add    description = 'Create material' )
      ( code_group = 'CHECKPOINT' code = zif_bilval_check=>checkpoint-mat_upd    description = 'Change material' ) )
      ( code_group = 'OUTCOME'    code = zif_bilval_check=>outcome-block            description = 'Block the billing action' )
      ( code_group = 'OUTCOME'    code = zif_bilval_check=>outcome-require_approval description = 'Require approval' )
      ( code_group = 'SEVERITY'   code = zif_bilval_check=>severity-error   description = 'Error' )
      ( code_group = 'SEVERITY'   code = zif_bilval_check=>severity-warning description = 'Warning' )
      ( code_group = 'SCOPE'      code = zif_bilval_check=>scope-header description = 'Header' )
      ( code_group = 'SCOPE'      code = zif_bilval_check=>scope-item   description = 'Item' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-is_initial     description = 'Is initial' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-is_not_initial description = 'Is not initial' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-eq             description = 'Equals' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-ne             description = 'Does not equal' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-gt             description = 'Greater than' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-lt             description = 'Less than' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-ge             description = 'Greater or equal' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-le             description = 'Less or equal' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-between        description = 'Between' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-in_list        description = 'In list' )
      ( code_group = 'OPERATOR'   code = zif_bilval_check=>operator-field_eq       description = 'Equals another field' ) ).
  ENDMETHOD.

  METHOD exists.
    DATA(name) = to_upper( field_name ).
    IF name CP 'YY1_*'.
      result = abap_true.
      RETURN.
    ENDIF.
    result = xsdbool( line_exists( get_catalog( )[ field_name = name scope = to_upper( scope ) ] ) ).
  ENDMETHOD.

  METHOD is_checkpoint.
    result = xsdbool( line_exists( get_codes( )[ code_group = 'CHECKPOINT' code = to_upper( value ) ] ) ).
  ENDMETHOD.

  METHOD is_operator.
    result = xsdbool( line_exists( get_codes( )[ code_group = 'OPERATOR' code = to_upper( value ) ] ) ).
  ENDMETHOD.

  METHOD is_outcome.
    result = xsdbool( line_exists( get_codes( )[ code_group = 'OUTCOME' code = to_upper( value ) ] ) ).
  ENDMETHOD.

  METHOD is_severity.
    result = xsdbool( line_exists( get_codes( )[ code_group = 'SEVERITY' code = to_upper( value ) ] ) ).
  ENDMETHOD.

  METHOD is_scope.
    result = xsdbool( line_exists( get_codes( )[ code_group = 'SCOPE' code = to_upper( value ) ] ) ).
  ENDMETHOD.

  METHOD is_master_checkpoint.
    result = xsdbool(
      value = zif_bilval_check=>checkpoint-customer
      OR value = zif_bilval_check=>checkpoint-cust_add
      OR value = zif_bilval_check=>checkpoint-cust_upd
      OR value = zif_bilval_check=>checkpoint-material
      OR value = zif_bilval_check=>checkpoint-mat_add
      OR value = zif_bilval_check=>checkpoint-mat_upd ).
  ENDMETHOD.

  METHOD checkpoint_applies.
    IF configured IS INITIAL.
      result = xsdbool( is_master_checkpoint( current ) = abap_false ).
      RETURN.
    ENDIF.
    IF configured = current.
      result = abap_true.
      RETURN.
    ENDIF.
    result = xsdbool(
      ( configured = zif_bilval_check=>checkpoint-customer
        AND ( current = zif_bilval_check=>checkpoint-cust_add
          OR current = zif_bilval_check=>checkpoint-cust_upd
          OR current = zif_bilval_check=>checkpoint-customer ) )
      OR ( configured = zif_bilval_check=>checkpoint-material
        AND ( current = zif_bilval_check=>checkpoint-mat_add
          OR current = zif_bilval_check=>checkpoint-mat_upd
          OR current = zif_bilval_check=>checkpoint-material ) ) ).
  ENDMETHOD.

  METHOD field_fits_checkpoint.
    DATA(name) = to_upper( field_name ).
    IF name CP 'YY1_*'.
      result = abap_true.
      RETURN.
    ENDIF.

    DATA(field_scope) = CONV zif_bilval_check=>ty_scope( to_upper( scope ) ).
    READ TABLE get_catalog( ) INTO DATA(field)
      WITH KEY field_name = name scope = field_scope.
    IF sy-subrc <> 0.
      result = abap_false.
      RETURN.
    ENDIF.

    DATA(area) = field-area.
    IF area IS INITIAL.
      area = 'B'.
    ENDIF.
    CASE area.
      WHEN 'S'.
        result = abap_true.
      WHEN 'C'.
        result = xsdbool(
          checkpoint = zif_bilval_check=>checkpoint-customer
          OR checkpoint = zif_bilval_check=>checkpoint-cust_add
          OR checkpoint = zif_bilval_check=>checkpoint-cust_upd ).
      WHEN 'M'.
        result = xsdbool(
          checkpoint = zif_bilval_check=>checkpoint-material
          OR checkpoint = zif_bilval_check=>checkpoint-mat_add
          OR checkpoint = zif_bilval_check=>checkpoint-mat_upd ).
      WHEN OTHERS.
        result = xsdbool( is_master_checkpoint( checkpoint ) = abap_false ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_value.
    DATA(name) = CONV zif_bilval_check=>ty_field_name( to_upper( field_name ) ).
    DATA(field_scope) = CONV zif_bilval_check=>ty_scope( to_upper( scope ) ).
    unknown = abap_false.

    IF name CP 'YY1_*'.
      IF field_scope = zif_bilval_check=>scope-item.
        result = custom_value( fields = item-custom_fields field_name = name ).
      ELSE.
        result = custom_value( fields = context-header-custom_fields field_name = name ).
      ENDIF.
      RETURN.
    ENDIF.

    IF exists( field_name = name scope = field_scope ) = abap_false
      OR field_fits_checkpoint( field_name = name scope = field_scope checkpoint = context-checkpoint ) = abap_false.
      unknown = abap_true.
      RETURN.
    ENDIF.

    CASE field_scope.
      WHEN zif_bilval_check=>scope-header.
        CASE name.
          WHEN 'BILLINGDOCUMENT'.
            result = context-header-billing_document.
          WHEN 'BILLINGTYPE'.
            result = context-header-billing_type.
          WHEN 'SALESORGANIZATION'.
            result = context-header-sales_organization.
          WHEN 'DISTRIBUTIONCHANNEL'.
            result = context-header-distribution_channel.
          WHEN 'DIVISION'.
            result = context-header-division.
          WHEN 'COMPANYCODE'.
            result = context-header-company_code.
          WHEN 'SOLDTOPARTY'.
            result = context-header-sold_to_party.
          WHEN 'PAYER'.
            result = context-header-payer.
          WHEN 'BILLINGDATE'.
            result = |{ context-header-billing_date DATE = RAW }|.
          WHEN 'NETAMOUNT'.
            result = |{ context-header-net_amount STYLE = SIMPLE }|.
          WHEN 'TAXAMOUNT'.
            result = |{ context-header-tax_amount STYLE = SIMPLE }|.
          WHEN 'CURRENCY'.
            result = context-header-currency.
          WHEN 'POSTINGSTATUS'.
            result = context-header-posting_status.
          WHEN 'CLEARINGSTATUS'.
            result = context-header-clearing_status.
          WHEN 'REFERENCEDOCUMENT'.
            result = context-header-reference_document.
          WHEN 'REFERENCEDOCUMENTCATEGORY'.
            result = context-header-reference_document_category.
          WHEN 'APPROVALREASON'.
            result = context-header-approval_reason.
        ENDCASE.
      WHEN zif_bilval_check=>scope-item.
        CASE name.
          WHEN 'BILLINGDOCUMENTITEM'.
            result = item-billing_document_item.
          WHEN 'MATERIAL'.
            result = item-material.
          WHEN 'ITEMCATEGORY'.
            result = item-item_category.
          WHEN 'QUANTITY'.
            result = |{ item-quantity STYLE = SIMPLE }|.
          WHEN 'NETAMOUNT'.
            result = |{ item-net_amount STYLE = SIMPLE }|.
          WHEN 'TAXAMOUNT'.
            result = |{ item-tax_amount STYLE = SIMPLE }|.
          WHEN 'CUSTOMERACCOUNTASSIGNMENTGROUP'.
            result = item-customer_account_assignment.
          WHEN 'MATERIALACCOUNTASSIGNMENTGROUP'.
            result = item-material_account_assignment.
          WHEN 'REFERENCEDOCUMENT'.
            result = item-reference_document.
          WHEN 'REFERENCEITEM'.
            result = item-reference_item.
          WHEN 'SALESDOCUMENT'.
            result = item-sales_document.
          WHEN 'SALESDOCUMENTITEM'.
            result = item-sales_document_item.
        ENDCASE.
    ENDCASE.

    IF result IS INITIAL.
      IF field_scope = zif_bilval_check=>scope-item.
        result = custom_value( fields = item-custom_fields field_name = name ).
      ELSE.
        result = custom_value( fields = context-header-custom_fields field_name = name ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD custom_value.
    DATA(name) = CONV zif_bilval_check=>ty_field_name( to_upper( field_name ) ).
    IF line_exists( fields[ field_name = name ] ).
      result = fields[ field_name = name ]-value.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
