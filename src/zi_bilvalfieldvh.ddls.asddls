@EndUserText.label: 'Billing validation field'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_BILVAL_FIELD_QUERY'
define custom entity ZI_BilValFieldVH
{
  key FieldName   : abap.char(30);
  key Scope       : abap.char(1);
      Description : abap.char(60);
}
