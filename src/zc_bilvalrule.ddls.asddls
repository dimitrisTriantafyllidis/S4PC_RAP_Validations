@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Rule'
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZC_BilValRule
  as projection on ZI_BilValRule
{
  key RuleId,
      ConfigId,
      @Search.defaultSearchElement: true
      Description,
      Checkpoint,
      Outcome,
      Severity,
      BillingType,
      SalesOrganization,
      CompanyCode,
      ItemCategory,
      SoldToParty,
      MessageText,
      ActiveFlag,
      Sequence,
      ApprovalReason,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      _Config     : redirected to parent ZC_BilValConfig,
      _Condition  : redirected to composition child ZC_BilValCondition
}
