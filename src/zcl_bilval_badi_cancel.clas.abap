CLASS zcl_bilval_badi_cancel DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Enhancement spot ES_PF_BILLING_DT, BAdI SD_BIL_FLEX_CANCELLATION.
    " Align check_cancellation if the released interface method has another name.
    INTERFACES if_sd_bil_flex_cancellation.

    METHODS constructor
      IMPORTING engine TYPE REF TO zcl_bilval_engine OPTIONAL.

    METHODS apply
      IMPORTING header   TYPE any
      EXPORTING rejected TYPE abap_bool
                reason   TYPE string.

  PRIVATE SECTION.
    DATA engine TYPE REF TO zcl_bilval_engine.
ENDCLASS.


CLASS zcl_bilval_badi_cancel IMPLEMENTATION.

  METHOD constructor.
    IF engine IS BOUND.
      me->engine = engine.
    ENDIF.
  ENDMETHOD.

  METHOD if_sd_bil_flex_cancellation~check_cancellation.
    MOVE-CORRESPONDING cancellation_bil_doc TO cancellation_bil_doc_res.

    apply(
      EXPORTING header = bil_doc
      IMPORTING rejected = bil_doc_canc_is_rejected
                reason = DATA(reason_text) ).
    IF bil_doc_canc_is_rejected = abap_true.
      rejection_reason_text = reason_text.
    ENDIF.
  ENDMETHOD.

  METHOD apply.
    DATA(context) = NEW zcl_bilval_context_mapper( )->map(
      checkpoint = zif_bilval_check=>checkpoint-cancel
      header = header
      complete_document = abap_true ).
    DATA(messages) = COND zif_bilval_check=>ty_messages(
      WHEN engine IS BOUND THEN engine->validate( context )
      ELSE zcl_bilval_engine=>create( )->validate( context ) ).
    rejected = zcl_bilval_outcome=>has_block( messages ).
    reason = zcl_bilval_outcome=>blocking_text( messages ).
  ENDMETHOD.

ENDCLASS.
