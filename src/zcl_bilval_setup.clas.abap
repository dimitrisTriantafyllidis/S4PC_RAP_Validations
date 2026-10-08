CLASS zcl_bilval_setup DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CONSTANTS config_id TYPE c LENGTH 10 VALUE 'BILVAL'.

    CLASS-METHODS ensure_configuration
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_bilval_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    out->write( ensure_configuration( ) ).
  ENDMETHOD.

  METHOD ensure_configuration.
    GET TIME STAMP FIELD DATA(now).

    SELECT SINGLE config_id
      FROM zbilval_config
      WHERE config_id = @config_id
      INTO @DATA(existing_config).

    IF sy-subrc <> 0.
      INSERT zbilval_config FROM @( VALUE #(
        config_id = config_id
        description = 'Billing document validation'
        local_last_changed_by = sy-uname
        local_last_changed_at = now
        last_changed_at = now ) ).
      result = |Created configuration { config_id }. |.
    ELSE.
      result = |Configuration { config_id } already exists. |.
    ENDIF.

    LOOP AT zcl_bilval_factory=>get_catalog( ) INTO DATA(plugin).
      SELECT SINGLE plugin_id
        FROM zbilval_plugin
        WHERE plugin_id = @plugin-plugin_id
        INTO @DATA(existing_plugin).
      IF sy-subrc = 0.
        result = |{ result }Plug-in { plugin-plugin_id } already exists. |.
        CONTINUE.
      ENDIF.

      INSERT zbilval_plugin FROM @( VALUE #(
        plugin_id = plugin-plugin_id
        config_id = config_id
        description = plugin-description
        active_flag = abap_false
        sequence = 10
        local_last_changed_by = sy-uname
        local_last_changed_at = now
        last_changed_at = now ) ).
      result = |{ result }Plug-in { plugin-plugin_id } created inactive. |.
    ENDLOOP.

    zcl_bilval_rule_provider=>clear_buffer( ).
  ENDMETHOD.

ENDCLASS.
