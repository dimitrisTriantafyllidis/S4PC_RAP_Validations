CLASS zcl_bilval_config_eval DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS matches
      IMPORTING
        rule          TYPE zif_bilval_check=>ty_rule
        context       TYPE zif_bilval_check=>ty_context
        item          TYPE zif_bilval_check=>ty_item OPTIONAL
      EXPORTING
        unknown_field TYPE abap_bool
      RETURNING
        VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    METHODS condition_matches
      IMPORTING
        condition      TYPE zif_bilval_check=>ty_condition
        context        TYPE zif_bilval_check=>ty_context
        item           TYPE zif_bilval_check=>ty_item
      EXPORTING
        unknown_field  TYPE abap_bool
      RETURNING
        VALUE(result)  TYPE abap_bool.

    METHODS values_equal
      IMPORTING
        left          TYPE string
        right         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS compare
      IMPORTING
        left          TYPE string
        right         TYPE string
      RETURNING
        VALUE(result) TYPE i.

    METHODS is_initial_value
      IMPORTING
        value         TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS as_number
      IMPORTING
        value         TYPE string
      EXPORTING
        number        TYPE decfloat34
        numeric       TYPE abap_bool.
ENDCLASS.


CLASS zcl_bilval_config_eval IMPLEMENTATION.

  METHOD matches.
    unknown_field = abap_false.
    result = abap_true.

    LOOP AT rule-conditions INTO DATA(condition).
      IF condition_matches(
           EXPORTING condition = condition context = context item = item
           IMPORTING unknown_field = DATA(unknown) ) = abap_false.
        IF unknown = abap_true.
          unknown_field = abap_true.
        ENDIF.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD condition_matches.
    unknown_field = abap_false.
    DATA(left) = zcl_bilval_fields=>get_value(
      EXPORTING
        context    = context
        field_name = condition-field_name
        scope      = condition-scope
        item       = item
      IMPORTING
        unknown    = unknown_field ).

    IF unknown_field = abap_true.
      result = abap_false.
      RETURN.
    ENDIF.

    DATA(operator) = CONV zif_bilval_check=>ty_operator( to_upper( condition-operator ) ).
    DATA(low) = CONV string( condition-value_low ).
    DATA(high) = CONV string( condition-value_high ).

    CASE operator.
      WHEN zif_bilval_check=>operator-is_initial.
        result = is_initial_value( left ).
      WHEN zif_bilval_check=>operator-is_not_initial.
        result = xsdbool( is_initial_value( left ) = abap_false ).
      WHEN zif_bilval_check=>operator-eq.
        result = values_equal( left = left right = low ).
      WHEN zif_bilval_check=>operator-ne.
        result = xsdbool( values_equal( left = left right = low ) = abap_false ).
      WHEN zif_bilval_check=>operator-gt.
        result = xsdbool( compare( left = left right = low ) > 0 ).
      WHEN zif_bilval_check=>operator-lt.
        result = xsdbool( compare( left = left right = low ) < 0 ).
      WHEN zif_bilval_check=>operator-ge.
        result = xsdbool( compare( left = left right = low ) >= 0 ).
      WHEN zif_bilval_check=>operator-le.
        result = xsdbool( compare( left = left right = low ) <= 0 ).
      WHEN zif_bilval_check=>operator-between.
        result = xsdbool( compare( left = left right = low ) >= 0
                     AND compare( left = left right = high ) <= 0 ).
      WHEN zif_bilval_check=>operator-in_list.
        result = abap_false.
        SPLIT low AT ',' INTO TABLE DATA(tokens).
        LOOP AT tokens INTO DATA(token).
          IF values_equal( left = left right = condense( token ) ) = abap_true.
            result = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.
      WHEN zif_bilval_check=>operator-field_eq.
        DATA(other) = zcl_bilval_fields=>get_value(
          EXPORTING
            context    = context
            field_name = condition-compare_field
            scope      = condition-scope
            item       = item
          IMPORTING
            unknown    = DATA(other_unknown) ).
        IF other_unknown = abap_true.
          unknown_field = abap_true.
          result = abap_false.
          RETURN.
        ENDIF.
        result = values_equal( left = left right = other ).
      WHEN OTHERS.
        unknown_field = abap_true.
        result = abap_false.
    ENDCASE.
  ENDMETHOD.

  METHOD values_equal.
    result = xsdbool( compare( left = left right = right ) = 0 ).
  ENDMETHOD.

  METHOD compare.
    as_number( EXPORTING value = left  IMPORTING number = DATA(left_number)  numeric = DATA(left_numeric) ).
    as_number( EXPORTING value = right IMPORTING number = DATA(right_number) numeric = DATA(right_numeric) ).

    IF left_numeric = abap_true AND right_numeric = abap_true.
      IF left_number > right_number.
        result = 1.
      ELSEIF left_number < right_number.
        result = -1.
      ELSE.
        result = 0.
      ENDIF.
      RETURN.
    ENDIF.

    DATA(left_text) = to_upper( condense( left ) ).
    DATA(right_text) = to_upper( condense( right ) ).
    IF left_text > right_text.
      result = 1.
    ELSEIF left_text < right_text.
      result = -1.
    ELSE.
      result = 0.
    ENDIF.
  ENDMETHOD.

  METHOD is_initial_value.
    IF condense( value ) IS INITIAL.
      result = abap_true.
      RETURN.
    ENDIF.
    as_number( EXPORTING value = value IMPORTING number = DATA(number) numeric = DATA(numeric) ).
    result = xsdbool( numeric = abap_true AND number = 0 ).
  ENDMETHOD.

  METHOD as_number.
    DATA(text) = condense( value ).
    IF text IS INITIAL.
      numeric = abap_false.
      RETURN.
    ENDIF.
    TRY.
        number = text.
        numeric = abap_true.
      CATCH cx_sy_conversion_error.
        numeric = abap_false.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
