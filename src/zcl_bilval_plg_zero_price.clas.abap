CLASS zcl_bilval_plg_zero_price DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_bilval_check.
ENDCLASS.


CLASS zcl_bilval_plg_zero_price IMPLEMENTATION.

  METHOD zif_bilval_check~validate.
    IF context-has_current_item = abap_true.
      IF context-current_item-net_amount = 0.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-error
          plugin_id    = zcl_bilval_factory=>plugin-zero_price
          outcome      = zif_bilval_check=>outcome-block
          item         = context-current_item-billing_document_item
          message_text = |Net amount is zero for item { context-current_item-billing_document_item }.| ) TO result.
      ENDIF.
      RETURN.
    ENDIF.

    LOOP AT context-items INTO DATA(item) WHERE net_amount = 0.
      APPEND VALUE #(
        severity     = zif_bilval_check=>severity-error
        plugin_id    = zcl_bilval_factory=>plugin-zero_price
        outcome      = zif_bilval_check=>outcome-block
        item         = item-billing_document_item
        message_text = |Net amount is zero for item { item-billing_document_item }.| ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
