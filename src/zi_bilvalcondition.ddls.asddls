@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Condition'
@Metadata.allowExtensions: true
define view entity ZI_BilValCondition
  as select from zbilval_cond
  association to parent ZI_BilValRule as _Rule on $projection.RuleId = _Rule.RuleId
{
  key rule_id       as RuleId,
  key position      as Position,
      scope         as Scope,
      field_name    as FieldName,
      operator      as Operator,
      value_low     as ValueLow,
      value_high    as ValueHigh,
      compare_field as CompareField,
      _Rule
}
