@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Entity for Vendor'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
serviceQuality: #X,
sizeCategory: #S,
dataClass: #MIXED
}
define root view entity ZI_VENDOR_25BLRXXX
  as select from ztvendor_blrxxx as Vendor
  association [0..1] to /DMO/I_Customer as _Customer on $projection.Partner = _Customer.CustomerID
  association [0..1] to I_Currency      as _Currency on $projection.Currkey = _Currency.Currency

{
  key mykey           as Mykey,
      sord            as Sord,
      partner         as Partner,
      matnr           as Matnr,
      orderqty        as OrderQty,
      @Semantics.amount.currencyCode: 'currkey'
      totcost         as Totcost,
      currkey         as Currkey,
      status          as Status,
      order_conf_date as OrderConfDate,
      delivery_date   as DeliveryDate,
      remarks         as Remarks,
      /*-- Admin data --*/
      @Semantics.systemDateTime.createdAt: true
      crea_date_time  as CreaDateTime,
      @Semantics.user.createdBy: true
      crea_uname      as CreaUname,
      @Semantics.systemDateTime.lastChangedAt: true
      lchg_date_time  as LchgDateTime,
      @Semantics.user.lastChangedBy: true
      lchg_uname      as LchgUname,
      @Semantics.largeObject:{ mimeType: 'MimeType',
      fileName: 'Filename',
      contentDispositionPreference: #INLINE }
      attachment      as Attachment,
      @Semantics.mimeType: true
      mimetype        as Mimetype,
      filename        as Filename,
      /* Public associations */
      _Customer,
      _Currency

}
