CLASS zcl_bilval_plg_preceding DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_bilval_check.

    METHODS constructor
      IMPORTING reader TYPE REF TO zif_bilval_preceding_reader OPTIONAL.

  PRIVATE SECTION.
    DATA reader TYPE REF TO zif_bilval_preceding_reader.

    METHODS item_number
      IMPORTING value         TYPE clike
      RETURNING VALUE(result) TYPE zif_bilval_check=>ty_item_number.

    METHODS collect_sales_documents
      IMPORTING context       TYPE zif_bilval_check=>ty_context
      RETURNING VALUE(result) TYPE string_table.

    METHODS billing_contains_item
      IMPORTING
        context             TYPE zif_bilval_check=>ty_context
        sales_document      TYPE zif_bilval_check=>ty_document
        sales_document_item TYPE zif_bilval_check=>ty_item_number
      RETURNING
        VALUE(result)       TYPE abap_bool.
ENDCLASS.


CLASS zcl_bilval_plg_preceding IMPLEMENTATION.

  METHOD constructor.
    IF reader IS BOUND.
      me->reader = reader.
    ELSE.
      me->reader = NEW zcl_bilval_preceding_reader( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_bilval_check~validate.
    DATA(sales_documents) = collect_sales_documents( context ).

    LOOP AT sales_documents INTO DATA(sales_document).
      DATA(preceding) = reader->read_sales_order_items(
        EXPORTING sales_document = CONV #( sales_document )
        IMPORTING failed = DATA(failed) ).

      IF failed = abap_true.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-warning
          plugin_id    = zcl_bilval_factory=>plugin-preceding
          outcome      = zif_bilval_check=>outcome-block
          message_text = |Preceding sales order { sales_document } could not be read and was skipped.| ) TO result.
        CONTINUE.
      ENDIF.

      IF context-complete_document = abap_true.
        LOOP AT preceding INTO DATA(required).
          DATA(required_item) = item_number( required-sales_document_item ).
          IF billing_contains_item(
               context = context
               sales_document = CONV #( sales_document )
               sales_document_item = required_item ) = abap_false.
            APPEND VALUE #(
              severity     = zif_bilval_check=>severity-error
              plugin_id    = zcl_bilval_factory=>plugin-preceding
              outcome      = zif_bilval_check=>outcome-block
              message_text = |Sales order { sales_document } item { required_item } is missing from the billing document.| ) TO result.
          ENDIF.
        ENDLOOP.
        CONTINUE.
      ENDIF.

      IF context-has_current_item = abap_false
        OR context-current_item-sales_document <> sales_document.
        CONTINUE.
      ENDIF.

      DATA(current_item) = item_number( context-current_item-sales_document_item ).
      DATA(order_number) = CONV zif_bilval_check=>ty_document( sales_document ).
      DATA(current_exists) = abap_false.
      LOOP AT preceding INTO DATA(preceding_item)
        WHERE sales_document = order_number.
        IF item_number( preceding_item-sales_document_item ) = current_item.
          current_exists = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF current_exists = abap_false.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-error
          plugin_id    = zcl_bilval_factory=>plugin-preceding
          outcome      = zif_bilval_check=>outcome-block
          item         = context-current_item-billing_document_item
          message_text = |Item { context-current_item-billing_document_item } does not exist on sales order { sales_document }.| ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD collect_sales_documents.
    IF context-has_current_item = abap_true AND context-current_item-sales_document IS NOT INITIAL.
      APPEND context-current_item-sales_document TO result.
    ENDIF.
    LOOP AT context-items INTO DATA(item) WHERE sales_document IS NOT INITIAL.
      IF NOT line_exists( result[ table_line = item-sales_document ] ).
        APPEND item-sales_document TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD item_number.
    DATA number TYPE n LENGTH 6.
    number = value.
    result = number.
  ENDMETHOD.

  METHOD billing_contains_item.
    DATA(order_number) = sales_document.
    DATA(order_item) = sales_document_item.
    LOOP AT context-items INTO DATA(item) WHERE sales_document = order_number.
      IF item_number( item-sales_document_item ) = order_item.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
