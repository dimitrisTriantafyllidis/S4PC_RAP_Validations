CLASS zcl_bilval_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS create
      RETURNING VALUE(result) TYPE REF TO zcl_bilval_engine.

    METHODS constructor
      IMPORTING
        provider  TYPE REF TO zif_bilval_rule_provider OPTIONAL
        factory   TYPE REF TO zif_bilval_factory OPTIONAL
        log       TYPE REF TO zif_bilval_log OPTIONAL
        evaluator TYPE REF TO zcl_bilval_config_eval OPTIONAL.

    METHODS validate
      IMPORTING context       TYPE zif_bilval_check=>ty_context
      RETURNING VALUE(result) TYPE zif_bilval_check=>ty_messages.

  PRIVATE SECTION.
    DATA provider  TYPE REF TO zif_bilval_rule_provider.
    DATA factory   TYPE REF TO zif_bilval_factory.
    DATA log       TYPE REF TO zif_bilval_log.
    DATA evaluator TYPE REF TO zcl_bilval_config_eval.

    METHODS header_matches
      IMPORTING
        rule          TYPE zif_bilval_check=>ty_rule
        context       TYPE zif_bilval_check=>ty_context
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS checkpoint_matches
      IMPORTING
        configured    TYPE zif_bilval_check=>ty_checkpoint
        current       TYPE zif_bilval_check=>ty_checkpoint
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS collect_rule_messages
      IMPORTING
        rule          TYPE zif_bilval_check=>ty_rule
        context       TYPE zif_bilval_check=>ty_context
      CHANGING
        messages      TYPE zif_bilval_check=>ty_messages.

    METHODS append_message
      IMPORTING
        rule     TYPE zif_bilval_check=>ty_rule
        item     TYPE zif_bilval_check=>ty_item_number OPTIONAL
      CHANGING
        messages TYPE zif_bilval_check=>ty_messages.

    METHODS item_category_matches
      IMPORTING
        rule          TYPE zif_bilval_check=>ty_rule
        item          TYPE zif_bilval_check=>ty_item
      RETURNING
        VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_bilval_engine IMPLEMENTATION.

  METHOD create.
    result = NEW zcl_bilval_engine(
      provider = NEW zcl_bilval_rule_provider( )
      factory  = NEW zcl_bilval_factory( )
      log      = NEW zcl_bilval_log( ) ).
  ENDMETHOD.

  METHOD constructor.
    me->provider = provider.
    me->factory = factory.
    me->log = log.
    me->evaluator = evaluator.
    IF me->provider IS NOT BOUND.
      me->provider = NEW zcl_bilval_rule_provider( ).
    ENDIF.
    IF me->factory IS NOT BOUND.
      me->factory = NEW zcl_bilval_factory( ).
    ENDIF.
    IF me->evaluator IS NOT BOUND.
      me->evaluator = NEW zcl_bilval_config_eval( ).
    ENDIF.
  ENDMETHOD.

  METHOD validate.
    DATA(rules) = provider->get_rules( context-checkpoint ).
    SORT rules BY sequence rule_id.

    LOOP AT rules INTO DATA(rule).
      IF rule-active_flag <> abap_true
        OR checkpoint_matches( configured = rule-checkpoint current = context-checkpoint ) = abap_false.
        CONTINUE.
      ENDIF.
      IF header_matches( rule = rule context = context ) = abap_false.
        CONTINUE.
      ENDIF.
      IF rule-conditions IS INITIAL.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-warning
          rule_id      = rule-rule_id
          outcome      = zif_bilval_check=>outcome-block
          message_text = |Rule { rule-rule_id } has no conditions and was skipped.| ) TO result.
        CONTINUE.
      ENDIF.
      collect_rule_messages( EXPORTING rule = rule context = context CHANGING messages = result ).
    ENDLOOP.

    DATA(plugins) = provider->get_plugins( context-checkpoint ).
    SORT plugins BY sequence plugin_id.

    LOOP AT plugins INTO DATA(plugin).
      IF plugin-active_flag <> abap_true
        OR checkpoint_matches( configured = plugin-checkpoint current = context-checkpoint ) = abap_false.
        CONTINUE.
      ENDIF.
      DATA(implementation) = factory->create( plugin-plugin_id ).
      IF implementation IS NOT BOUND.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-warning
          plugin_id    = plugin-plugin_id
          outcome      = zif_bilval_check=>outcome-block
          message_text = |Plug-in { plugin-plugin_id } is not registered and was skipped.| ) TO result.
        CONTINUE.
      ENDIF.

      DATA(plugin_messages) = implementation->validate( context ).
      LOOP AT plugin_messages ASSIGNING FIELD-SYMBOL(<plugin_message>).
        IF <plugin_message>-severity IS INITIAL.
          <plugin_message>-severity = zif_bilval_check=>severity-error.
        ENDIF.
        IF <plugin_message>-outcome IS INITIAL.
          <plugin_message>-outcome = zif_bilval_check=>outcome-block.
        ENDIF.
        IF <plugin_message>-plugin_id IS INITIAL.
          <plugin_message>-plugin_id = plugin-plugin_id.
        ENDIF.
        IF <plugin_message>-approval_reason IS INITIAL.
          <plugin_message>-approval_reason = plugin-approval_reason.
        ENDIF.
      ENDLOOP.
      APPEND LINES OF plugin_messages TO result.
    ENDLOOP.

    IF log IS BOUND AND result IS NOT INITIAL.
      log->add_messages( context = context messages = result ).
    ENDIF.
  ENDMETHOD.

  METHOD checkpoint_matches.
    result = zcl_bilval_fields=>checkpoint_applies( configured = configured current = current ).
  ENDMETHOD.

  METHOD header_matches.
    result = xsdbool(
      ( rule-billing_type IS INITIAL OR rule-billing_type = context-header-billing_type )
      AND ( rule-sales_organization IS INITIAL OR rule-sales_organization = context-header-sales_organization )
      AND ( rule-company_code IS INITIAL OR rule-company_code = context-header-company_code )
      AND ( rule-sold_to_party IS INITIAL OR rule-sold_to_party = context-header-sold_to_party ) ).
  ENDMETHOD.

  METHOD item_category_matches.
    result = xsdbool( rule-item_category IS INITIAL OR rule-item_category = item-item_category ).
  ENDMETHOD.

  METHOD collect_rule_messages.
    DATA(has_item_condition) = xsdbool( line_exists( rule-conditions[ scope = zif_bilval_check=>scope-item ] ) ).

    IF has_item_condition = abap_false.
      IF rule-item_category IS NOT INITIAL.
        IF context-has_current_item = abap_true.
          IF item_category_matches( rule = rule item = context-current_item ) = abap_false.
            RETURN.
          ENDIF.
        ELSEIF NOT line_exists( context-items[ item_category = rule-item_category ] ).
          RETURN.
        ENDIF.
      ENDIF.

      IF evaluator->matches(
           EXPORTING rule = rule context = context item = context-current_item
           IMPORTING unknown_field = DATA(unknown) ) = abap_true.
        append_message(
          EXPORTING rule = rule item = COND #( WHEN context-has_current_item = abap_true THEN context-current_item-billing_document_item )
          CHANGING messages = messages ).
      ELSEIF unknown = abap_true.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-warning
          rule_id      = rule-rule_id
          outcome      = zif_bilval_check=>outcome-block
          message_text = |Rule { rule-rule_id } names an unknown field and was skipped.| ) TO messages.
      ENDIF.
      RETURN.
    ENDIF.

    IF context-has_current_item = abap_true.
      IF item_category_matches( rule = rule item = context-current_item ) = abap_false.
        RETURN.
      ENDIF.
      IF evaluator->matches(
           EXPORTING rule = rule context = context item = context-current_item
           IMPORTING unknown_field = unknown ) = abap_true.
        append_message(
          EXPORTING rule = rule item = context-current_item-billing_document_item
          CHANGING messages = messages ).
      ELSEIF unknown = abap_true.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-warning
          rule_id      = rule-rule_id
          outcome      = zif_bilval_check=>outcome-block
          message_text = |Rule { rule-rule_id } names an unknown field and was skipped.| ) TO messages.
      ENDIF.
      RETURN.
    ENDIF.

    LOOP AT context-items INTO DATA(item).
      IF item_category_matches( rule = rule item = item ) = abap_false.
        CONTINUE.
      ENDIF.
      IF evaluator->matches(
           EXPORTING rule = rule context = context item = item
           IMPORTING unknown_field = unknown ) = abap_true.
        append_message(
          EXPORTING rule = rule item = item-billing_document_item
          CHANGING messages = messages ).
      ELSEIF unknown = abap_true.
        APPEND VALUE #(
          severity     = zif_bilval_check=>severity-warning
          rule_id      = rule-rule_id
          item         = item-billing_document_item
          outcome      = zif_bilval_check=>outcome-block
          message_text = |Rule { rule-rule_id } names an unknown field and was skipped.| ) TO messages.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD append_message.
    DATA(text) = CONV string( rule-message_text ).
    IF text IS INITIAL.
      text = |Validation rule { rule-rule_id } failed.|.
    ENDIF.
    APPEND VALUE #(
      severity        = rule-severity
      rule_id         = rule-rule_id
      message_text    = text
      item            = item
      approval_reason = rule-approval_reason
      outcome         = rule-outcome ) TO messages.
  ENDMETHOD.

ENDCLASS.
