CLASS zcl_bilval_md_mapper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS partner_id
      IMPORTING
        partner_key   TYPE any OPTIONAL
        general       TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE string.

    METHODS product_id
      IMPORTING
        row           TYPE any
      RETURNING
        VALUE(result) TYPE string.

    METHODS customer_context
      IMPORTING
        checkpoint    TYPE zif_bilval_check=>ty_checkpoint
        partner_key   TYPE any OPTIONAL
        general       TYPE ANY TABLE
        sales         TYPE ANY TABLE OPTIONAL
        companies     TYPE ANY TABLE OPTIONAL
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_context.

    METHODS product_context
      IMPORTING
        checkpoint    TYPE zif_bilval_check=>ty_checkpoint
        row           TYPE any
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_context.

    CLASS-METHODS add_messages
      IMPORTING
        messages TYPE zif_bilval_check=>ty_messages
        product  TYPE string OPTIONAL
        warnings TYPE abap_bool DEFAULT abap_false
      CHANGING
        target   TYPE ANY TABLE.

  PRIVATE SECTION.
    METHODS read_value
      IMPORTING
        structure     TYPE any
        names         TYPE string_table
      EXPORTING
        found         TYPE abap_bool
      RETURNING
        VALUE(result) TYPE string.

    METHODS read_direct
      IMPORTING
        structure     TYPE any
        names         TYPE string_table
      EXPORTING
        found         TYPE abap_bool
      RETURNING
        VALUE(result) TYPE string.

    METHODS put_custom
      IMPORTING
        name   TYPE zif_bilval_check=>ty_field_name
        value  TYPE string
      CHANGING
        fields TYPE zif_bilval_check=>ty_custom_fields.

    METHODS add_yy1
      IMPORTING
        structure TYPE any
      CHANGING
        fields    TYPE zif_bilval_check=>ty_custom_fields.

    METHODS is_structure
      IMPORTING
        data          TYPE any
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS sales_item
      IMPORTING
        row           TYPE any
        position      TYPE i
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_item.

    METHODS company_item
      IMPORTING
        row           TYPE any
        position      TYPE i
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_item.

    METHODS plant_item
      IMPORTING
        row           TYPE any
        product       TYPE string
        position      TYPE i
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_item.

    METHODS item_number
      IMPORTING
        position      TYPE i
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_item_number.
ENDCLASS.


