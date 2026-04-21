@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZRAGTRAVEL'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_RAGTRAVEL
  as select from ZRAGTRAVEL
{
  key travel_id as TravelID,
  customer_id as CustomerID,
  @Semantics.amount.currencyCode: 'Currency'
  booking_amount as BookingAmount,
  @Consumption.valueHelpDefinition: [ {
    entity.name: 'I_CurrencyStdVH', 
    entity.element: 'Currency', 
    useForValidation: true
  } ]
  currency as Currency,
  travel_type as TravelType,
  approval_status as ApprovalStatus,
  @Semantics.user.createdBy: true
  approver as Approver,
  travel_purpose as TravelPurpose,
  comments as Comments,
  duration as Duration,
  status as Status,
  start_date as StartDate,
  end_date as EndDate,
  @Semantics.user.createdBy: true
  local_created_by as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  local_created_at as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt
}
