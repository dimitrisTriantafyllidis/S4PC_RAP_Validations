CLASS zcl_bilval_outcome DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS blocking_text
      IMPORTING messages      TYPE zif_bilval_check=>ty_messages
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS approval_reason
      IMPORTING messages      TYPE zif_bilval_check=>ty_messages
      RETURNING VALUE(result) TYPE zif_bilval_check=>ty_approval_reason.

    CLASS-METHODS has_block
      IMPORTING messages      TYPE zif_bilval_check=>ty_messages
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_bilval_outcome IMPLEMENTATION.

  METHOD blocking_text.
    LOOP AT messages INTO DATA(message)
      WHERE severity = zif_bilval_check=>severity-error
        AND outcome  = zif_bilval_check=>outcome-block.
      IF result IS NOT INITIAL.
        result = |{ result }; |.
      ENDIF.
      result = |{ result }{ message-message_text }|.
    ENDLOOP.
    IF strlen( result ) > 200.
      result = result(200).
    ENDIF.
  ENDMETHOD.

  METHOD approval_reason.
    LOOP AT messages INTO DATA(message) WHERE approval_reason IS NOT INITIAL.
      result = message-approval_reason.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD has_block.
    result = xsdbool( line_exists( messages[ severity = zif_bilval_check=>severity-error
                                             outcome  = zif_bilval_check=>outcome-block ] ) ).
  ENDMETHOD.

ENDCLASS.
