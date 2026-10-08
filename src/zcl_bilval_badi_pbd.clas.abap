CLASS zcl_bilval_badi_pbd DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " BAdI SD_BIL_PBD_ACTION_CHECK, released with SAP Cloud ERP 2602.
    " Confirm the enhancement spot and method name in Released Objects before activation.
    " The method below uses the parameter names published for this check:
    " billing document header, item table, action, and a message table.
    INTERFACES if_sd_bil_pbd_action_check.

    METHODS constructor
      IMPORTING engine TYPE REF TO zcl_bilval_engine OPTIONAL.

    METHODS checkpoint_for
      IMPORTING action        TYPE string
      RETURNING VALUE(result) TYPE zif_bilval_check=>ty_checkpoint.

    METHODS apply
      IMPORTING
        header   TYPE any
        items    TYPE ANY TABLE OPTIONAL
        action   TYPE string OPTIONAL
      EXPORTING
        rejected TYPE abap_bool
        reason   TYPE string.

  PRIVATE SECTION.
    DATA engine TYPE REF TO zcl_bilval_engine.
ENDCLASS.


CLASS zcl_bilval_badi_pbd IMPLEMENTATION.

  METHOD constructor.
    IF engine IS BOUND.
      me->engine = engine.
    ENDIF.
  ENDMETHOD.

  METHOD if_sd_bil_pbd_action_check~check.
    apply(
      EXPORTING header = billingprocdocument
                items  = billingprocdocumentitem
                action = CONV #( action )
      IMPORTING rejected = DATA(rejected)
                reason = DATA(reason_text) ).

    IF rejected = abap_true.
      APPEND VALUE #(
        messagetype = 'E'
        messagetext = reason_text ) TO messages.
    ENDIF.
  ENDMETHOD.

  METHOD checkpoint_for.
    DATA(normalized) = to_upper( condense( action ) ).
    IF normalized CS 'AUTO'.
      result = zif_bilval_check=>checkpoint-pbd_auto.
    ELSEIF normalized CS 'CREAT'.
      result = zif_bilval_check=>checkpoint-pbd_create.
    ELSEIF normalized CS 'FINAL'.
      result = zif_bilval_check=>checkpoint-pbd_final.
    ELSEIF zcl_bilval_fields=>is_checkpoint( CONV #( normalized ) ) = abap_true.
      result = normalized.
    ELSE.
      result = zif_bilval_check=>checkpoint-pbd_final.
    ENDIF.
  ENDMETHOD.

  METHOD apply.
    DATA(mapper) = NEW zcl_bilval_context_mapper( ).
    DATA context TYPE zif_bilval_check=>ty_context.
    IF items IS SUPPLIED.
      context = mapper->map(
        checkpoint = checkpoint_for( action )
        header = header
        items = items
        action = CONV #( action )
        complete_document = abap_true ).
    ELSE.
      context = mapper->map(
        checkpoint = checkpoint_for( action )
        header = header
        action = CONV #( action )
        complete_document = abap_true ).
    ENDIF.
    DATA messages TYPE zif_bilval_check=>ty_messages.
    IF engine IS BOUND.
      messages = engine->validate( context ).
    ELSE.
      messages = zcl_bilval_engine=>create( )->validate( context ).
    ENDIF.
    rejected = zcl_bilval_outcome=>has_block( messages ).
    reason = zcl_bilval_outcome=>blocking_text( messages ).
  ENDMETHOD.

ENDCLASS.
