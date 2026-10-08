CLASS zcl_bilval_md_product DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        engine TYPE REF TO zcl_bilval_engine OPTIONAL
        lookup TYPE REF TO zif_bilval_md_lookup OPTIONAL.

    METHODS validate_product
      IMPORTING
        data TYPE ANY TABLE
      CHANGING
        messages TYPE ANY TABLE.

  PRIVATE SECTION.
    DATA engine TYPE REF TO zcl_bilval_engine.
    DATA lookup TYPE REF TO zif_bilval_md_lookup.
    DATA mapper TYPE REF TO zcl_bilval_md_mapper.
ENDCLASS.


CLASS zcl_bilval_md_product IMPLEMENTATION.

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

  METHOD validate_product.
    LOOP AT data ASSIGNING FIELD-SYMBOL(<row>).
      DATA(product) = mapper->product_id( <row> ).
      DATA(checkpoint) = lookup->product_checkpoint( product ).
      DATA(context) = mapper->product_context( checkpoint = checkpoint row = <row> ).
      zcl_bilval_md_mapper=>add_messages(
        EXPORTING
          messages = engine->validate( context )
          product = product
          warnings = abap_true
        CHANGING target = messages ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
