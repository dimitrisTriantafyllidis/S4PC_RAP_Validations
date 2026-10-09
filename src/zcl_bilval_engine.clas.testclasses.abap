CLASS lcl_provider DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_rule_provider.
    DATA rules   TYPE zif_bilval_check=>ty_rules.
    DATA plugins TYPE zif_bilval_check=>ty_plugin_cfgs.
ENDCLASS.

CLASS lcl_provider IMPLEMENTATION.
  METHOD zif_bilval_rule_provider~get_rules.
    result = rules.
  ENDMETHOD.

  METHOD zif_bilval_rule_provider~get_plugins.
    result = plugins.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_marker DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_check.
    DATA marker TYPE string.
ENDCLASS.

CLASS lcl_marker IMPLEMENTATION.
  METHOD zif_bilval_check~validate.
    APPEND VALUE #(
      severity     = zif_bilval_check=>severity-warning
      plugin_id    = marker
      outcome      = zif_bilval_check=>outcome-block
      message_text = marker ) TO result.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_factory DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_factory.
    TYPES:
      BEGIN OF ty_entry,
        plugin_id TYPE zif_bilval_check=>ty_plugin_id,
        plugin    TYPE REF TO lcl_marker,
      END OF ty_entry.
    DATA entries TYPE HASHED TABLE OF ty_entry WITH UNIQUE KEY plugin_id.
ENDCLASS.

CLASS lcl_factory IMPLEMENTATION.
  METHOD zif_bilval_factory~create.
    ASSIGN entries[ plugin_id = plugin_id ] TO FIELD-SYMBOL(<entry>).
    IF sy-subrc = 0.
      result = <entry>-plugin.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_reader DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_preceding_reader.
    DATA items  TYPE zif_bilval_preceding_reader=>ty_items.
    DATA failed TYPE abap_bool.
ENDCLASS.

CLASS lcl_reader IMPLEMENTATION.
  METHOD zif_bilval_preceding_reader~read_sales_order_items.
    failed = me->failed.
    result = items.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_lookup DEFINITION.
  PUBLIC SECTION.
    INTERFACES zif_bilval_md_lookup.
    DATA customer TYPE zif_bilval_check=>ty_checkpoint.
    DATA product  TYPE zif_bilval_check=>ty_checkpoint.
ENDCLASS.

