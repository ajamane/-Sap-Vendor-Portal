CLASS zcl_salesorder_wf_BLRXXX DEFINITION
PUBLIC
FINAL
CREATE PUBLIC .
  PUBLIC SECTION.
    TYPES: tt_sales_data TYPE STANDARD TABLE OF ZI_Vendor_25BLRXXX INITIAL SIZE 0,
           BEGIN OF ty_logfile,
             msgtype TYPE c LENGTH 1,
             message TYPE bapi_msg,
           END OF ty_logfile,
***BOC By Somak On 02252025 for Defect 52576***
           tt_logfile TYPE STANDARD TABLE OF ty_logfile WITH DEFAULT KEY INITIAL SIZE 0.

    METHODS: constructor IMPORTING it_salesorder_data TYPE tt_sales_data OPTIONAL,
      process_data RETURNING VALUE(rv_salesorder) TYPE vbeln.

    INTERFACES: if_oo_adt_classrun,
      if_serializable_object,
      if_bgmc_operation,
      if_bgmc_op_single,
      if_bgmc_op_single_tx_uncontr.
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: gt_salesorder_data TYPE tt_sales_data,
          gt_log             TYPE tt_logfile.

    METHODS:
      get_access_token EXPORTING et_cookies             TYPE if_web_http_request=>cookies
                       RETURNING VALUE(rv_access_token) TYPE string,
      bpa_post_call IMPORTING iv_access_token   TYPE string
                              it_cookies        TYPE if_web_http_request=>cookies
                    RETURNING VALUE(rv_success) TYPE abap_boolean.
ENDCLASS.



CLASS zcl_salesorder_wf_BLRXXX IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA(rv_access_token) = me->process_data( ).
  ENDMETHOD.


  METHOD constructor.
    gt_salesorder_data[] = CORRESPONDING #( it_salesorder_data[] ).
  ENDMETHOD.


  METHOD process_data.
    "This is an executable method in which we create a deep sales order and update a field using the Service Consumption Model


    DATA: lv_csrf_token     TYPE string,
          lt_cookies        TYPE if_web_http_request=>cookies,
          lv_update_success TYPE abap_boolean.

* Get OAUTH Access token
    DATA(lv_access_token) = me->get_access_token( IMPORTING et_cookies = lt_cookies[] ).

    IF lv_access_token IS NOT INITIAL.
* Make post call to BPA Instance for WF
      DATA(lv_success) = me->bpa_post_call( iv_access_token = lv_access_token
      it_cookies = lt_cookies[] ).
    ENDIF.
    CLEAR: lv_access_token.
  ENDMETHOD.

  METHOD get_access_token.

    DATA: lv_token_url        TYPE string,
          lv_client_id        TYPE string,
          lv_client_secret    TYPE string,
          ls_data_deserialize TYPE REF TO data,
          lv_bearer_token     TYPE string.

    FIELD-SYMBOLS: <data>                  TYPE data,
                   <lfs_ACCESS_TOKEN_DATA> TYPE data.

* Define your OAuth 2.0 endpoint and credentials
    lv_token_url = 'https://5f3d4c66trial.authentication.us10.hana.ondemand.com/oauth/token'.
    lv_client_id = 'sb-afe6c452-b0a2-441b-81bf-2885acb2ddc8!b549683|xsuaa!b49390'.
    lv_client_secret = 'ffbf9421-e2e3-4cc4-a0a5-cc85096bc944$Locrrq3Fzaz7mtUjVMeXM-MECAcMrix1to74X1Ch2bU='.

*create http destination by url
    TRY.
        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( lv_token_url ). "Token URL
      CATCH cx_http_dest_provider_error INTO DATA(lo_exc_dest).
        gt_log[] = VALUE #( BASE gt_log[] ( msgtype = 'E'
        message = lo_exc_dest->get_longtext( ) ) ).
    ENDTRY.

*create HTTP client by destination
    TRY.
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
      CATCH cx_web_http_client_error INTO DATA(lo_web_excep).
        gt_log[] = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_excep->get_longtext( ) ) ).
    ENDTRY.

    TRY.
        lo_http_client->accept_cookies( abap_true ).
      CATCH cx_web_http_client_error INTO lo_web_excep.
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_excep->get_longtext( ) ) ).
    ENDTRY.

    "adding headers
    DATA(lo_http_request) = lo_http_client->get_http_request( ).

*Set Header Details
    lo_http_request->set_header_fields( VALUE #( ( name = 'cookie' value = 'X' )
    ( name = 'Content-Type' value = 'application/x-www-form-urlencoded' ) ) ).

    lo_http_request->set_authorization_basic( i_username = lv_client_id
    i_password = lv_client_secret ).

    lo_http_request->set_form_field( i_name = 'grant_type'
    i_value = 'client_credentials' ).

    lo_http_request->set_query( space ).

    TRY.
        "set request method and execute request get
        DATA(lo_web_http_response) = lo_http_client->execute( if_web_http_client=>post ).

        IF lo_web_http_response->get_status( )-code = 200.
* rv_access_token = |Bearer { lo_web_http_response->get_text( ) }|.
          DATA(lv_access_token_json) = lo_web_http_response->get_text( ).

          IF lv_access_token_json IS NOT INITIAL.
