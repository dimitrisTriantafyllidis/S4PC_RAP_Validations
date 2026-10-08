CLASS zcl_bilval_plugin_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.


CLASS zcl_bilval_plugin_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA result TYPE STANDARD TABLE OF zi_bilvalpluginvh WITH EMPTY KEY.

    LOOP AT zcl_bilval_factory=>get_catalog( ) INTO DATA(plugin).
      APPEND VALUE #(
        pluginid = plugin-plugin_id
        description = plugin-description ) TO result.
    ENDLOOP.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( result ) ).
    ENDIF.
    IF io_request->is_data_requested( ).
      io_response->set_data( result ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
