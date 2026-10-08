CLASS zcl_bilval_badi_transfer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Enhancement spot ES_PF_BILLING_DT, BAdI SD_BIL_DATA_TRANSFER.
    " Filter DATA_TRANSFER = ZBILVAL_TRANSFER.
    " Released method name in the tenant is change_data. Align this method
    " if the released interface uses a different name.
    INTERFACES if_sd_bil_data_transfer.

    METHODS constructor
      IMPORTING engine TYPE REF TO zcl_bilval_engine OPTIONAL.

    METHODS apply
      IMPORTING
        header   TYPE any
        item     TYPE any
      EXPORTING
        rejected TYPE abap_bool
        reason   TYPE string.

  PRIVATE SECTION.
    DATA engine TYPE REF TO zcl_bilval_engine.

    METHODS messages_for
      IMPORTING
        header          TYPE any
        item            TYPE any
        checkpoint      TYPE zif_bilval_check=>ty_checkpoint
        action          TYPE zif_bilval_check=>ty_action OPTIONAL
        complete        TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)   TYPE zif_bilval_check=>ty_messages.
ENDCLASS.


CLASS zcl_bilval_badi_transfer IMPLEMENTATION.

  METHOD constructor.
    IF engine IS BOUND.
      me->engine = engine.
    ENDIF.
  ENDMETHOD.

  METHOD if_sd_bil_data_transfer~change_data.
    MOVE-CORRESPONDING bil_doc TO bil_doc_res.
    MOVE-CORRESPONDING bil_doc_item TO bil_doc_item_res.
    MOVE-CORRESPONDING bil_doc_item_contr TO bil_doc_item_contr_res.

    apply(
      EXPORTING header = bil_doc
                item   = bil_doc_item
      IMPORTING rejected = billingdocumentitemisrejected
                reason   = DATA(reason_text) ).
    IF billingdocumentitemisrejected = abap_true.
      billgdocitmrejectionreasontext = reason_text.
    ENDIF.
  ENDMETHOD.

  METHOD apply.
    DATA(messages) = messages_for(
      header = header
      item = item
      checkpoint = zif_bilval_check=>checkpoint-create ).
    rejected = zcl_bilval_outcome=>has_block( messages ).
    reason = zcl_bilval_outcome=>blocking_text( messages ).
  ENDMETHOD.

  METHOD messages_for.
    DATA(mapper) = NEW zcl_bilval_context_mapper( ).
    DATA(context) = mapper->map(
      checkpoint = checkpoint
      header = header
      item = item
      action = action
      complete_document = complete ).
    IF engine IS BOUND.
      result = engine->validate( context ).
    ELSE.
      result = zcl_bilval_engine=>create( )->validate( context ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
