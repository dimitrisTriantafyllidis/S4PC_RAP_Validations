INTERFACE zif_bilval_md_lookup
  PUBLIC.

  METHODS customer_checkpoint
    IMPORTING
      partner       TYPE string
    RETURNING
      VALUE(result) TYPE zif_bilval_check=>ty_checkpoint.

  METHODS product_checkpoint
    IMPORTING
      product       TYPE string
    RETURNING
      VALUE(result) TYPE zif_bilval_check=>ty_checkpoint.
ENDINTERFACE.
