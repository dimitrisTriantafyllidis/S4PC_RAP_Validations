CLASS lcl_provider DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_rule_provider.
    DATA rules   TYPE zif_bilval_check=>ty_rules.
    DATA plugins TYPE zif_bilval_check=>ty_plugin_cfgs.
ENDCLASS.

CLASS lcl_provider IMPLEMENTATION.
  METHOD zif_bilval_rule_provider~get_rules.
    result = rules.
  ENDMETHOD.

  METHOD zif_bilval_rule_provider~get_plugins.
    result = plugins.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_marker DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_check.
    DATA marker TYPE string.
ENDCLASS.

CLASS lcl_marker IMPLEMENTATION.
  METHOD zif_bilval_check~validate.
    APPEND VALUE #(
      severity     = zif_bilval_check=>severity-warning
      plugin_id    = marker
      outcome      = zif_bilval_check=>outcome-block
      message_text = marker ) TO result.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_factory DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_factory.
    TYPES:
      BEGIN OF ty_entry,
        plugin_id TYPE zif_bilval_check=>ty_plugin_id,
        plugin    TYPE REF TO lcl_marker,
      END OF ty_entry.
    DATA entries TYPE HASHED TABLE OF ty_entry WITH UNIQUE KEY plugin_id.
ENDCLASS.

CLASS lcl_factory IMPLEMENTATION.
  METHOD zif_bilval_factory~create.
    ASSIGN entries[ plugin_id = plugin_id ] TO FIELD-SYMBOL(<entry>).
    IF sy-subrc = 0.
      result = <entry>-plugin.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_reader DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_preceding_reader.
    DATA items  TYPE zif_bilval_preceding_reader=>ty_items.
    DATA failed TYPE abap_bool.
ENDCLASS.

CLASS lcl_reader IMPLEMENTATION.
  METHOD zif_bilval_preceding_reader~read_sales_order_items.
    failed = me->failed.
    result = items.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_lookup DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_md_lookup.
    DATA customer TYPE zif_bilval_check=>ty_checkpoint.
    DATA product  TYPE zif_bilval_check=>ty_checkpoint.
ENDCLASS.

CLASS lcl_lookup IMPLEMENTATION.
  METHOD zif_bilval_md_lookup~customer_checkpoint.
    result = customer.
  ENDMETHOD.

  METHOD zif_bilval_md_lookup~product_checkpoint.
    result = product.
  ENDMETHOD.
ENDCLASS.
