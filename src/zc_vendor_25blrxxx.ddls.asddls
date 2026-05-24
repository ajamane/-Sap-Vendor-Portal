@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection entity for Vendor'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZC_VENDOR_25BLRXXX
  provider contract transactional_query
  as projection on ZI_VENDOR_25BLRXXX
{
      @UI.facet: [ { id: 'VendorPortal',
      purpose: #STANDARD,
      type: #IDENTIFICATION_REFERENCE,
      label: 'Vendor Portal',
      position: 10 } ]

      @UI.hidden: true
  key Mykey,
      @UI: {
      lineItem: [ { position: 10, importance: #HIGH, label: 'Sales Order' } ],
      identification: [ { position: 10, label: 'Sales Order' } ] }
      @Search.defaultSearchElement: true
      Sord,
      @UI: {
      lineItem: [ { position: 30, importance: #HIGH, label: 'Customer' } ],
      identification: [ { position: 30, label: 'Customer Number' } ],
      selectionField: [ { position: 30 } ] }
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Customer_StdVH', element: 'CustomerID' } }]

      @ObjectModel.text.element: ['CustomerName']
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Customer'
      Partner,

      @UI.hidden: true
      _Customer.FirstName as CustomerName,

      @UI: {
      lineItem: [ { position: 40, importance: #HIGH, label: 'Material No' } ],
      identification: [ { position: 40, label: 'Material Number' } ],
      selectionField: [{ position: 40 } ] }
      @EndUserText.label: 'Material Number'
      @Search.defaultSearchElement: true
      Matnr,
      @UI: {
      lineItem: [ { position: 50, importance: #HIGH, label: 'Order Quantity' } ],
      identification: [ { position: 50, label: 'Order Quantity' } ] }
      @Search.defaultSearchElement: true
      OrderQty,
      Currkey,
      @UI: {
      lineItem: [ { position: 70, importance: #HIGH } ],
      identification: [ { position: 70, label: 'Status[C(Created)|R(Released)|X(Cancel)]' } ] }
      Status,
      @UI: {
      lineItem: [ { position: 60, importance: #HIGH, label: 'Delivery Date' } ],
      identification: [ { position: 60, label: 'Delivery Date' } ] }
      DeliveryDate,
      CreaDateTime,
      CreaUname,
      LchgDateTime,
      LchgUname,
      /* Associations */
      _Currency,
      _Customer
}
