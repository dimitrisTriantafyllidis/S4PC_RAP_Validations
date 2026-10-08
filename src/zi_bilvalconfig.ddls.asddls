@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Configuration'
@Metadata.allowExtensions: true
define root view entity ZI_BilValConfig
  as select from zbilval_config
  composition [0..*] of ZI_BilValRule   as _Rule
  composition [0..*] of ZI_BilValPlugin as _Plugin
{
  key config_id             as ConfigId,
      description           as Description,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Rule,
      _Plugin
}
