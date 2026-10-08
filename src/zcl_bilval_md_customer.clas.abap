CLASS zcl_bilval_md_customer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        engine TYPE REF TO zcl_bilval_engine OPTIONAL
        lookup TYPE REF TO zif_bilval_md_lookup OPTIONAL.

    METHODS validate_customer
      IMPORTING
        partner_key TYPE any OPTIONAL
        general     TYPE ANY TABLE
        sales       TYPE ANY TABLE OPTIONAL
        companies   TYPE ANY TABLE OPTIONAL
      CHANGING
        validation_messages TYPE ANY TABLE.

  PRIVATE SECTION.
    DATA engine TYPE REF TO zcl_bilval_engine.
    DATA lookup TYPE REF TO zif_bilval_md_lookup.
    DATA mapper TYPE REF TO zcl_bilval_md_mapper.
ENDCLASS.


CLASS zcl_bilval_md_customer IMPLEMENTATION.

  METHOD constructor.
    mapper = NEW zcl_bilval_md_mapper( ).
    me->engine = engine.
    me->lookup = lookup.
    IF me->engine IS NOT BOUND.
      me->engine = zcl_bilval_engine=>create( ).
    ENDIF.
    IF me->lookup IS NOT BOUND.
      me->lookup = NEW zcl_bilval_md_lookup( ).
    ENDIF.
  ENDMETHOD.

  METHOD validate_customer.
    TYPES:
      BEGIN OF ty_key,
        businesspartner TYPE c LENGTH 10,
      END OF ty_key,
      BEGIN OF ty_row,
        dummy TYPE c LENGTH 1,
      END OF ty_row.
    DATA empty_key TYPE ty_key.
    DATA empty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    DATA partner TYPE string.
    IF partner_key IS SUPPLIED.
      partner = mapper->partner_id( partner_key = partner_key general = general ).
    ELSE.
      partner = mapper->partner_id( general = general ).
    ENDIF.
    DATA(checkpoint) = lookup->customer_checkpoint( partner ).

    DATA context TYPE zif_bilval_check=>ty_context.
    IF partner_key IS SUPPLIED.
      IF sales IS SUPPLIED AND companies IS SUPPLIED.
        context = mapper->customer_context(
          checkpoint = checkpoint partner_key = partner_key general = general sales = sales companies = companies ).
      ELSEIF sales IS SUPPLIED.
        context = mapper->customer_context(
          checkpoint = checkpoint partner_key = partner_key general = general sales = sales companies = empty_rows ).
      ELSEIF companies IS SUPPLIED.
        context = mapper->customer_context(
          checkpoint = checkpoint partner_key = partner_key general = general sales = empty_rows companies = companies ).
      ELSE.
        context = mapper->customer_context(
          checkpoint = checkpoint partner_key = partner_key general = general sales = empty_rows companies = empty_rows ).
      ENDIF.
    ELSEIF sales IS SUPPLIED AND companies IS SUPPLIED.
      context = mapper->customer_context(
        checkpoint = checkpoint partner_key = empty_key general = general sales = sales companies = companies ).
    ELSEIF sales IS SUPPLIED.
      context = mapper->customer_context(
        checkpoint = checkpoint partner_key = empty_key general = general sales = sales companies = empty_rows ).
    ELSEIF companies IS SUPPLIED.
      context = mapper->customer_context(
        checkpoint = checkpoint partner_key = empty_key general = general sales = empty_rows companies = companies ).
    ELSE.
      context = mapper->customer_context(
        checkpoint = checkpoint partner_key = empty_key general = general sales = empty_rows companies = empty_rows ).
    ENDIF.

    zcl_bilval_md_mapper=>add_messages(
      EXPORTING messages = engine->validate( context )
      CHANGING target = validation_messages ).
  ENDMETHOD.

ENDCLASS.
