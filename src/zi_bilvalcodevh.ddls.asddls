@EndUserText.label: 'Billing validation code'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_BILVAL_CODE_QUERY'
define custom entity ZI_BilValCodeVH
{
  key CodeGroup   : abap.char(15);
  key Code        : abap.char(20);
      Description : abap.char(60);
}
