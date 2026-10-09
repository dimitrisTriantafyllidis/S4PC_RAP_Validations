@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Plug-in'
@Metadata.allowExtensions: true
define view entity ZI_BilValPlugin
  as select from zbilval_plugin
  association to parent ZI_BilValConfig as _Config on $projection.ConfigId = _Config.ConfigId
{
  key plugin_id             as PluginId,
      config_id             as ConfigId,
      description           as Description,
      checkpoint_id         as CheckpointCode,
      active_flag           as ActiveFlag,
      sequence              as Sequence,
      approval_reason       as ApprovalReason,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Config
}
