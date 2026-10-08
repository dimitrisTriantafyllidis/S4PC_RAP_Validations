@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Validation Configuration'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_BilValConfig
  provider contract transactional_query
  as projection on ZI_BilValConfig
{
  key ConfigId,
      @Search.defaultSearchElement: true
      Description,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      _Rule   : redirected to composition child ZC_BilValRule,
      _Plugin : redirected to composition child ZC_BilValPlugin
}