CLASS lcl_lookup IMPLEMENTATION.
  METHOD zif_bilval_md_lookup~customer_checkpoint.
    result = customer.
  ENDMETHOD.

  METHOD zif_bilval_md_lookup~product_checkpoint.
    result = product.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_bilval_engine DEFINITION
  FINAL
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS equal_matches FOR TESTING.
    METHODS equal_miss_does_not_block FOR TESTING.
    METHODS not_equal FOR TESTING.
    METHODS initial_and_not_initial FOR TESTING.
    METHODS numeric_greater_than FOR TESTING.
    METHODS between_is_inclusive FOR TESTING.
    METHODS in_list FOR TESTING.
    METHODS field_compared_with_field FOR TESTING.
    METHODS and_requires_every_condition FOR TESTING.
    METHODS billing_type_filter_skips FOR TESTING.
    METHODS empty_filter_matches FOR TESTING.
    METHODS warning_does_not_block FOR TESTING.
    METHODS unknown_field_does_not_block FOR TESTING.
    METHODS rules_run_in_sequence FOR TESTING.
    METHODS plugin_order FOR TESTING.
    METHODS inactive_plugin_skipped FOR TESTING.
    METHODS item_category_filter FOR TESTING.
    METHODS header_rule_without_item FOR TESTING.
    METHODS zero_price_plugin FOR TESTING.
    METHODS preceding_complete_document FOR TESTING.
    METHODS preceding_current_item_only FOR TESTING.
    METHODS mapper_reads_billing_type FOR TESTING.
    METHODS transfer_rejects_matching_item FOR TESTING.
    METHODS pbd_checkpoint_mapping FOR TESTING.
    METHODS customer_save_blocks_wrong_group FOR TESTING.
    METHODS customer_add_rule_skips_on_change FOR TESTING.
    METHODS billing_rule_skips_customer_save FOR TESTING.
    METHODS material_save_requires_profit_center FOR TESTING.

    METHODS run
      IMPORTING
        rules         TYPE zif_bilval_check=>ty_rules OPTIONAL
        plugins       TYPE zif_bilval_check=>ty_plugin_cfgs OPTIONAL
        context       TYPE zif_bilval_check=>ty_context
        factory       TYPE REF TO zif_bilval_factory OPTIONAL
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_messages.

    METHODS header_rule
      IMPORTING
        operator      TYPE zif_bilval_check=>ty_operator
        field_name    TYPE zif_bilval_check=>ty_field_name DEFAULT 'BILLINGTYPE'
        value_low     TYPE c LENGTH 80 OPTIONAL
        value_high    TYPE c LENGTH 80 OPTIONAL
        compare_field TYPE zif_bilval_check=>ty_field_name OPTIONAL
        severity      TYPE zif_bilval_check=>ty_severity DEFAULT zif_bilval_check=>severity-error
        sequence      TYPE i DEFAULT 1
        billing_type  TYPE c LENGTH 4 OPTIONAL
        item_category TYPE c LENGTH 4 OPTIONAL
        scope         TYPE zif_bilval_check=>ty_scope DEFAULT zif_bilval_check=>scope-header
        checkpoint    TYPE zif_bilval_check=>ty_checkpoint DEFAULT zif_bilval_check=>checkpoint-create
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_rule.

    METHODS billing_context
      IMPORTING
        billing_type  TYPE c LENGTH 4 DEFAULT 'F2'
        net_amount    TYPE zif_bilval_check=>ty_amount DEFAULT 0
        sold_to_party TYPE c LENGTH 10 OPTIONAL
      RETURNING
        VALUE(result) TYPE zif_bilval_check=>ty_context.
ENDCLASS.


