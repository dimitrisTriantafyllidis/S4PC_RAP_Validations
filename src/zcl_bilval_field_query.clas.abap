CLASS zcl_bilval_field_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.


CLASS zcl_bilval_field_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA result TYPE STANDARD TABLE OF zi_bilvalfieldvh WITH EMPTY KEY.
    DATA(catalog) = zcl_bilval_fields=>get_catalog( ).

    LOOP AT catalog INTO DATA(field).
      APPEND VALUE #(
        fieldname = field-field_name
        scope = field-scope
        description = field-description ) TO result.
    ENDLOOP.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( result ) ).
    ENDIF.
    IF io_request->is_data_requested( ).
      io_response->set_data( result ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