*Extract error details from JSON response.
            /ui2/cl_json=>deserialize( EXPORTING json = lv_access_token_json
            CHANGING data = ls_data_deserialize ).
            IF ls_data_deserialize IS BOUND.
              ASSIGN ls_data_deserialize->* TO <data>.
              IF <data> IS ASSIGNED.
                ASSIGN COMPONENT `ACCESS_TOKEN` OF STRUCTURE <data> TO FIELD-SYMBOL(<lfs_ACCESS_TOKEN>).
                IF <lfs_ACCESS_TOKEN> IS ASSIGNED.
                  ASSIGN <lfs_ACCESS_TOKEN>->* TO <lfs_ACCESS_TOKEN_DATA>.
                  IF <lfs_ACCESS_TOKEN_DATA> IS ASSIGNED.
* Get error code details.
                    rv_access_token = |Bearer { <lfs_ACCESS_TOKEN_DATA> }|.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

*Get Cookies data
          et_cookies = lo_web_http_response->get_cookies( ).
        ENDIF.

      CATCH cx_web_http_client_error INTO lo_web_excep.
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_excep->get_longtext( ) ) ).
    ENDTRY.

  ENDMETHOD.

  METHOD bpa_post_call.

    CONSTANTS: lc_bpa_wf_post_url TYPE string VALUE 'https://spa-api-gateway-bpi-us-prod.cfapps.us10.hana.ondemand.com/workflow/rest/v1/workflow-instances'.

*create http destination by url
    TRY.
        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( lc_bpa_wf_post_url ). "API URL
      CATCH cx_http_dest_provider_error INTO DATA(lo_exc_dest).
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_exc_dest->get_longtext( ) ) ).
    ENDTRY.

*create HTTP client by destination
    TRY.
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
      CATCH cx_web_http_client_error INTO DATA(lo_web_excep).
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_excep->get_longtext( ) ) ).
    ENDTRY.

    "adding headers
    DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).

    TRY.
        lo_web_http_client->accept_cookies( abap_true ).
      CATCH cx_web_http_client_error INTO lo_web_excep.
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_excep->get_longtext( ) ) ).
    ENDTRY.

*Set Header Details
    lo_web_http_request->set_header_fields( VALUE #( ( name = 'Authorization' value = iv_access_token )
* ( name = 'DataServiceVersion' value = '2.0' )
    ( name = 'Accept' value = 'application/json' )
    ( name = 'Content-type' value = 'application/json' )
* ( name = c_etag value = '*' )
    ) ).
    lo_web_http_request->set_query( space ).

*Set Cookies
    TRY.
        LOOP AT it_cookies[] ASSIGNING FIELD-SYMBOL(<lfs_cookies>)
        WHERE name CS 'SAP_SESSIONID'.
          DATA(ls_cookie) = <lfs_cookies>.
          EXIT.
        ENDLOOP.

        DATA(lv_resp_cookie) = lo_web_http_request->set_cookie( i_name = ls_cookie-name
        i_path = ls_cookie-path
        i_value = ls_cookie-value
        i_domain = ls_cookie-domain
        i_expires = ls_cookie-expires
        i_secure = ls_cookie-secure ).
      CATCH cx_web_message_error INTO DATA(lo_web_msg_excp).
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_msg_excp->get_longtext( ) ) ).
    ENDTRY.

    DATA(ls_salesorder_wf_data) = VALUE #( gt_salesorder_data[ 1 ] OPTIONAL ).
    " DATA(lv_delv_date) = CONV datum( ls_salesorder_wf_data-DeliveryDate ).
    "subhant added
    TRY.
        CONVERT TIME STAMP ls_salesorder_wf_data-deliverydate
        TIME ZONE cl_abap_context_info=>get_user_time_zone( )
        INTO DATE DATA(lv_delv_date)
        TIME DATA(tim).
      CATCH cx_abap_context_info_error.
        "handle exception
    ENDTRY.

    DATA(lv_payload) = '{' &&
    |"definitionId": "us10.5f3d4c66trial.sob2025makerskol.salesOrderApproval",| &&
    ' "context": { ' &&
    ' "salesordinput": { ' &&
    | "VendorUUID": "{ ls_salesorder_wf_data-Mykey }", | &&
    | "Customer": "{ ls_salesorder_wf_data-Partner }", | &&
    | "Matnr": "{ ls_salesorder_wf_data-Matnr }", | &&
    | "OrderQty": "{ ls_salesorder_wf_data-OrderQty }", | &&
    | "delivery_date": | && |"{ lv_delv_date+0(4) }-{ lv_delv_date+4(2) }-{ lv_delv_date+6(2) }"| &&
    '}' &&
    '}' &&
    '}'.
    TRY.
        lo_web_http_request->set_text( i_text = lv_payload ).
      CATCH cx_web_message_error INTO lo_web_msg_excp.
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_msg_excp->get_longtext( ) ) ).
    ENDTRY.

* POST CALL
    TRY.
        "set request method and execute request patch
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).
        DATA(lv_result) = lo_web_http_response->get_text( ).
      CATCH cx_web_http_client_error INTO lo_web_excep.
        gt_log = VALUE #( BASE gt_log ( msgtype = 'E'
        message = lo_web_excep->get_longtext( ) ) ).
    ENDTRY.


*Get return structure filled.
    DATA(ls_response) = lo_web_http_response->get_status( ).
    IF ls_response-code = 200 OR ls_response-code = 201 .
      rv_success = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD if_bgmc_op_single~execute.

    CHECK 1 = 1 .

  ENDMETHOD.

  METHOD if_bgmc_op_single_tx_uncontr~execute.
    DATA(rv_access_token) = me->process_data( ).
  ENDMETHOD.

ENDCLASS.

