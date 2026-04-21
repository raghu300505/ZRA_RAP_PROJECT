@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZRAGTRAVEL'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_RAGTRAVEL
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_RAGTRAVEL
  association [1..1] to ZR_RAGTRAVEL as _BaseEntity on $projection.TRAVELID = _BaseEntity.TRAVELID
{
  key TravelID,
  CustomerID,
  @Semantics: {
    Amount.Currencycode: 'Currency'
  }
  BookingAmount,
  @Consumption: {
    Valuehelpdefinition: [ {
      Entity.Element: 'Currency', 
      Entity.Name: 'I_CurrencyStdVH', 
      Useforvalidation: true
    } ]
  }
  Currency,
  TravelType,
  ApprovalStatus,
  @Semantics: {
    User.Createdby: true
  }
  Approver,
  TravelPurpose,
  Comments,
  Duration,
  Status,
  StartDate,
  EndDate,
  @Semantics: {
    User.Createdby: true
  }
  LocalCreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  LocalCreatedAt,
  @Semantics: {
    User.Localinstancelastchangedby: true
  }
  LocalLastChangedBy,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChangedAt,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  _BaseEntity
}
