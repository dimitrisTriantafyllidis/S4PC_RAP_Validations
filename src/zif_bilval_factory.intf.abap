INTERFACE zif_bilval_factory
  PUBLIC.

  METHODS create
    IMPORTING plugin_id     TYPE zif_bilval_check=>ty_plugin_id
    RETURNING VALUE(result) TYPE REF TO zif_bilval_check.

ENDINTERFACE.
