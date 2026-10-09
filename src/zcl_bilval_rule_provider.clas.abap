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

    SELECT FROM zbilval_rule
      FIELDS rule_id, config_id, description, checkpoint_id, outcome, severity,
             billing_type, sales_organization, company_code, item_category,
             sold_to_party, message_text, active_flag, sequence, approval_reason,
             local_last_changed_by, local_last_changed_at, last_changed_at
      INTO TABLE @rules_buffer.
    SELECT FROM zbilval_cond
      FIELDS rule_id, position, scope, field_name, operator,
             value_low, value_high, compare_field
      INTO TABLE @conditions_buffer.
    SELECT FROM zbilval_plugin
      FIELDS plugin_id, config_id, description, checkpoint_id, active_flag, sequence,
             approval_reason, local_last_changed_by, local_last_changed_at, last_changed_at
      INTO TABLE @plugins_buffer.
    loaded = abap_true.
  ENDMETHOD.

  METHOD zif_bilval_rule_provider~get_rules.
    load( ).

    LOOP AT rules_buffer INTO DATA(rule)
      WHERE active_flag = abap_true.
      IF rule-checkpoint_id IS NOT INITIAL AND rule-checkpoint_id <> checkpoint.
        CONTINUE.
      ENDIF.

      DATA(runtime_rule) = CORRESPONDING zif_bilval_check=>ty_rule( rule MAPPING checkpoint = checkpoint_id ).
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
      IF plugin-checkpoint_id IS NOT INITIAL AND plugin-checkpoint_id <> checkpoint.
        CONTINUE.
      ENDIF.
      APPEND CORRESPONDING #( plugin MAPPING checkpoint = checkpoint_id ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
