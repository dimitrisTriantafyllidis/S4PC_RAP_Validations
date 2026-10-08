@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Condition'
@Metadata.allowExtensions: true
define view entity ZC_BilValCondition
  as projection on ZI_BilValCondition
{
  key RuleId,
  key Position,
      Scope,
      FieldName,
      Operator,
      ValueLow,
      ValueHigh,
      CompareField,
      _Rule : redirected to parent ZC_BilValRule
}
