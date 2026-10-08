CLASS zcl_bilval_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_bilval_log.

  PRIVATE SECTION.
    CONSTANTS object    TYPE c LENGTH 20 VALUE 'ZBILVAL'.
    CONSTANTS subobject TYPE c LENGTH 20 VALUE 'RUN'.
ENDCLASS.


CLASS zcl_bilval_log IMPLEMENTATION.

  METHOD zif_bilval_log~add_messages.
    IF messages IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(external_id) = |{ context-checkpoint }-{ context-header-billing_document }|.
        IF context-header-billing_document IS INITIAL.
          external_id = |{ context-checkpoint }-{ context-header-reference_document }|.
        ENDIF.
        IF strlen( external_id ) > 100.
          external_id = external_id(100).
        ENDIF.

        DATA(header) = cl_bali_header_setter=>create(
          object      = object
          subobject   = subobject
          external_id = CONV #( external_id ) ).
        DATA(log) = cl_bali_log=>create_with_header( header = header ).

        LOOP AT messages INTO DATA(message).
          DATA severity TYPE c LENGTH 1.
          IF message-severity = zif_bilval_check=>severity-warning.
            severity = if_bali_constants=>c_severity_warning.
          ELSE.
            severity = if_bali_constants=>c_severity_error.
          ENDIF.
          DATA(text) = message-message_text.
          IF strlen( text ) > 200.
            text = text(200).
          ENDIF.
          log->add_item( cl_bali_free_text_setter=>create( severity = severity text = CONV #( text ) ) ).
        ENDLOOP.

        cl_bali_log_db=>get_instance( )->save_log( log = log ).
      CATCH cx_root.
        " A missing log object must not block billing.
        RETURN.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
