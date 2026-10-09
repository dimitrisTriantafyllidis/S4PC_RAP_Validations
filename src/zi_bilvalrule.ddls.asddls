@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Rule'
@Metadata.allowExtensions: true
define view entity ZI_BilValRule
  as select from zbilval_rule
  association to parent ZI_BilValConfig as _Config on $projection.ConfigId = _Config.ConfigId
  composition [0..*] of ZI_BilValCondition as _Condition
{
  key rule_id               as RuleId,
      config_id             as ConfigId,
      description           as Description,
      checkpoint_id         as Checkpoint,
      outcome               as Outcome,
      severity              as Severity,
      billing_type          as BillingType,
      sales_organization    as SalesOrganization,
      company_code          as CompanyCode,
      item_category         as ItemCategory,
      sold_to_party         as SoldToParty,
      message_text          as MessageText,
      active_flag           as ActiveFlag,
      sequence              as Sequence,
      approval_reason       as ApprovalReason,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Config,
      _Condition
}
