CLASS zcl_bilval_md_lookup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_bilval_md_lookup.
ENDCLASS.


CLASS zcl_bilval_md_lookup IMPLEMENTATION.

  METHOD zif_bilval_md_lookup~customer_checkpoint.
    result = zif_bilval_check=>checkpoint-customer.
    IF partner IS INITIAL.
      RETURN.
    ENDIF.

    DATA(number) = to_upper( condense( partner ) ).
    DATA internal TYPE n LENGTH 10.
    internal = number.

    TRY.
        SELECT SINGLE customer
          FROM i_customer
          WHERE customer = @number
          INTO @DATA(found).
        IF sy-subrc <> 0.
          DATA(internal_customer) = CONV string( internal ).
          SELECT SINGLE customer
            FROM i_customer
            WHERE customer = @internal_customer
            INTO @found.
        ENDIF.
        IF sy-subrc = 0.
          result = zif_bilval_check=>checkpoint-cust_upd.
        ELSE.
          result = zif_bilval_check=>checkpoint-cust_add.
        ENDIF.
      CATCH cx_root.
        result = zif_bilval_check=>checkpoint-customer.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_bilval_md_lookup~product_checkpoint.
    result = zif_bilval_check=>checkpoint-material.
    IF product IS INITIAL.
      RETURN.
    ENDIF.

    DATA(number) = to_upper( condense( product ) ).

    TRY.
        SELECT SINGLE product
          FROM i_product
          WHERE product = @number
          INTO @DATA(found).
        IF sy-subrc = 0.
          result = zif_bilval_check=>checkpoint-mat_upd.
        ELSE.
          result = zif_bilval_check=>checkpoint-mat_add.
        ENDIF.
      CATCH cx_root.
        result = zif_bilval_check=>checkpoint-material.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
