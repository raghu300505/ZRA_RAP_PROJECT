CLASS LHC_ZR_RAGTRAVEL DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ZrRagtravel
        RESULT result,
      setInitialStatus FOR DETERMINE ON MODIFY
            IMPORTING keys FOR ZrRagtravel~setInitialStatus.

          METHODS validateDates FOR VALIDATE ON SAVE
            IMPORTING keys FOR ZrRagtravel~validateDates.
          METHODS validateAmount FOR VALIDATE ON SAVE
            IMPORTING keys FOR ZrRagtravel~validateAmount.
          METHODS calculateDuration FOR DETERMINE ON SAVE
            IMPORTING keys FOR ZrRagtravel~calculateDuration.

          METHODS setApprovalStatus FOR DETERMINE ON SAVE
            IMPORTING keys FOR ZrRagtravel~setApprovalStatus.
*
          METHODS approveTravel FOR MODIFY
            IMPORTING keys FOR ACTION ZrRagtravel~approveTravel.

          METHODS rejectTravel FOR MODIFY
            IMPORTING keys FOR ACTION ZrRagtravel~rejectTravel.
ENDCLASS.

CLASS LHC_ZR_RAGTRAVEL IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.
  METHOD setInitialStatus.
     READ ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
      FIELDS ( status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

  MODIFY ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
      UPDATE FIELDS ( status )
      WITH VALUE #(
        FOR ls_travel IN lt_travel
        WHERE ( status IS INITIAL )
        ( %tky   = ls_travel-%tky
          status = 'N' )
      ).


  ENDMETHOD.

  METHOD validateDates.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    READ ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
      FIELDS ( StartDate EndDate )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

    " Rule 1: Start date >= today
    IF <fs_travel>-startdate < lv_today.

      APPEND VALUE #( %tky = <fs_travel>-%tky )
        TO failed-zrragtravel.

      APPEND VALUE #(
        %tky = <fs_travel>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text     = 'Start date must be today or later'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-zrragtravel.

    ENDIF.

    " Rule 2: End date >= start date
    IF <fs_travel>-enddate < <fs_travel>-startdate.

      APPEND VALUE #( %tky = <fs_travel>-%tky )
        TO failed-zrragtravel.

      APPEND VALUE #(
        %tky = <fs_travel>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text     = 'End date must be after start date'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-zrragtravel.
    ENDIF.

  ENDLOOP.

  ENDMETHOD.

  METHOD validateAmount.
   READ ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
      FIELDS ( BookingAmount Currency )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
     LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs>).

    " ❌ Rule 1: Amount must be positive
    IF <fs>-BookingAmount IS INITIAL OR <fs>-BookingAmount <= 0.

      APPEND VALUE #( %tky = <fs>-%tky )
        TO failed-ZrRagtravel.

      APPEND VALUE #(
        %tky = <fs>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text = 'Booking amount must be greater than 0'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-ZrRagtravel.

    ENDIF.

    " ⚠️ Rule 2: High amount warning
    IF <fs>-BookingAmount > 50000.

      APPEND VALUE #(
        %tky = <fs>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text = 'High amount - approval required'
          severity = if_abap_behv_message=>severity-warning
        )
      ) TO reported-ZrRagtravel.

    ENDIF.

    " ❌ Rule 3: Currency must exist
    IF <fs>-Currency IS INITIAL.

      APPEND VALUE #( %tky = <fs>-%tky )
        TO failed-ZrRagtravel.

      APPEND VALUE #(
        %tky = <fs>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text = 'Currency is required'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-ZrRagtravel.

    ENDIF.

  ENDLOOP.
  ENDMETHOD.

  METHOD calculateDuration.

  READ ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
    FIELDS ( StartDate EndDate Duration )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

  MODIFY ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
    UPDATE FIELDS ( Duration )
    WITH VALUE #(
      FOR ls_travel IN lt_travel
      WHERE ( Duration IS INITIAL )
      (
        %tky = ls_travel-%tky
        Duration =
          COND i(
            WHEN ls_travel-StartDate IS NOT INITIAL
             AND ls_travel-EndDate IS NOT INITIAL
            THEN ls_travel-EndDate - ls_travel-StartDate
            ELSE 0
          )
      )
    ).

ENDMETHOD.
METHOD setApprovalStatus.

  READ ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
    FIELDS ( BookingAmount )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).

  MODIFY ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagTravel
    UPDATE FIELDS ( ApprovalStatus )
    WITH VALUE #(
      FOR ls_travel IN lt_travel
      WHERE ( ApprovalStatus IS INITIAL )
      (
        %tky = ls_travel-%tky
        ApprovalStatus =
          COND #(
            WHEN ls_travel-BookingAmount < 5000
            THEN 'A'
            ELSE 'P'
          )
      )
    ).

ENDMETHOD.
  METHOD APPROVETRAVEL.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    READ ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagtravel
    FIELDS ( Status ApprovalStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_data).

  LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs>).

    " ❌ Cannot approve if already Approved or Rejected
    IF <fs>-Status = 'A' OR <fs>-Status = 'R'.

      APPEND VALUE #( %tky = <fs>-%tky )
        TO failed-ZrRagtravel.

      APPEND VALUE #(
        %tky = <fs>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text = 'Action not allowed for current status'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-ZrRagtravel.

    ENDIF.

  ENDLOOP.

   MODIFY ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagtravel
    UPDATE FIELDS ( Status ApprovalStatus Approver )
    WITH VALUE #(
      FOR key IN keys
      (
        %tky           = key-%tky
        Status         = 'A'
        ApprovalStatus = 'A'
        Approver       = lv_user
      )
    ).

  ENDMETHOD.

  METHOD rejectTravel.

  READ ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagtravel
    FIELDS ( Status Comments )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_data).

  LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs>).
      " ❌ Cannot reject if already Approved or Rejected
    IF <fs>-Status = 'A' OR <fs>-Status = 'R'.

      APPEND VALUE #( %tky = <fs>-%tky )
        TO failed-ZrRagtravel.

      APPEND VALUE #(
        %tky = <fs>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text = 'Action not allowed for current status '
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-ZrRagtravel.

    ENDIF.

    " ❌ Comment mandatory
    IF <fs>-Comments IS INITIAL.

      APPEND VALUE #( %tky = <fs>-%tky )
        TO failed-ZrRagtravel.

      APPEND VALUE #(
        %tky = <fs>-%tky
        %msg = NEW_MESSAGE_WITH_TEXT(
          text = 'Comment required for rejection'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-ZrRagtravel.

    ENDIF.

  ENDLOOP.
*
*  " Only update valid ones
  MODIFY ENTITIES OF zr_ragtravel IN LOCAL MODE
    ENTITY ZrRagtravel
    UPDATE FIELDS ( Status ApprovalStatus )
    WITH VALUE #(
      FOR key IN keys
      (
        %tky           = key-%tky
        Status         = 'R'
        ApprovalStatus = 'R'
      )
    ).

ENDMETHOD.

ENDCLASS.
