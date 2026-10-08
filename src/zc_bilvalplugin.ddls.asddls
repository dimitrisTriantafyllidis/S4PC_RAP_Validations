@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Plug-in'
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZC_BilValPlugin
  as projection on ZI_BilValPlugin
{
  key PluginId,
      ConfigId,
      @Search.defaultSearchElement: true
      Description,
      Checkpoint,
      ActiveFlag,
      Sequence,
      ApprovalReason,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      _Config : redirected to parent ZC_BilValConfig
}
