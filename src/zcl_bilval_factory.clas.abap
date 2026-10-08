CLASS zcl_bilval_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_bilval_factory.

    CONSTANTS:
      BEGIN OF plugin,
        zero_price TYPE zif_bilval_check=>ty_plugin_id VALUE 'ZERO_PRICE',
        preceding  TYPE zif_bilval_check=>ty_plugin_id VALUE 'PRECEDING',
      END OF plugin.

    TYPES:
      BEGIN OF ty_catalog_entry,
        plugin_id   TYPE zif_bilval_check=>ty_plugin_id,
        description TYPE c LENGTH 60,
      END OF ty_catalog_entry,
      ty_catalog TYPE STANDARD TABLE OF ty_catalog_entry WITH EMPTY KEY.

    CLASS-METHODS get_catalog
      RETURNING VALUE(result) TYPE ty_catalog.

    CLASS-METHODS is_known
      IMPORTING plugin_id    TYPE zif_bilval_check=>ty_plugin_id
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_bilval_factory IMPLEMENTATION.

  METHOD get_catalog.
    result = VALUE #(
      ( plugin_id = plugin-zero_price description = 'Reject an item whose net amount is zero' )
      ( plugin_id = plugin-preceding  description = 'Reject when a preceding sales-order item is missing' ) ).
  ENDMETHOD.

  METHOD is_known.
    result = xsdbool( line_exists( get_catalog( )[ plugin_id = to_upper( plugin_id ) ] ) ).
  ENDMETHOD.

  METHOD zif_bilval_factory~create.
    CASE to_upper( plugin_id ).
      WHEN plugin-zero_price.
        result = NEW zcl_bilval_plg_zero_price( ).
      WHEN plugin-preceding.
        result = NEW zcl_bilval_plg_preceding( ).
      WHEN OTHERS.
        CLEAR result.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
