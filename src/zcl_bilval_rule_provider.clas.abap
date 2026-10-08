CLASS zcl_bilval_rule_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_bilval_rule_provider.

    CLASS-METHODS clear_buffer.

  PRIVATE SECTION.
    CLASS-DATA loaded            TYPE abap_bool.
    CLASS-DATA rules_buffer      TYPE STANDARD TABLE OF zbilval_rule WITH EMPTY KEY.
    CLASS-DATA conditions_buffer TYPE STANDARD TABLE OF zbilval_cond WITH EMPTY KEY.
    CLASS-DATA plugins_buffer    TYPE STANDARD TABLE OF zbilval_plugin WITH EMPTY KEY.

    CLASS-METHODS load.
ENDCLASS.


CLASS zcl_bilval_rule_provider IMPLEMENTATION.

  METHOD clear_buffer.
    CLEAR: loaded, rules_buffer, conditions_buffer, plugins_buffer.
  ENDMETHOD.

  METHOD load.
    IF loaded = abap_true.
      RETURN.
    ENDIF.

    SELECT * FROM zbilval_rule INTO TABLE @rules_buffer.
    SELECT * FROM zbilval_cond INTO TABLE @conditions_buffer.
    SELECT * FROM zbilval_plugin INTO TABLE @plugins_buffer.
    loaded = abap_true.
  ENDMETHOD.

  METHOD zif_bilval_rule_provider~get_rules.
    load( ).

    LOOP AT rules_buffer INTO DATA(rule)
      WHERE active_flag = abap_true.
      IF rule-checkpoint IS NOT INITIAL AND rule-checkpoint <> checkpoint.
        CONTINUE.
      ENDIF.

      DATA(runtime_rule) = CORRESPONDING zif_bilval_check=>ty_rule( rule ).
      LOOP AT conditions_buffer INTO DATA(condition) WHERE rule_id = rule-rule_id.
        APPEND CORRESPONDING #( condition ) TO runtime_rule-conditions.
      ENDLOOP.
      SORT runtime_rule-conditions BY position.
      APPEND runtime_rule TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_bilval_rule_provider~get_plugins.
    load( ).

    LOOP AT plugins_buffer INTO DATA(plugin) WHERE active_flag = abap_true.
      IF plugin-checkpoint IS NOT INITIAL AND plugin-checkpoint <> checkpoint.
        CONTINUE.
      ENDIF.
      APPEND CORRESPONDING #( plugin ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