CLASS zcl_bilval_md_mapper IMPLEMENTATION.

  METHOD add_messages.
    LOOP AT messages INTO DATA(message).
      DATA(message_type) = message-severity.
      IF message-severity = zif_bilval_check=>severity-error
        AND message-outcome = zif_bilval_check=>outcome-block.
      ELSEIF warnings = abap_true AND message-severity = zif_bilval_check=>severity-warning.
      ELSE.
        CONTINUE.
      ENDIF.

      DATA line_ref TYPE REF TO data.
      CREATE DATA line_ref LIKE LINE OF target.
      ASSIGN line_ref->* TO FIELD-SYMBOL(<line>).
      ASSIGN COMPONENT 'MSGTY' OF STRUCTURE <line> TO FIELD-SYMBOL(<msgty>).
      IF sy-subrc <> 0.
        ASSIGN COMPONENT 'MESSAGETYPE' OF STRUCTURE <line> TO <msgty>.
      ENDIF.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      <msgty> = message_type.

      ASSIGN COMPONENT 'MSGID' OF STRUCTURE <line> TO FIELD-SYMBOL(<msgid>).
      IF sy-subrc = 0.
        <msgid> = 'ZBILVAL_MSG'.
      ENDIF.
      ASSIGN COMPONENT 'MSGNO' OF STRUCTURE <line> TO FIELD-SYMBOL(<msgno>).
      IF sy-subrc = 0.
        <msgno> = '001'.
      ENDIF.

      DATA(text) = message-message_text.
      DATA v1 TYPE c LENGTH 50.
      DATA v2 TYPE c LENGTH 50.
      DATA v3 TYPE c LENGTH 50.
      DATA v4 TYPE c LENGTH 50.
      v1 = text.
      IF strlen( text ) > 50.
        DATA(rest2) = strlen( text ) - 50.
        IF rest2 > 50.
          rest2 = 50.
        ENDIF.
        v2 = substring( val = text off = 50 len = rest2 ).
      ENDIF.
      IF strlen( text ) > 100.
        DATA(rest3) = strlen( text ) - 100.
        IF rest3 > 50.
          rest3 = 50.
        ENDIF.
        v3 = substring( val = text off = 100 len = rest3 ).
      ENDIF.
      IF strlen( text ) > 150.
        DATA(rest4) = strlen( text ) - 150.
        IF rest4 > 50.
          rest4 = 50.
        ENDIF.
        v4 = substring( val = text off = 150 len = rest4 ).
      ENDIF.
      ASSIGN COMPONENT 'MSGV1' OF STRUCTURE <line> TO FIELD-SYMBOL(<v1>).
      IF sy-subrc = 0.
        <v1> = v1.
      ENDIF.
      ASSIGN COMPONENT 'MSGV2' OF STRUCTURE <line> TO FIELD-SYMBOL(<v2>).
      IF sy-subrc = 0.
        <v2> = v2.
      ENDIF.
      ASSIGN COMPONENT 'MSGV3' OF STRUCTURE <line> TO FIELD-SYMBOL(<v3>).
      IF sy-subrc = 0.
        <v3> = v3.
      ENDIF.
      ASSIGN COMPONENT 'MSGV4' OF STRUCTURE <line> TO FIELD-SYMBOL(<v4>).
      IF sy-subrc = 0.
        <v4> = v4.
      ENDIF.
      ASSIGN COMPONENT 'MESSAGETEXT' OF STRUCTURE <line> TO FIELD-SYMBOL(<text>).
      IF sy-subrc = 0.
        <text> = text.
      ENDIF.
      IF product IS NOT INITIAL.
        ASSIGN COMPONENT 'PRODUCT' OF STRUCTURE <line> TO FIELD-SYMBOL(<product>).
        IF sy-subrc = 0.
          <product> = product.
        ENDIF.
      ENDIF.
      INSERT <line> INTO TABLE target.
    ENDLOOP.
  ENDMETHOD.

  METHOD partner_id.
    IF partner_key IS SUPPLIED.
      result = read_value(
        structure = partner_key
        names = VALUE #( ( `BUSINESSPARTNER` ) ( `CUSTOMER` ) ( `PARTNER` ) ) ).
    ENDIF.
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.
    LOOP AT general ASSIGNING FIELD-SYMBOL(<row>).
      result = read_value(
        structure = <row>
        names = VALUE #( ( `BUSINESSPARTNER` ) ( `CUSTOMER` ) ( `PARTNER` ) ) ).
      IF result IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD product_id.
    FIELD-SYMBOLS <source> TYPE any.
    ASSIGN COMPONENT 'PRODUCT' OF STRUCTURE row TO FIELD-SYMBOL(<nested>).
    IF sy-subrc = 0 AND is_structure( <nested> ) = abap_true.
      ASSIGN <nested> TO <source>.
    ELSE.
      ASSIGN row TO <source>.
    ENDIF.
    result = read_value(
      structure = <source>
      names = VALUE #( ( `PRODUCT` ) ( `MATERIAL` ) ( `MATNR` ) ) ).
  ENDMETHOD.

  METHOD customer_context.
    result-checkpoint = checkpoint.
    result-complete_document = abap_true.

    DATA(partner) = partner_id( partner_key = partner_key general = general ).
    IF strlen( partner ) <= 10.
      result-header-sold_to_party = partner.
    ENDIF.
    put_custom( EXPORTING name = 'CUSTOMER' value = partner CHANGING fields = result-header-custom_fields ).

    LOOP AT general ASSIGNING FIELD-SYMBOL(<general>).
      put_custom(
        EXPORTING name = 'CUSTOMERNAME'
                  value = read_value( structure = <general> names = VALUE #(
                    ( `ORGANIZATIONBPNAME1` ) ( `BUSINESSPARTNERFULLNAME` ) ( `CUSTOMERNAME` )
                    ( `ORGANIZATIONNAME1` ) ( `NAME1` ) ) )
        CHANGING fields = result-header-custom_fields ).
      put_custom(
        EXPORTING name = 'COUNTRY'
                  value = read_value( structure = <general> names = VALUE #( ( `COUNTRY` ) ( `COUNTRYKEY` ) ) )
        CHANGING fields = result-header-custom_fields ).
      put_custom(
        EXPORTING name = 'ACCOUNTGROUP'
                  value = read_value( structure = <general> names = VALUE #(
                    ( `CUSTOMERACCOUNTGROUP` ) ( `ACCOUNTGROUP` ) ( `KTOKD` ) ) )
        CHANGING fields = result-header-custom_fields ).
      put_custom(
        EXPORTING name = 'TAXNUMBER'
                  value = read_value( structure = <general> names = VALUE #(
                    ( `TAXNUMBER` ) ( `TAXNUMBER1` ) ( `VATREGISTRATION` ) ( `STCEG` ) ( `BPTAXNUMBER` ) ) )
        CHANGING fields = result-header-custom_fields ).
      add_yy1( EXPORTING structure = <general> CHANGING fields = result-header-custom_fields ).
      EXIT.
    ENDLOOP.

    IF sales IS SUPPLIED.
      LOOP AT sales ASSIGNING FIELD-SYMBOL(<sales>).
        APPEND sales_item( row = <sales> position = sy-tabix ) TO result-items.
      ENDLOOP.
    ENDIF.
    IF companies IS SUPPLIED.
      LOOP AT companies ASSIGNING FIELD-SYMBOL(<company>).
        APPEND company_item( row = <company> position = lines( result-items ) + 1 ) TO result-items.
      ENDLOOP.
    ENDIF.

    IF sales IS SUPPLIED.
    IF lines( sales ) = 1 AND lines( result-items ) >= 1.
      DATA(sales_fields) = result-items[ 1 ]-custom_fields.
      IF line_exists( sales_fields[ field_name = 'SALESORGANIZATION' ] ).
        result-header-sales_organization = sales_fields[ field_name = 'SALESORGANIZATION' ]-value.
      ENDIF.
      IF line_exists( sales_fields[ field_name = 'DISTRIBUTIONCHANNEL' ] ).
        result-header-distribution_channel = sales_fields[ field_name = 'DISTRIBUTIONCHANNEL' ]-value.
      ENDIF.
      IF line_exists( sales_fields[ field_name = 'DIVISION' ] ).
        result-header-division = sales_fields[ field_name = 'DIVISION' ]-value.
      ENDIF.
    ENDIF.
    ENDIF.
    IF companies IS SUPPLIED.
    IF lines( companies ) = 1 AND lines( result-items ) >= 1.
      DATA(company_fields) = result-items[ lines( result-items ) ]-custom_fields.
      IF line_exists( company_fields[ field_name = 'COMPANYCODE' ] ).
        result-header-company_code = company_fields[ field_name = 'COMPANYCODE' ]-value.
      ENDIF.
    ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD product_context.
    result-checkpoint = checkpoint.
    result-complete_document = abap_true.

    FIELD-SYMBOLS <source> TYPE any.
    ASSIGN COMPONENT 'PRODUCT' OF STRUCTURE row TO FIELD-SYMBOL(<nested>).
    IF sy-subrc = 0 AND is_structure( <nested> ) = abap_true.
      ASSIGN <nested> TO <source>.
    ELSE.
      ASSIGN row TO <source>.
    ENDIF.

    DATA(product) = read_value(
      structure = <source>
      names = VALUE #( ( `PRODUCT` ) ( `MATERIAL` ) ( `MATNR` ) ) ).
    put_custom( EXPORTING name = 'MATERIAL' value = product CHANGING fields = result-header-custom_fields ).
    DATA(division) = read_value( structure = <source> names = VALUE #( ( `DIVISION` ) ( `SPART` ) ) ).
    result-header-division = division.
    put_custom(
      EXPORTING name = 'PRODUCTTYPE'
                value = read_value( structure = <source> names = VALUE #( ( `PRODUCTTYPE` ) ( `MTART` ) ) )
      CHANGING fields = result-header-custom_fields ).
    put_custom(
      EXPORTING name = 'PRODUCTGROUP'
                value = read_value( structure = <source> names = VALUE #( ( `PRODUCTGROUP` ) ( `MATKL` ) ) )
      CHANGING fields = result-header-custom_fields ).
    put_custom(
      EXPORTING name = 'BASEUNIT'
                value = read_value( structure = <source> names = VALUE #(
                  ( `BASEUNIT` ) ( `BASEUNITOFMEASURE` ) ( `MEINS` ) ) )
      CHANGING fields = result-header-custom_fields ).
    add_yy1( EXPORTING structure = <source> CHANGING fields = result-header-custom_fields ).

    DATA position TYPE i.
    FIELD-SYMBOLS <plants> TYPE ANY TABLE.
    DATA(description) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( row ) ).
    LOOP AT description->components INTO DATA(component).
      UNASSIGN <plants>.
      ASSIGN COMPONENT component-name OF STRUCTURE row TO <plants>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(component_type) = cl_abap_typedescr=>describe_by_data( <plants> ).
      IF component_type->kind <> cl_abap_typedescr=>kind_table.
        CONTINUE.
      ENDIF.
      DATA(line_type) = CAST cl_abap_tabledescr( component_type )->get_table_line_type( ).
      IF line_type->kind <> cl_abap_typedescr=>kind_struct.
        CONTINUE.
      ENDIF.
      DATA(line) = CAST cl_abap_structdescr( line_type ).
      DATA(has_plant) = abap_false.
      LOOP AT line->components INTO DATA(part).
        DATA(part_name) = to_upper( part-name ).
        IF part_name = 'PLANT' OR part_name = 'WERKS'.
          has_plant = abap_true.
        ENDIF.
      ENDLOOP.
      IF has_plant = abap_false.
        CONTINUE.
      ENDIF.
      LOOP AT <plants> ASSIGNING FIELD-SYMBOL(<plant>).
        position = position + 1.
        APPEND plant_item( row = <plant> product = product position = position ) TO result-items.
      ENDLOOP.
      EXIT.
    ENDLOOP.
  ENDMETHOD.

  METHOD sales_item.
    result-billing_document_item = item_number( position ).
    result-customer_account_assignment = read_value(
      structure = row
      names = VALUE #( ( `CUSTOMERACCOUNTASSIGNMENTGROUP` ) ( `KTGRD` ) ) ).
    put_custom( EXPORTING name = 'RECORDTYPE' value = 'SALES' CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'SALESORGANIZATION'
                value = read_value( structure = row names = VALUE #( ( `SALESORGANIZATION` ) ( `VKORG` ) ) )
      CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'DISTRIBUTIONCHANNEL'
                value = read_value( structure = row names = VALUE #( ( `DISTRIBUTIONCHANNEL` ) ( `VTWEG` ) ) )
      CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'DIVISION'
                value = read_value( structure = row names = VALUE #( ( `DIVISION` ) ( `SPART` ) ) )
      CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'PAYMENTTERMS'
                value = read_value( structure = row names = VALUE #( ( `CUSTOMERPAYMENTTERMS` ) ( `PAYMENTTERMS` ) ( `ZTERM` ) ) )
      CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'INCOTERMS'
                value = read_value( structure = row names = VALUE #( ( `INCOTERMSCLASSIFICATION` ) ( `INCOTERMS` ) ( `INCO1` ) ) )
      CHANGING fields = result-custom_fields ).
    add_yy1( EXPORTING structure = row CHANGING fields = result-custom_fields ).
  ENDMETHOD.

  METHOD company_item.
    result-billing_document_item = item_number( position ).
    put_custom( EXPORTING name = 'RECORDTYPE' value = 'COMPANY' CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'COMPANYCODE'
                value = read_value( structure = row names = VALUE #( ( `COMPANYCODE` ) ( `BUKRS` ) ) )
      CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'RECONCILIATIONACCT'
                value = read_value( structure = row names = VALUE #(
                  ( `RECONCILIATIONACCOUNT` ) ( `RECONCILIATIONACCT` ) ( `AKONT` ) ) )
      CHANGING fields = result-custom_fields ).
    add_yy1( EXPORTING structure = row CHANGING fields = result-custom_fields ).
  ENDMETHOD.

  METHOD plant_item.
    result-billing_document_item = item_number( position ).
    result-material = product.
    put_custom( EXPORTING name = 'MATERIAL' value = product CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'PLANT'
                value = read_value( structure = row names = VALUE #( ( `PLANT` ) ( `WERKS` ) ) )
      CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'PROFITCENTER'
                value = read_value( structure = row names = VALUE #( ( `PROFITCENTER` ) ( `PRCTR` ) ) )
      CHANGING fields = result-custom_fields ).
    put_custom(
      EXPORTING name = 'PURCHASINGGROUP'
                value = read_value( structure = row names = VALUE #( ( `PURCHASINGGROUP` ) ( `EKGRP` ) ) )
      CHANGING fields = result-custom_fields ).
    add_yy1( EXPORTING structure = row CHANGING fields = result-custom_fields ).
  ENDMETHOD.

  METHOD item_number.
    DATA number TYPE n LENGTH 6.
    number = position.
    result = number.
  ENDMETHOD.

  METHOD read_value.
    found = abap_false.
    IF is_structure( structure ) = abap_false.
      RETURN.
    ENDIF.
    result = read_direct( EXPORTING structure = structure names = names IMPORTING found = found ).
    IF found = abap_true.
      RETURN.
    ENDIF.

    DATA(description) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( structure ) ).
    LOOP AT description->components INTO DATA(component).
      ASSIGN COMPONENT component-name OF STRUCTURE structure TO FIELD-SYMBOL(<nested>).
      IF sy-subrc <> 0 OR is_structure( <nested> ) = abap_false.
        CONTINUE.
      ENDIF.
      result = read_direct( EXPORTING structure = <nested> names = names IMPORTING found = found ).
      IF found = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_direct.
    found = abap_false.
    LOOP AT names INTO DATA(name).
      ASSIGN COMPONENT name OF STRUCTURE structure TO FIELD-SYMBOL(<value>).
      IF sy-subrc = 0.
        found = abap_true.
        result = to_upper( condense( CONV string( <value> ) ) ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD put_custom.
    IF value IS INITIAL.
      RETURN.
    ENDIF.
    IF line_exists( fields[ field_name = name ] ).
      RETURN.
    ENDIF.
    INSERT VALUE #( field_name = name value = value ) INTO TABLE fields.
  ENDMETHOD.

  METHOD add_yy1.
    IF is_structure( structure ) = abap_false.
      RETURN.
    ENDIF.
    DATA(description) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( structure ) ).
    LOOP AT description->components INTO DATA(component).
      DATA(name) = to_upper( component-name ).
      IF name NP 'YY1_*'.
        ASSIGN COMPONENT component-name OF STRUCTURE structure TO FIELD-SYMBOL(<nested>).
        IF sy-subrc = 0 AND is_structure( <nested> ) = abap_true.
          add_yy1( EXPORTING structure = <nested> CHANGING fields = fields ).
        ENDIF.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT component-name OF STRUCTURE structure TO FIELD-SYMBOL(<value>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      put_custom( EXPORTING name = name value = condense( CONV string( <value> ) ) CHANGING fields = fields ).
    ENDLOOP.
  ENDMETHOD.

  METHOD is_structure.
    result = xsdbool( cl_abap_typedescr=>describe_by_data( data )->kind = cl_abap_typedescr=>kind_struct ).
  ENDMETHOD.

ENDCLASS.
