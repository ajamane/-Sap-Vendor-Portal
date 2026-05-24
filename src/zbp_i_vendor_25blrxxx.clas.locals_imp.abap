CLASS lhc_ZI_VENDOR_25BLRXXX DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_vendor_25BLRXXX RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
    IMPORTING REQUEST requested_authorizations FOR zi_vendor_25BLRXXX RESULT result.

    METHODS autofill_status FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zi_vendor_25BLRXXX~autofill_status.

    METHODS validateMandfield FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_vendor_25BLRXXX~validateMandfield.

ENDCLASS.

CLASS lhc_ZI_VENDOR_25BLRXXX IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD autofill_status.

    READ ENTITIES OF zi_vendor_25BLRXXX IN LOCAL MODE
    ENTITY zi_vendor_25BLRXXX
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_status_data).

    DATA(lv_result_status) = VALUE #( lt_status_data[ 1 ]-Status OPTIONAL ).

    IF lv_result_status <> 'C'.
*Modify entity value.
      MODIFY ENTITIES OF zi_vendor_25BLRXXX IN LOCAL MODE
      ENTITY zi_vendor_25BLRXXX
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR <lfs_status_upd> IN lt_status_data ( %tky = <lfs_status_upd>-%tky
      Status = 'C' ) )
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).
    ENDIF.

    CLEAR: lv_result_status.
  ENDMETHOD.

  METHOD validateMandfield.

    READ ENTITIES OF zi_vendor_25BLRXXX IN LOCAL MODE
    ENTITY zi_vendor_25BLRXXX
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_vendor_result).

    LOOP AT lt_vendor_result INTO DATA(ls_vendor_result).
      CONVERT TIME STAMP ls_vendor_result-OrderConfDate TIME ZONE space INTO DATE DATA(rv_Sdate).

      CONVERT TIME STAMP ls_vendor_result-DeliveryDate TIME ZONE space INTO DATE DATA(rv_Ddate).

      IF ls_vendor_result-partner IS INITIAL. "AND ls_vendor_result-sord IS INITIAL.
        APPEND VALUE #( %key = ls_vendor_result-%key
        mykey = ls_vendor_result-mykey ) TO failed-zi_vendor_25BLRXXX.

        APPEND VALUE #( %key = ls_vendor_result-%key
        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
        text = 'Partner is Empty' )
        )

        TO reported-zi_vendor_25BLRXXX.
      ENDIF.

      IF ls_vendor_result-Matnr IS INITIAL.
        failed-zi_vendor_25BLRXXX[] = VALUE #( BASE failed-zi_vendor_25BLRXXX[] ( %key = ls_vendor_result-%key
        mykey = ls_vendor_result-mykey ) ).

        reported-zi_vendor_25BLRXXX[] = VALUE #( BASE reported-zi_vendor_25BLRXXX[] ( %key = ls_vendor_result-%key
        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
        text = 'Material Number is Empty' ) ) ).
      ENDIF.

      IF ls_vendor_result-DeliveryDate IS INITIAL.
        APPEND VALUE #( %key = ls_vendor_result-%key
        mykey = ls_vendor_result-mykey ) TO failed-zi_vendor_25BLRXXX.

        APPEND VALUE #( %key = ls_vendor_result-%key
        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
        text = 'Delivery date is Empty' )
        )

        TO reported-zi_vendor_25BLRXXX.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_VENDOR_25BLRXXX DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_VENDOR_25BLRXXX IMPLEMENTATION.

  METHOD save_modified.

    DATA: lt_salesorderdata TYPE zcl_salesorder_wf_BLRXXX=>tt_sales_data.

    CONSTANTS: c_background_process_name TYPE c LENGTH 64 VALUE 'SALESORD_WF_POST_BGPF'.

    IF create-zi_vendor_25BLRXXX IS NOT INITIAL.
      ASSIGN create-zi_vendor_25BLRXXX TO FIELD-SYMBOL(<lfs_create_details>).

      DATA(lv_key) = VALUE sysuuid_x16( <lfs_create_details>[ 1 ]-Mykey OPTIONAL ).

      DATA(lo_bgpf_operation) = NEW zcl_salesorder_wf_BLRXXX( it_salesorder_data = CORRESPONDING #( create-zi_vendor_25BLRXXX ) ).

      TRY.
*2.Create background process using default destination.
          DATA(lo_process) = cl_bgmc_process_factory=>get_default( )->create( ).

*3.Set name to the background process to be traced in ABAP Cross Trace & put operation in background process.
          lo_process->set_name( c_background_process_name )->set_operation_tx_uncontrolled( lo_bgpf_operation ).
*4.Save background process for execution.
          lo_process->save_for_execution( ).

        CATCH cx_bgmc INTO DATA(lo_exc_bgmc).

      ENDTRY.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