CLASS ltc_bilval_engine IMPLEMENTATION.

  METHOD equal_matches.
    DATA(context) = billing_context( 'F2' ).
    DATA(messages) = run( rules = VALUE #( ( header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' ) ) )
                          context = context ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-severity exp = zif_bilval_check=>severity-error ).
  ENDMETHOD.

  METHOD equal_miss_does_not_block.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' ) ) )
      context = billing_context( 'G2' ) ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.

  METHOD not_equal.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule( operator = zif_bilval_check=>operator-ne value_low = 'F2' ) ) )
      context = billing_context( 'G2' ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
  ENDMETHOD.

  METHOD initial_and_not_initial.
    DATA(empty_party) = run(
      rules = VALUE #( ( header_rule( field_name = 'SOLDTOPARTY' operator = zif_bilval_check=>operator-is_initial ) ) )
      context = billing_context( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( empty_party ) exp = 1 ).

    DATA(filled) = billing_context( ).
    filled-header-sold_to_party = '1000001'.
    DATA(not_initial) = run(
      rules = VALUE #( ( header_rule( field_name = 'SOLDTOPARTY' operator = zif_bilval_check=>operator-is_not_initial ) ) )
      context = filled ).
    cl_abap_unit_assert=>assert_equals( act = lines( not_initial ) exp = 1 ).
  ENDMETHOD.

  METHOD numeric_greater_than.
    DATA(context) = billing_context( ).
    context-header-net_amount = 10.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule( field_name = 'NETAMOUNT' operator = zif_bilval_check=>operator-gt value_low = '9' ) ) )
      context = context ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
  ENDMETHOD.

  METHOD between_is_inclusive.
    DATA(context) = billing_context( ).
    context-header-net_amount = 10.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule(
        field_name = 'NETAMOUNT'
        operator = zif_bilval_check=>operator-between
        value_low = '1'
        value_high = '10' ) ) )
      context = context ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
  ENDMETHOD.

  METHOD in_list.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule( operator = zif_bilval_check=>operator-in_list value_low = 'F2, G2' ) ) )
      context = billing_context( 'G2' ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).

    DATA(miss) = run(
      rules = VALUE #( ( header_rule( operator = zif_bilval_check=>operator-in_list value_low = 'F2, G2' ) ) )
      context = billing_context( 'L2' ) ).
    cl_abap_unit_assert=>assert_initial( miss ).
  ENDMETHOD.

  METHOD field_compared_with_field.
    DATA(context) = billing_context( ).
    context-has_current_item = abap_true.
    context-current_item-sales_document = '0000001234'.
    context-current_item-reference_document = '0000001234'.
    DATA(rule) = header_rule(
      field_name = 'SALESDOCUMENT'
      operator = zif_bilval_check=>operator-field_eq
      compare_field = 'REFERENCEDOCUMENT'
      scope = zif_bilval_check=>scope-item ).
    DATA(messages) = run( rules = VALUE #( ( rule ) ) context = context ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
  ENDMETHOD.

  METHOD and_requires_every_condition.
    DATA(rule) = header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' ).
    APPEND VALUE #(
      position = '002'
      scope = zif_bilval_check=>scope-header
      field_name = 'SOLDTOPARTY'
      operator = zif_bilval_check=>operator-eq
      value_low = '1000001' ) TO rule-conditions.
    DATA(messages) = run( rules = VALUE #( ( rule ) ) context = billing_context( 'F2' ) ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.

  METHOD billing_type_filter_skips.
    DATA(rule) = header_rule( operator = zif_bilval_check=>operator-is_not_initial field_name = 'BILLINGTYPE' ).
    rule-billing_type = 'G2'.
    DATA(messages) = run( rules = VALUE #( ( rule ) ) context = billing_context( 'F2' ) ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.

  METHOD empty_filter_matches.
    DATA(rule) = header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' ).
    CLEAR: rule-billing_type, rule-sales_organization, rule-company_code, rule-sold_to_party.
    DATA(messages) = run( rules = VALUE #( ( rule ) ) context = billing_context( 'F2' ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
  ENDMETHOD.

  METHOD warning_does_not_block.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule(
        operator = zif_bilval_check=>operator-eq
        value_low = 'F2'
        severity = zif_bilval_check=>severity-warning ) ) )
      context = billing_context( 'F2' ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-severity exp = zif_bilval_check=>severity-warning ).
    cl_abap_unit_assert=>assert_false( act = zcl_bilval_outcome=>has_block( messages ) ).
  ENDMETHOD.

  METHOD unknown_field_does_not_block.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule( field_name = 'NOT_A_FIELD' operator = zif_bilval_check=>operator-eq value_low = 'X' ) ) )
      context = billing_context( ) ).
    LOOP AT messages INTO DATA(message) WHERE severity = zif_bilval_check=>severity-error.
      cl_abap_unit_assert=>fail( msg = 'An unknown field blocked billing' ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-severity exp = zif_bilval_check=>severity-warning ).
  ENDMETHOD.

  METHOD rules_run_in_sequence.
    DATA(second) = header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' sequence = 20 ).
    second-rule_id = 'R2'.
    second-message_text = 'Second'.
    DATA(first) = header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' sequence = 10 ).
    first-rule_id = 'R1'.
    first-message_text = 'First'.
    DATA(messages) = run( rules = VALUE #( ( second ) ( first ) ) context = billing_context( 'F2' ) ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-message_text exp = 'First' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 2 ]-message_text exp = 'Second' ).
  ENDMETHOD.

  METHOD plugin_order.
    DATA(factory) = NEW lcl_factory( ).
    DATA(early) = NEW lcl_marker( ).
    early->marker = 'A'.
    DATA(late) = NEW lcl_marker( ).
    late->marker = 'B'.
    factory->entries = VALUE #(
      ( plugin_id = 'LATE' plugin = late )
      ( plugin_id = 'EARLY' plugin = early ) ).
    DATA(messages) = run(
      plugins = VALUE #(
        ( plugin_id = 'LATE' active_flag = abap_true sequence = 20 )
        ( plugin_id = 'EARLY' active_flag = abap_true sequence = 10 ) )
      context = billing_context( )
      factory = factory ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-message_text exp = 'A' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 2 ]-message_text exp = 'B' ).
  ENDMETHOD.

  METHOD inactive_plugin_skipped.
    DATA(factory) = NEW lcl_factory( ).
    DATA(marker) = NEW lcl_marker( ).
    marker->marker = 'OFF'.
    INSERT VALUE #( plugin_id = 'OFF' plugin = marker ) INTO TABLE factory->entries.
    DATA(messages) = run(
      plugins = VALUE #( ( plugin_id = 'OFF' active_flag = abap_false sequence = 1 ) )
      context = billing_context( )
      factory = factory ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.

  METHOD item_category_filter.
    DATA(rule) = header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' item_category = 'TAN' ).
    DATA(context) = billing_context( 'F2' ).
    context-has_current_item = abap_true.
    context-current_item-item_category = 'TAD'.
    cl_abap_unit_assert=>assert_initial( run( rules = VALUE #( ( rule ) ) context = context ) ).

    context-current_item-item_category = 'TAN'.
    cl_abap_unit_assert=>assert_equals(
      act = lines( run( rules = VALUE #( ( rule ) ) context = context ) )
      exp = 1 ).
  ENDMETHOD.

  METHOD header_rule_without_item.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' ) ) )
      context = billing_context( 'F2' ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_initial( messages[ 1 ]-item ).
  ENDMETHOD.

  METHOD zero_price_plugin.
    DATA(context) = billing_context( ).
    context-has_current_item = abap_true.
    context-current_item-billing_document_item = '000010'.
    context-current_item-net_amount = 0.
    DATA(messages) = run(
      plugins = VALUE #( ( plugin_id = zcl_bilval_factory=>plugin-zero_price active_flag = abap_true sequence = 1 ) )
      context = context
      factory = NEW zcl_bilval_factory( ) ).
    cl_abap_unit_assert=>assert_true( act = zcl_bilval_outcome=>has_block( messages ) ).

    context-current_item-net_amount = 5.
    cl_abap_unit_assert=>assert_initial( run(
      plugins = VALUE #( ( plugin_id = zcl_bilval_factory=>plugin-zero_price active_flag = abap_true sequence = 1 ) )
      context = context
      factory = NEW zcl_bilval_factory( ) ) ).
  ENDMETHOD.

  METHOD preceding_complete_document.
    DATA(reader) = NEW lcl_reader( ).
    reader->items = VALUE #(
      ( sales_document = '0000001234' sales_document_item = '000010' )
      ( sales_document = '0000001234' sales_document_item = '000020' ) ).
    DATA(plugin) = NEW zcl_bilval_plg_preceding( reader = reader ).
    DATA(context) = VALUE zif_bilval_check=>ty_context(
      checkpoint = zif_bilval_check=>checkpoint-pbd_final
      complete_document = abap_true
      items = VALUE #( ( sales_document = '0000001234' sales_document_item = '10' ) ) ).
    DATA(messages) = plugin->zif_bilval_check~validate( context ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    IF messages[ 1 ]-message_text NS '000020'.
      cl_abap_unit_assert=>fail( msg = 'Missing item 000020 was not reported' ).
    ENDIF.
  ENDMETHOD.

  METHOD preceding_current_item_only.
    DATA(reader) = NEW lcl_reader( ).
    reader->items = VALUE #( ( sales_document = '0000001234' sales_document_item = '000010' ) ).
    DATA(plugin) = NEW zcl_bilval_plg_preceding( reader = reader ).
    DATA(context) = VALUE zif_bilval_check=>ty_context(
      has_current_item = abap_true
      current_item = VALUE #( sales_document = '0000001234' sales_document_item = '10' billing_document_item = '000010' ) ).
    cl_abap_unit_assert=>assert_initial( plugin->zif_bilval_check~validate( context ) ).

    context-current_item-sales_document_item = '30'.
    DATA(messages) = plugin->zif_bilval_check~validate( context ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
  ENDMETHOD.

  METHOD mapper_reads_billing_type.
    TYPES: BEGIN OF ty_header,
             billingdocumenttype TYPE c LENGTH 4,
             soldtoparty         TYPE c LENGTH 10,
             totalnetamount      TYPE p LENGTH 15 DECIMALS 2,
           END OF ty_header.
    DATA(header) = VALUE ty_header( billingdocumenttype = 'f2' soldtoparty = '1000001' ).
    header-totalnetamount = '15.5'.
    DATA(context) = NEW zcl_bilval_context_mapper( )->map(
      checkpoint = zif_bilval_check=>checkpoint-create
      header = header ).
    DATA expected_amount TYPE p LENGTH 15 DECIMALS 2.
    expected_amount = '15.5'.
    cl_abap_unit_assert=>assert_equals( act = context-header-billing_type exp = 'F2' ).
    cl_abap_unit_assert=>assert_equals( act = context-header-sold_to_party exp = '1000001' ).
    cl_abap_unit_assert=>assert_equals( act = context-header-net_amount exp = expected_amount ).
  ENDMETHOD.

  METHOD transfer_rejects_matching_item.
    DATA(provider) = NEW lcl_provider( ).
    provider->rules = VALUE #( ( header_rule( operator = zif_bilval_check=>operator-eq value_low = 'F2' ) ) ).
    DATA(engine) = NEW zcl_bilval_engine( provider = provider ).
    DATA(adapter) = NEW zcl_bilval_badi_transfer( engine = engine ).
    TYPES:
      BEGIN OF ty_header,
        billingdocumenttype TYPE c LENGTH 4,
      END OF ty_header,
      BEGIN OF ty_item,
        billingdocumentitem TYPE c LENGTH 6,
      END OF ty_item.
    DATA(header) = VALUE ty_header( billingdocumenttype = 'F2' ).
    DATA(item) = VALUE ty_item( billingdocumentitem = '000010' ).
    adapter->apply(
      EXPORTING header = header item = item
      IMPORTING rejected = DATA(rejected) reason = DATA(reason) ).
    cl_abap_unit_assert=>assert_true( act = rejected ).
    cl_abap_unit_assert=>assert_not_initial( reason ).
  ENDMETHOD.

  METHOD pbd_checkpoint_mapping.
    DATA(adapter) = NEW zcl_bilval_badi_pbd( ).
    cl_abap_unit_assert=>assert_equals(
      act = adapter->checkpoint_for( 'AUTO_FINALIZE' )
      exp = zif_bilval_check=>checkpoint-pbd_auto ).
    cl_abap_unit_assert=>assert_equals(
      act = adapter->checkpoint_for( 'CREATE_BILLING' )
      exp = zif_bilval_check=>checkpoint-pbd_create ).
    cl_abap_unit_assert=>assert_equals(
      act = adapter->checkpoint_for( 'FINALIZE' )
      exp = zif_bilval_check=>checkpoint-pbd_final ).
  ENDMETHOD.

  METHOD customer_save_blocks_wrong_group.
    DATA(provider) = NEW lcl_provider( ).
    provider->rules = VALUE #( (
      rule_id = 'R-CUST'
      checkpoint = zif_bilval_check=>checkpoint-customer
      outcome = zif_bilval_check=>outcome-block
      severity = zif_bilval_check=>severity-error
      message_text = 'Domestic customers need account assignment group 01.'
      active_flag = abap_true
      sequence = 10
      conditions = VALUE #(
        ( position = '001' scope = zif_bilval_check=>scope-item field_name = 'RECORDTYPE'
          operator = zif_bilval_check=>operator-eq value_low = 'SALES' )
        ( position = '002' scope = zif_bilval_check=>scope-item field_name = 'SALESORGANIZATION'
          operator = zif_bilval_check=>operator-eq value_low = '1010' )
        ( position = '003' scope = zif_bilval_check=>scope-item field_name = 'CUSTOMERACCOUNTASSIGNMENTGROUP'
          operator = zif_bilval_check=>operator-ne value_low = '01' ) ) ) ).
    DATA(lookup) = NEW lcl_lookup( ).
    lookup->customer = zif_bilval_check=>checkpoint-cust_add.
    DATA(checker) = NEW zcl_bilval_md_customer(
      engine = NEW zcl_bilval_engine( provider = provider )
      lookup = lookup ).

    TYPES:
      BEGIN OF ty_key,
        businesspartner TYPE c LENGTH 10,
      END OF ty_key,
      BEGIN OF ty_general,
        businesspartner     TYPE c LENGTH 10,
        organizationbpname1 TYPE c LENGTH 40,
        country             TYPE c LENGTH 3,
      END OF ty_general,
      BEGIN OF ty_sales,
        salesorganization              TYPE c LENGTH 4,
        distributionchannel            TYPE c LENGTH 2,
        division                       TYPE c LENGTH 2,
        customeraccountassignmentgroup TYPE c LENGTH 2,
      END OF ty_sales,
      BEGIN OF ty_msg,
        msgty TYPE c LENGTH 1,
        msgid TYPE c LENGTH 20,
        msgno TYPE c LENGTH 3,
        msgv1 TYPE c LENGTH 50,
      END OF ty_msg.
    DATA general TYPE STANDARD TABLE OF ty_general WITH EMPTY KEY.
    DATA sales TYPE STANDARD TABLE OF ty_sales WITH EMPTY KEY.
    DATA messages TYPE STANDARD TABLE OF ty_msg WITH EMPTY KEY.
    DATA(key) = VALUE ty_key( businesspartner = '10100009' ).
    general = VALUE #( ( businesspartner = '10100009' organizationbpname1 = 'Domestic Test' country = 'DE' ) ).
    sales = VALUE #( ( salesorganization = '1010' distributionchannel = '10' division = '00'
      customeraccountassignmentgroup = '02' ) ).

    checker->validate_customer(
      EXPORTING partner_key = key general = general sales = sales
      CHANGING validation_messages = messages ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-msgty exp = 'E' ).

    CLEAR messages.
    sales[ 1 ]-customeraccountassignmentgroup = '01'.
    checker->validate_customer(
      EXPORTING partner_key = key general = general sales = sales
      CHANGING validation_messages = messages ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.

  METHOD customer_add_rule_skips_on_change.
    DATA(provider) = NEW lcl_provider( ).
    provider->rules = VALUE #( ( header_rule(
      field_name = 'COUNTRY'
      operator = zif_bilval_check=>operator-is_initial
      checkpoint = zif_bilval_check=>checkpoint-cust_add ) ) ).
    DATA(lookup) = NEW lcl_lookup( ).
    lookup->customer = zif_bilval_check=>checkpoint-cust_upd.
    DATA(checker) = NEW zcl_bilval_md_customer(
      engine = NEW zcl_bilval_engine( provider = provider )
      lookup = lookup ).

    TYPES:
      BEGIN OF ty_general,
        businesspartner TYPE c LENGTH 10,
        country         TYPE c LENGTH 3,
      END OF ty_general,
      BEGIN OF ty_msg,
        msgty TYPE c LENGTH 1,
        msgv1 TYPE c LENGTH 50,
      END OF ty_msg.
    DATA general TYPE STANDARD TABLE OF ty_general WITH EMPTY KEY.
    DATA messages TYPE STANDARD TABLE OF ty_msg WITH EMPTY KEY.
    general = VALUE #( ( businesspartner = '10100001' country = '' ) ).
    checker->validate_customer(
      EXPORTING general = general
      CHANGING validation_messages = messages ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.

  METHOD billing_rule_skips_customer_save.
    DATA(context) = billing_context( sold_to_party = '10100001' ).
    context-checkpoint = zif_bilval_check=>checkpoint-cust_add.
    DATA(messages) = run(
      rules = VALUE #( ( header_rule(
        field_name = 'SOLDTOPARTY'
        operator = zif_bilval_check=>operator-eq
        value_low = '10100001' ) ) )
      context = context ).
    cl_abap_unit_assert=>assert_initial( messages ).

    DATA(open_rule) = header_rule(
      field_name = 'SOLDTOPARTY'
      operator = zif_bilval_check=>operator-eq
      value_low = '10100001' ).
    CLEAR open_rule-checkpoint.
    cl_abap_unit_assert=>assert_initial( run( rules = VALUE #( ( open_rule ) ) context = context ) ).
  ENDMETHOD.

  METHOD material_save_requires_profit_center.
    DATA(provider) = NEW lcl_provider( ).
    provider->rules = VALUE #( (
      rule_id = 'R-MAT'
      checkpoint = zif_bilval_check=>checkpoint-material
      outcome = zif_bilval_check=>outcome-block
      severity = zif_bilval_check=>severity-error
      message_text = 'Plant 1010 needs a profit center.'
      active_flag = abap_true
      sequence = 10
      conditions = VALUE #(
        ( position = '001' scope = zif_bilval_check=>scope-item field_name = 'PLANT'
          operator = zif_bilval_check=>operator-eq value_low = '1010' )
        ( position = '002' scope = zif_bilval_check=>scope-item field_name = 'PROFITCENTER'
          operator = zif_bilval_check=>operator-is_initial ) ) ) ).
    DATA(lookup) = NEW lcl_lookup( ).
    lookup->product = zif_bilval_check=>checkpoint-mat_add.
    DATA(checker) = NEW zcl_bilval_md_product(
      engine = NEW zcl_bilval_engine( provider = provider )
      lookup = lookup ).

    TYPES:
      BEGIN OF ty_plant,
        plant        TYPE c LENGTH 4,
        profitcenter TYPE c LENGTH 10,
      END OF ty_plant,
      BEGIN OF ty_product,
        product      TYPE c LENGTH 40,
        producttype  TYPE c LENGTH 4,
        productgroup TYPE c LENGTH 9,
      END OF ty_product,
      BEGIN OF ty_data,
        product      TYPE ty_product,
        productplant TYPE STANDARD TABLE OF ty_plant WITH EMPTY KEY,
      END OF ty_data,
      BEGIN OF ty_msg,
        msgty   TYPE c LENGTH 1,
        msgv1   TYPE c LENGTH 50,
        product TYPE c LENGTH 40,
      END OF ty_msg.
    DATA payload TYPE STANDARD TABLE OF ty_data WITH EMPTY KEY.
    DATA messages TYPE STANDARD TABLE OF ty_msg WITH EMPTY KEY.
    payload = VALUE #( ( product = VALUE #( product = 'TG-BILVAL' producttype = 'HAWA' productgroup = 'L001' )
      productplant = VALUE #( ( plant = '1010' profitcenter = '' ) ) ) ).

    checker->validate_product( EXPORTING data = payload CHANGING messages = messages ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-product exp = 'TG-BILVAL' ).

    CLEAR messages.
    payload[ 1 ]-productplant[ 1 ]-profitcenter = 'YB600'.
    checker->validate_product( EXPORTING data = payload CHANGING messages = messages ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.

  METHOD run.
    DATA(provider) = NEW lcl_provider( ).
    provider->rules = rules.
    provider->plugins = plugins.
    DATA(engine) = NEW zcl_bilval_engine( provider = provider factory = factory ).
    result = engine->validate( context ).
  ENDMETHOD.

  METHOD header_rule.
    result = VALUE #(
      rule_id = 'R1'
      checkpoint = checkpoint
      outcome = zif_bilval_check=>outcome-block
      severity = severity
      billing_type = billing_type
      item_category = item_category
      message_text = 'Rule failed'
      active_flag = abap_true
      sequence = sequence
      conditions = VALUE #( ( position = '001' scope = scope field_name = field_name operator = operator
        value_low = value_low value_high = value_high compare_field = compare_field ) ) ).
  ENDMETHOD.

  METHOD billing_context.
    result = VALUE #(
      checkpoint = zif_bilval_check=>checkpoint-create
      header = VALUE #(
        billing_type = billing_type
        net_amount = net_amount
        sold_to_party = sold_to_party ) ).
  ENDMETHOD.

ENDCLASS.
