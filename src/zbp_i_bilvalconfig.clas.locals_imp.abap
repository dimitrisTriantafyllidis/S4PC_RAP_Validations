CLASS lhc_bilval DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Config RESULT result.

    METHODS normalizeRule FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Rule~normalizeRule.

    METHODS validateRule FOR VALIDATE ON SAVE
      IMPORTING keys FOR Rule~validateRule.

    METHODS normalizeCondition FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Condition~normalizeCondition.

    METHODS validateCondition FOR VALIDATE ON SAVE
      IMPORTING keys FOR Condition~validateCondition.

    METHODS normalizePlugin FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Plugin~normalizePlugin.

    METHODS validatePlugin FOR VALIDATE ON SAVE
      IMPORTING keys FOR Plugin~validatePlugin.
ENDCLASS.

CLASS lhc_bilval IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%update = if_abap_behv=>auth-allowed.
    result-%assoc-_Rule = if_abap_behv=>auth-allowed.
    result-%assoc-_Plugin = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD normalizeRule.
    READ ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Rule
      FIELDS ( Checkpoint Outcome Severity BillingType SalesOrganization CompanyCode ItemCategory SoldToParty ApprovalReason )
      WITH CORRESPONDING #( keys )
      RESULT DATA(rules).

    MODIFY ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Rule
      UPDATE FIELDS ( Checkpoint Outcome Severity BillingType SalesOrganization CompanyCode ItemCategory SoldToParty ApprovalReason )
      WITH VALUE #( FOR rule IN rules (
        %tky = rule-%tky
        Checkpoint = to_upper( rule-Checkpoint )
        Outcome = to_upper( rule-Outcome )
        Severity = to_upper( rule-Severity )
        BillingType = to_upper( rule-BillingType )
        SalesOrganization = to_upper( rule-SalesOrganization )
        CompanyCode = to_upper( rule-CompanyCode )
        ItemCategory = to_upper( rule-ItemCategory )
        SoldToParty = to_upper( rule-SoldToParty )
        ApprovalReason = to_upper( rule-ApprovalReason ) ) ).
  ENDMETHOD.

  METHOD validateRule.
    READ ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Rule
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(rules).

    LOOP AT rules INTO DATA(rule).
      IF rule-Checkpoint IS NOT INITIAL AND zcl_bilval_fields=>is_checkpoint( CONV #( rule-Checkpoint ) ) = abap_false.
        APPEND VALUE #( %tky = rule-%tky
          %element-Checkpoint = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = |Checkpoint { rule-Checkpoint } is not supported.| ) ) TO reported-rule.
        APPEND VALUE #( %tky = rule-%tky ) TO failed-rule.
      ENDIF.

      IF zcl_bilval_fields=>is_outcome( CONV #( rule-Outcome ) ) = abap_false.
        APPEND VALUE #( %tky = rule-%tky
          %element-Outcome = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = |Outcome { rule-Outcome } is not supported.| ) ) TO reported-rule.
        APPEND VALUE #( %tky = rule-%tky ) TO failed-rule.
      ENDIF.

      IF zcl_bilval_fields=>is_severity( CONV #( rule-Severity ) ) = abap_false.
        APPEND VALUE #( %tky = rule-%tky
          %element-Severity = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = 'Severity must be E or W.' ) ) TO reported-rule.
        APPEND VALUE #( %tky = rule-%tky ) TO failed-rule.
      ENDIF.

      IF rule-MessageText IS INITIAL.
        APPEND VALUE #( %tky = rule-%tky
          %element-MessageText = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = 'Message text is required.' ) ) TO reported-rule.
        APPEND VALUE #( %tky = rule-%tky ) TO failed-rule.
      ENDIF.

      IF ( rule-Outcome = zif_bilval_check=>outcome-require_approval OR rule-Checkpoint = zif_bilval_check=>checkpoint-approval )
        AND rule-ApprovalReason IS INITIAL.
        APPEND VALUE #( %tky = rule-%tky
          %element-ApprovalReason = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = 'Approval reason is required for this rule.' ) ) TO reported-rule.
        APPEND VALUE #( %tky = rule-%tky ) TO failed-rule.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD normalizeCondition.
    READ ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Condition
      FIELDS ( Scope FieldName Operator CompareField )
      WITH CORRESPONDING #( keys )
      RESULT DATA(conditions).

    MODIFY ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Condition
      UPDATE FIELDS ( Scope FieldName Operator CompareField )
      WITH VALUE #( FOR condition IN conditions (
        %tky = condition-%tky
        Scope = to_upper( condition-Scope )
        FieldName = to_upper( condition-FieldName )
        Operator = to_upper( condition-Operator )
        CompareField = to_upper( condition-CompareField ) ) ).
  ENDMETHOD.

  METHOD validateCondition.
    READ ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Condition
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(conditions).

    LOOP AT conditions INTO DATA(condition).
      IF zcl_bilval_fields=>is_scope( CONV #( condition-Scope ) ) = abap_false.
        APPEND VALUE #( %tky = condition-%tky
          %element-Scope = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Scope must be H or I.' ) )
          TO reported-condition.
        APPEND VALUE #( %tky = condition-%tky ) TO failed-condition.
      ENDIF.

      IF zcl_bilval_fields=>is_operator( CONV #( condition-Operator ) ) = abap_false.
        APPEND VALUE #( %tky = condition-%tky
          %element-Operator = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = |Operator { condition-Operator } is not supported.| ) )
          TO reported-condition.
        APPEND VALUE #( %tky = condition-%tky ) TO failed-condition.
      ENDIF.

      IF zcl_bilval_fields=>exists( field_name = CONV #( condition-FieldName ) scope = CONV #( condition-Scope ) ) = abap_false.
        APPEND VALUE #( %tky = condition-%tky
          %element-FieldName = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = |Field { condition-FieldName } is not in the catalog for this scope.| ) )
          TO reported-condition.
        APPEND VALUE #( %tky = condition-%tky ) TO failed-condition.
      ENDIF.

      IF condition-Operator = zif_bilval_check=>operator-field_eq
        AND zcl_bilval_fields=>exists( field_name = CONV #( condition-CompareField ) scope = CONV #( condition-Scope ) ) = abap_false.
        APPEND VALUE #( %tky = condition-%tky
          %element-CompareField = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = 'Compare field must be a catalog field in the same scope.' ) )
          TO reported-condition.
        APPEND VALUE #( %tky = condition-%tky ) TO failed-condition.
      ENDIF.

      IF condition-Operator <> zif_bilval_check=>operator-is_initial
        AND condition-Operator <> zif_bilval_check=>operator-is_not_initial
        AND condition-Operator <> zif_bilval_check=>operator-field_eq
        AND condition-ValueLow IS INITIAL.
        APPEND VALUE #( %tky = condition-%tky
          %element-ValueLow = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Comparison value is required.' ) )
          TO reported-condition.
        APPEND VALUE #( %tky = condition-%tky ) TO failed-condition.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD normalizePlugin.
    READ ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Plugin
      FIELDS ( PluginId Checkpoint ApprovalReason )
      WITH CORRESPONDING #( keys )
      RESULT DATA(plugins).

    MODIFY ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Plugin
      UPDATE FIELDS ( Checkpoint ApprovalReason )
      WITH VALUE #( FOR plugin IN plugins (
        %tky = plugin-%tky
        Checkpoint = to_upper( plugin-Checkpoint )
        ApprovalReason = to_upper( plugin-ApprovalReason ) ) ).
  ENDMETHOD.

  METHOD validatePlugin.
    READ ENTITIES OF zi_bilvalconfig IN LOCAL MODE
      ENTITY Plugin
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(plugins).

    LOOP AT plugins INTO DATA(plugin).
      IF zcl_bilval_factory=>is_known( CONV #( plugin-PluginId ) ) = abap_false.
        APPEND VALUE #( %tky = plugin-%tky
          %element-PluginId = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = |Plug-in { plugin-PluginId } is not registered in the factory.| ) )
          TO reported-plugin.
        APPEND VALUE #( %tky = plugin-%tky ) TO failed-plugin.
      ENDIF.

      IF plugin-Checkpoint IS NOT INITIAL AND zcl_bilval_fields=>is_checkpoint( CONV #( plugin-Checkpoint ) ) = abap_false.
        APPEND VALUE #( %tky = plugin-%tky
          %element-Checkpoint = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = |Checkpoint { plugin-Checkpoint } is not supported.| ) )
          TO reported-plugin.
        APPEND VALUE #( %tky = plugin-%tky ) TO failed-plugin.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
