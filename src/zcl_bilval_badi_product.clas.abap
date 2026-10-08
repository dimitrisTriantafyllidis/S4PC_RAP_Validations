CLASS zcl_bilval_badi_product DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Enhancement spot for BAdI BD_CMD_PROD_DATA_API_CHECK_2.
    " Interface IF_BD_CMD_PROD_DATA_API_CHECK_2, method CHECK_DATA.
    " Align the interface and method names with the released BAdI in the tenant
    " before this class is activated. The check itself is in ZCL_BILVAL_MD_PRODUCT.
    INTERFACES if_bd_cmd_prod_data_api_check_2.

    METHODS constructor
      IMPORTING checker TYPE REF TO zcl_bilval_md_product OPTIONAL.

  PRIVATE SECTION.
    DATA checker TYPE REF TO zcl_bilval_md_product.
ENDCLASS.


CLASS zcl_bilval_badi_product IMPLEMENTATION.

  METHOD constructor.
    IF checker IS BOUND.
      me->checker = checker.
    ELSE.
      me->checker = NEW zcl_bilval_md_product( ).
    ENDIF.
  ENDMETHOD.

  METHOD if_bd_cmd_prod_data_api_check_2~check_data.
    IF checker IS NOT BOUND.
      checker = NEW zcl_bilval_md_product( ).
    ENDIF.
    checker->validate_product(
      EXPORTING data = it_data
      CHANGING messages = ct_message ).
  ENDMETHOD.

ENDCLASS.
