INTERFACE zif_bilval_preceding_reader
  PUBLIC.

  TYPES:
    BEGIN OF ty_item,
      sales_document      TYPE zif_bilval_check=>ty_document,
      sales_document_item TYPE zif_bilval_check=>ty_item_number,
      material            TYPE c LENGTH 40,
    END OF ty_item,
    ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

  METHODS read_sales_order_items
    IMPORTING sales_document TYPE zif_bilval_check=>ty_document
    EXPORTING failed         TYPE abap_bool
    RETURNING VALUE(result)  TYPE ty_items.

ENDINTERFACE.
