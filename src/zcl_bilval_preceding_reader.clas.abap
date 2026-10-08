CLASS zcl_bilval_preceding_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_bilval_preceding_reader.
ENDCLASS.


CLASS zcl_bilval_preceding_reader IMPLEMENTATION.

  METHOD zif_bilval_preceding_reader~read_sales_order_items.
    failed = abap_false.
    IF sales_document IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        SELECT salesorder, salesorderitem, material
          FROM i_salesorderitem
          WHERE salesorder = @sales_document
          INTO TABLE @DATA(selected).

        LOOP AT selected INTO DATA(row).
          APPEND VALUE #(
            sales_document = row-salesorder
            sales_document_item = row-salesorderitem
            material = row-material ) TO result.
        ENDLOOP.
      CATCH cx_root.
        failed = abap_true.
        CLEAR result.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
