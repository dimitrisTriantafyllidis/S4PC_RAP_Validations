@EndUserText.label: 'Billing validation plug-in'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_BILVAL_PLUGIN_QUERY'
define custom entity ZI_BilValPluginVH
{
  key PluginId    : abap.char(30);
      Description : abap.char(60);
}
