INTERFACE zif_bilval_log
  PUBLIC.

  METHODS add_messages
    IMPORTING
      context  TYPE zif_bilval_check=>ty_context
      messages TYPE zif_bilval_check=>ty_messages.

ENDINTERFACE.
