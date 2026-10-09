CLASS zcl_bilval_context_mapper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS map
      IMPORTING
        checkpoint        TYPE zif_bilval_check=>ty_checkpoint
        header            TYPE any
        item              TYPE any OPTIONAL
        items             TYPE ANY TABLE OPTIONAL
        action            TYPE zif_bilval_check=>ty_action OPTIONAL
        complete_document TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)     TYPE zif_bilval_check=>ty_context.

  PRIVATE SECTION.
    METHODS read_component
      IMPORTING
        structure     TYPE any
        names         TYPE string_table
      RETURNING
        VALUE(result) TYPE string.

    METHODS fill_header
      IMPORTING
        structure TYPE any
      CHANGING
        header    TYPE zif_bilval_check=>ty_header.

    METHODS fill_item
      IMPORTING
        structure     TYPE any
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_item.

    METHODS collect_custom_fields
      IMPORTING
        structure     TYPE any
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_custom_fields.

    METHODS as_date
      IMPORTING
        value         TYPE string
      RETURNING
        VALUE(result) TYPE d.

    METHODS as_amount
      IMPORTING
        value         TYPE string
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_amount.

    METHODS as_quantity
      IMPORTING
        value         TYPE string
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_quantity.

    METHODS is_structure
      IMPORTING
        data          TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_bilval_context_mapper IMPLEMENTATION.

  METHOD map.
    result-checkpoint = checkpoint.
    result-action = action.
    result-complete_document = complete_document.

    IF is_structure( header ) = abap_true.
      fill_header( EXPORTING structure = header CHANGING header = result-header ).
    ENDIF.

    IF item IS SUPPLIED AND is_structure( item ) = abap_true.
      result-current_item = fill_item( item ).
      result-has_current_item = abap_true.
      IF result-header-reference_document IS INITIAL.
        result-header-reference_document = result-current_item-reference_document.
      ENDIF.
    ENDIF.

    IF items IS SUPPLIED.
      LOOP AT items ASSIGNING FIELD-SYMBOL(<row>).
        APPEND fill_item( <row> ) TO result-items.
      ENDLOOP.
    ENDIF.

    IF result-header-reference_document_category = 'C'
      AND result-current_item-sales_document IS INITIAL
      AND result-current_item-reference_document IS NOT INITIAL.
      result-current_item-sales_document = result-current_item-reference_document.
      result-current_item-sales_document_item = result-current_item-reference_item.
    ENDIF.
  ENDMETHOD.

  METHOD fill_header.
    header-billing_document = read_component( structure = structure names = VALUE #( ( `BILLINGDOCUMENT` ) ( `VBELN` ) ) ).
    header-billing_type = to_upper( read_component( structure = structure names = VALUE #( ( `BILLINGDOCUMENTTYPE` ) ( `FKART` ) ) ) ).
    header-sales_organization = to_upper( read_component( structure = structure names = VALUE #( ( `SALESORGANIZATION` ) ( `VKORG` ) ) ) ).
    header-distribution_channel = to_upper( read_component( structure = structure names = VALUE #( ( `DISTRIBUTIONCHANNEL` ) ( `VTWEG` ) ) ) ).
    header-division = to_upper( read_component( structure = structure names = VALUE #( ( `DIVISION` ) ( `SPART` ) ) ) ).
    header-company_code = to_upper( read_component( structure = structure names = VALUE #( ( `COMPANYCODE` ) ( `BUKRS` ) ) ) ).
    header-sold_to_party = to_upper( read_component( structure = structure names = VALUE #( ( `SOLDTOPARTY` ) ( `KUNAG` ) ) ) ).
    header-payer = to_upper( read_component( structure = structure names = VALUE #( ( `PAYERPARTY` ) ( `PAYER` ) ( `KUNRG` ) ) ) ).
    header-billing_date = as_date( read_component( structure = structure names = VALUE #( ( `BILLINGDOCUMENTDATE` ) ( `FKDAT` ) ) ) ).
    header-net_amount = as_amount( read_component( structure = structure names = VALUE #( ( `TOTALNETAMOUNT` ) ( `NETAMOUNT` ) ( `NETWR` ) ) ) ).
    header-tax_amount = as_amount( read_component( structure = structure names = VALUE #( ( `TAXAMOUNT` ) ( `MWSBK` ) ) ) ).
    header-currency = to_upper( read_component( structure = structure names = VALUE #( ( `TRANSACTIONCURRENCY` ) ( `CURRENCY` ) ( `WAERK` ) ) ) ).
    header-posting_status = to_upper( read_component( structure = structure names = VALUE #( ( `ACCOUNTINGTRANSFERSTATUS` ) ( `RFBSK` ) ) ) ).
    header-clearing_status = to_upper( read_component( structure = structure names = VALUE #( ( `INVOICECLEARINGSTATUS` ) ) ) ).
    header-reference_document = read_component( structure = structure names = VALUE #( ( `DOCUMENTREFERENCEID` ) ( `REFERENCEDOCUMENT` ) ) ).
    header-reference_document_category = to_upper( read_component(
      structure = structure
      names = VALUE #( ( `REFERENCESDDOCUMENTCATEGORY` ) ( `SDDOCUMENTCATEGORY` ) ( `VBTYP` ) ) ) ).
    header-approval_reason = to_upper( read_component(
      structure = structure
      names = VALUE #( ( `BILLINGPROCDOCAPPROVALREASON` ) ( `APPROVALREQUESTREASON` ) ) ) ).
    header-custom_fields = collect_custom_fields( structure ).
  ENDMETHOD.

  METHOD fill_item.
    result-billing_document_item = read_component( structure = structure names = VALUE #( ( `BILLINGDOCUMENTITEM` ) ( `POSNR` ) ) ).
    result-material = to_upper( read_component( structure = structure names = VALUE #( ( `MATERIAL` ) ( `MATNR` ) ) ) ).
    result-item_category = to_upper( read_component(
      structure = structure
      names = VALUE #( ( `SALESDOCUMENTITEMCATEGORY` ) ( `BILLINGDOCUMENTITEMCATEGORY` ) ( `PSTYV` ) ) ) ).
    result-quantity = as_quantity( read_component( structure = structure names = VALUE #( ( `BILLINGQUANTITY` ) ( `QUANTITY` ) ( `FKIMG` ) ) ) ).
    result-net_amount = as_amount( read_component( structure = structure names = VALUE #( ( `NETAMOUNT` ) ( `NETWR` ) ) ) ).
    result-tax_amount = as_amount( read_component( structure = structure names = VALUE #( ( `TAXAMOUNT` ) ) ) ).
    result-customer_account_assignment = to_upper( read_component(
      structure = structure
      names = VALUE #( ( `CUSTOMERACCOUNTASSIGNMENTGROUP` ) ( `KTGRD` ) ) ) ).
    result-material_account_assignment = to_upper( read_component(
      structure = structure
      names = VALUE #( ( `MATERIALACCOUNTASSIGNMENTGROUP` ) ( `KTGRM` ) ) ) ).
    result-reference_document = read_component( structure = structure names = VALUE #( ( `REFERENCESDDOCUMENT` ) ( `VGBEL` ) ) ).
    result-reference_item = read_component( structure = structure names = VALUE #( ( `REFERENCESDDOCUMENTITEM` ) ( `VGPOS` ) ) ).
    result-sales_document = read_component( structure = structure names = VALUE #( ( `SALESDOCUMENT` ) ( `AUBEL` ) ) ).
    result-sales_document_item = read_component( structure = structure names = VALUE #( ( `SALESDOCUMENTITEM` ) ( `AUPOS` ) ) ).
    result-custom_fields = collect_custom_fields( structure ).

    IF result-sales_document IS INITIAL AND result-reference_document IS NOT INITIAL.
      result-sales_document = result-reference_document.
      result-sales_document_item = result-reference_item.
    ENDIF.
  ENDMETHOD.

  METHOD read_component.
    LOOP AT names INTO DATA(name).
      ASSIGN COMPONENT name OF STRUCTURE structure TO FIELD-SYMBOL(<value>).
      IF sy-subrc = 0.
        result = condense( CONV string( <value> ) ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD collect_custom_fields.
    TRY.
        DATA(description) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( structure ) ).
      CATCH cx_sy_move_cast_error.
        RETURN.
    ENDTRY.

    LOOP AT description->components INTO DATA(component).
      DATA(name) = to_upper( component-name ).
      IF name NP 'YY1_*'.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT component-name OF STRUCTURE structure TO FIELD-SYMBOL(<value>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      INSERT VALUE #(
        field_name = name
        value = condense( CONV string( <value> ) ) ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD as_date.
    DATA(text) = condense( value ).
    IF text IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        result = text.
      CATCH cx_sy_conversion_error.
        CLEAR result.
    ENDTRY.
  ENDMETHOD.

  METHOD as_amount.
    DATA(text) = condense( value ).
    IF text IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        result = text.
      CATCH cx_sy_conversion_error.
        CLEAR result.
    ENDTRY.
  ENDMETHOD.

  METHOD as_quantity.
    DATA(text) = condense( value ).
    IF text IS INITIAL.
      RETURN.
    ENDIF.
    TRY.
        result = text.
      CATCH cx_sy_conversion_error.
        CLEAR result.
    ENDTRY.
  ENDMETHOD.

  METHOD is_structure.
    result = xsdbool( cl_abap_typedescr=>describe_by_data( data )->kind = cl_abap_typedescr=>kind_struct ).
  ENDMETHOD.

ENDCLASS.
