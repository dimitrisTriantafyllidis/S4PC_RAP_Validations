CLASS zcl_bilval_badi_approval DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Enhancement spot ES_SD_BIL_EXTEND, BAdI SD_BIL_APM_SET_APPROVAL_REASON.
    " Interface IF_SD_BIL_APM_SET_APPR_REASON. Single implementation, no filter.
    " Align set_approval_reason if the released method name differs.
    INTERFACES if_sd_bil_apm_set_appr_reason.

    METHODS constructor
      IMPORTING engine TYPE REF TO zcl_bilval_engine OPTIONAL.

    METHODS apply
      IMPORTING
        header          TYPE any
        items           TYPE ANY TABLE OPTIONAL
      EXPORTING
        approval_reason TYPE zif_bilval_check=>ty_approval_reason.

  PRIVATE SECTION.
    DATA engine TYPE REF TO zcl_bilval_engine.
ENDCLASS.


CLASS zcl_bilval_badi_approval IMPLEMENTATION.

  METHOD constructor.
    IF engine IS BOUND.
      me->engine = engine.
    ENDIF.
  ENDMETHOD.

  METHOD if_sd_bil_apm_set_appr_reason~set_approval_reason.
    apply(
      EXPORTING header = billingprocdocument
                items  = billingprocdocumentitem
      IMPORTING approval_reason = DATA(reason) ).
    IF reason IS NOT INITIAL.
      billingprocdocapprovalreason = reason.
    ENDIF.
  ENDMETHOD.

  METHOD apply.
    DATA(mapper) = NEW zcl_bilval_context_mapper( ).
    DATA context TYPE zif_bilval_check=>ty_context.
    IF items IS SUPPLIED.
      context = mapper->map(
        checkpoint = zif_bilval_check=>checkpoint-approval
        header = header
        items = items
        complete_document = abap_true ).
    ELSE.
      context = mapper->map(
        checkpoint = zif_bilval_check=>checkpoint-approval
        header = header
        complete_document = abap_true ).
    ENDIF.
    DATA messages TYPE zif_bilval_check=>ty_messages.
    IF engine IS BOUND.
      messages = engine->validate( context ).
    ELSE.
      messages = zcl_bilval_engine=>create( )->validate( context ).
    ENDIF.
    approval_reason = zcl_bilval_outcome=>approval_reason( messages ).
  ENDMETHOD.

ENDCLASS.
