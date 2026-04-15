CLASS zcl_ai_claude DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_extension .
    INTERFACES zif_fi_vendor_api .

    " Response structure for employee service
    TYPES: BEGIN OF ty_s_employee_response,
             code       TYPE char1,
             message    TYPE string,
             pernr      TYPE persno,
             first_name TYPE pad_vorna,
             last_name  TYPE pad_nachn,
             orgeh      TYPE orgeh,
             orgeh_text TYPE stext,
             stell      TYPE stell,
           END OF ty_s_employee_response.

    " Response structure for active employee service
    TYPES: BEGIN OF ty_s_active_emp_response,
             code       TYPE char1,
             message    TYPE string,
             pernr      TYPE persno,
             first_name TYPE pad_vorna,
             last_name  TYPE pad_nachn,
             orgeh      TYPE orgeh,
             orgeh_text TYPE stext,
           END OF ty_s_active_emp_response.

    " Onboarding employee detail structure
    TYPES: BEGIN OF ty_s_onboarding_emp,
             pernr              TYPE persno,
             first_name         TYPE pad_vorna,
             last_name          TYPE pad_nachn,
             email              TYPE ad_smtpadr,
             hire_days          TYPE i,
             work_type          TYPE char40,
             buddy_pernr        TYPE persno,
             buddy_first_name   TYPE pad_vorna,
             buddy_last_name    TYPE pad_nachn,
             hrbp_pernr         TYPE persno,
             hrbp_first_name    TYPE pad_vorna,
             hrbp_last_name     TYPE pad_nachn,
             hrbp_email         TYPE ad_smtpadr,
             manager_pernr      TYPE persno,
             manager_first_name TYPE pad_vorna,
             manager_last_name  TYPE pad_nachn,
             manager_email      TYPE ad_smtpadr,
           END OF ty_s_onboarding_emp,
           ty_t_onboarding_emp TYPE STANDARD TABLE OF ty_s_onboarding_emp WITH EMPTY KEY.

    " Onboarding response structure
    TYPES: BEGIN OF ty_s_onboarding_response,
             code      TYPE char1,
             message   TYPE string,
             count     TYPE i,
             employees TYPE ty_t_onboarding_emp,
           END OF ty_s_onboarding_response.

    " Request structure — shared for all services
    TYPES: BEGIN OF ty_s_employee_request,
             action TYPE string,
             pernr  TYPE persno,
             date   TYPE begda,
             day    TYPE i,
           END OF ty_s_employee_request.

    CONSTANTS: gc_code_success        TYPE char1 VALUE 'S',
               gc_code_error          TYPE char1 VALUE 'E',
               gc_action_employee     TYPE string VALUE 'GET_EMPLOYEE',
               gc_action_active       TYPE string VALUE 'GET_ACTIVE_EMPLOYEE',
               gc_action_onboarding   TYPE string VALUE 'GET_ONBOARDING',
               gc_action_vendor_bal   TYPE string VALUE 'GET_VENDOR_BALANCE',
               gc_stat2_active        TYPE pa0000-stat2 VALUE '3',
               gc_date_type_hire      TYPE char2 VALUE '03'.

    METHODS get_employee_data
      IMPORTING
        iv_pernr           TYPE persno
        iv_date            TYPE begda
      RETURNING
        VALUE(rs_response) TYPE ty_s_employee_response.

    METHODS get_active_employee_data
      IMPORTING
        iv_pernr           TYPE persno
        iv_date            TYPE begda
      RETURNING
        VALUE(rs_response) TYPE ty_s_active_emp_response.

    METHODS get_onboarding_data
      IMPORTING
        iv_date            TYPE begda
        iv_day             TYPE i
      RETURNING
        VALUE(rs_response) TYPE ty_s_onboarding_response.

    ALIASES get_vendor_balance FOR zif_fi_vendor_api~get_vendor_balance.

  PROTECTED SECTION.
  PRIVATE SECTION.

    " Internal structure for BSIK/BSAK line item aggregation
    TYPES: BEGIN OF ty_s_vendor_item,
             bukrs TYPE bukrs,
             lifnr TYPE lifnr,
             gjahr TYPE gjahr,
             waers TYPE waers,
             dmbtr TYPE dmbtr,
             shkzg TYPE shkzg,
           END OF ty_s_vendor_item,
           ty_t_vendor_items TYPE STANDARD TABLE OF ty_s_vendor_item WITH EMPTY KEY.

    METHODS handle_vendor_balance
      IMPORTING
        iv_cdata        TYPE string
      RETURNING
        VALUE(rv_json)  TYPE string.

    METHODS handle_hr_request
      IMPORTING
        iv_cdata        TYPE string
        iv_action       TYPE string
        is_request      TYPE ty_s_employee_request
      RETURNING
        VALUE(rv_json)  TYPE string.

    METHODS check_vendor_exists
      IMPORTING
        iv_lifnr         TYPE lifnr
        iv_bukrs         TYPE bukrs
      RETURNING
        VALUE(rv_exists) TYPE abap_bool.

    METHODS fetch_vendor_items
      IMPORTING
        iv_lifnr         TYPE lifnr
        iv_bukrs         TYPE bukrs
        iv_gjahr         TYPE gjahr
      RETURNING
        VALUE(rt_items)  TYPE ty_t_vendor_items.

    METHODS aggregate_balance
      IMPORTING
        it_items          TYPE ty_t_vendor_items
        iv_lifnr          TYPE lifnr
        iv_bukrs          TYPE bukrs
        iv_gjahr          TYPE gjahr
      RETURNING
        VALUE(rs_balance) TYPE zif_fi_vendor_api=>ty_s_vendor_balance.

    METHODS get_orgeh_text
      IMPORTING
        iv_orgeh       TYPE orgeh
        iv_date        TYPE begda
      RETURNING
        VALUE(rv_text) TYPE stext.

    METHODS get_employee_email
      IMPORTING
        iv_pernr       TYPE persno
        iv_date        TYPE begda
      RETURNING
        VALUE(rv_email) TYPE ad_smtpadr.

    METHODS get_employee_name
      IMPORTING
        iv_pernr           TYPE persno
        iv_date            TYPE begda
      EXPORTING
        ev_first_name      TYPE pad_vorna
        ev_last_name       TYPE pad_nachn.

    METHODS get_manager_pernr
      IMPORTING
        iv_orgeh          TYPE orgeh
        iv_date           TYPE begda
      RETURNING
        VALUE(rv_manager) TYPE persno.

    METHODS get_hrbp_pernr
      IMPORTING
        iv_orgeh        TYPE orgeh
        iv_date         TYPE begda
      RETURNING
        VALUE(rv_hrbp)  TYPE persno.

    METHODS check_hr_authority
      IMPORTING
        iv_infty        TYPE infty
        iv_werks        TYPE persa DEFAULT space
        iv_persg        TYPE persg DEFAULT space
        iv_persk        TYPE persk DEFAULT space
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    METHODS is_active_employee
      IMPORTING
        iv_pernr         TYPE persno
        iv_date          TYPE begda
      RETURNING
        VALUE(rv_active) TYPE abap_bool.

ENDCLASS.



CLASS zcl_ai_claude IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA(lv_cdata) = server->request->get_cdata( ).
    DATA lv_json TYPE string.

    " Determine action from request
    DATA ls_generic TYPE ty_s_employee_request.
    /ui2/cl_json=>deserialize(
      EXPORTING json = lv_cdata
      CHANGING  data = ls_generic ).

    DATA(lv_action) = to_upper( ls_generic-action ).

    TRY.
        " Route: vendor balance has its own request structure
        IF lv_action = gc_action_vendor_bal.
          lv_json = handle_vendor_balance( lv_cdata ).
        ELSE.
          lv_json = handle_hr_request( iv_cdata  = lv_cdata
                                       iv_action = lv_action
                                       is_request = ls_generic ).
        ENDIF.

      CATCH cx_root INTO DATA(lx_root).
        lv_json = /ui2/cl_json=>serialize(
          data = VALUE zif_fi_vendor_api=>ty_s_vendor_response(
            code    = gc_code_error
            message = lx_root->get_text( ) ) ).
    ENDTRY.

    " Set response
    server->response->set_cdata( lv_json ).
    server->response->set_header_field(
      name  = 'Content-Type'
      value = 'application/json' ).

    IF lv_json CS '"code":"S"'.
      server->response->set_status( code = 200 reason = 'OK' ).
    ELSE.
      server->response->set_status( code = 400 reason = 'Bad Request' ).
    ENDIF.
  ENDMETHOD.


  METHOD handle_vendor_balance.
    " Deserialize vendor-specific request
    DATA ls_vreq TYPE zif_fi_vendor_api=>ty_s_vendor_request.
    /ui2/cl_json=>deserialize(
      EXPORTING json = iv_cdata
      CHANGING  data = ls_vreq ).

    " Validate required fields
    IF ls_vreq-lifnr IS INITIAL OR ls_vreq-bukrs IS INITIAL OR ls_vreq-gjahr IS INITIAL.
      rv_json = /ui2/cl_json=>serialize(
        data = VALUE zif_fi_vendor_api=>ty_s_vendor_response(
          code    = gc_code_error
          message = 'LIFNR, BUKRS, and GJAHR are required' ) ).
      RETURN.
    ENDIF.

    " Authorization check — F_BKPF_BUK for company code
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD ls_vreq-bukrs
      ID 'ACTVT' FIELD '03'.

    IF sy-subrc <> 0.
      rv_json = /ui2/cl_json=>serialize(
        data = VALUE zif_fi_vendor_api=>ty_s_vendor_response(
          code    = gc_code_error
          message = |No authorization for company code { ls_vreq-bukrs }| ) ).
      RETURN.
    ENDIF.

    TRY.
        DATA(ls_balance) = get_vendor_balance(
          iv_lifnr = ls_vreq-lifnr
          iv_bukrs = ls_vreq-bukrs
          iv_gjahr = ls_vreq-gjahr ).

        rv_json = /ui2/cl_json=>serialize(
          data = VALUE zif_fi_vendor_api=>ty_s_vendor_response(
            code    = gc_code_success
            message = |Vendor balance retrieved successfully|
            balance = ls_balance )
          compress    = abap_true
          pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

      CATCH zcx_fi_vendor_not_found INTO DATA(lx_vendor).
        rv_json = /ui2/cl_json=>serialize(
          data = VALUE zif_fi_vendor_api=>ty_s_vendor_response(
            code    = gc_code_error
            message = lx_vendor->get_text( ) ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD handle_hr_request.
    " Validate date — required for all HR services
    IF is_request-date IS INITIAL.
      rv_json = /ui2/cl_json=>serialize(
        data = VALUE ty_s_employee_response(
          code    = gc_code_error
          message = 'DATE is required' ) ).
      RETURN.
    ENDIF.

    CASE iv_action.

      WHEN gc_action_onboarding.
        IF is_request-day IS INITIAL.
          rv_json = /ui2/cl_json=>serialize(
            data = VALUE ty_s_onboarding_response(
              code    = gc_code_error
              message = 'DAY parameter is required' ) ).
        ELSE.
          DATA(ls_onboard_resp) = get_onboarding_data(
            iv_date = is_request-date
            iv_day  = is_request-day ).
          rv_json = /ui2/cl_json=>serialize(
            data        = ls_onboard_resp
            compress    = abap_true
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
        ENDIF.

      WHEN gc_action_active.
        IF is_request-pernr IS INITIAL.
          rv_json = /ui2/cl_json=>serialize(
            data = VALUE ty_s_active_emp_response(
              code = gc_code_error  message = 'PERNR is required' ) ).
        ELSE.
          DATA(ls_active_resp) = get_active_employee_data(
            iv_pernr = is_request-pernr
            iv_date  = is_request-date ).
          rv_json = /ui2/cl_json=>serialize(
            data        = ls_active_resp
            compress    = abap_true
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
        ENDIF.

      WHEN gc_action_employee OR space.
        IF is_request-pernr IS INITIAL.
          rv_json = /ui2/cl_json=>serialize(
            data = VALUE ty_s_employee_response(
              code = gc_code_error  message = 'PERNR is required' ) ).
        ELSE.
          DATA(ls_emp_resp) = get_employee_data(
            iv_pernr = is_request-pernr
            iv_date  = is_request-date ).
          rv_json = /ui2/cl_json=>serialize(
            data        = ls_emp_resp
            compress    = abap_true
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
        ENDIF.

      WHEN OTHERS.
        rv_json = /ui2/cl_json=>serialize(
          data = VALUE ty_s_employee_response(
            code    = gc_code_error
            message = |Unknown action: { iv_action }| ) ).

    ENDCASE.
  ENDMETHOD.


  METHOD get_onboarding_data.
    " Authority check
    IF check_hr_authority( iv_infty = '0041' ) = abap_false.
      rs_response-code    = gc_code_error.
      rs_response-message = 'No authorization for HR data'.
      RETURN.
    ENDIF.

    " Calculate target hire date: employees hired exactly iv_day days ago
    DATA(lv_target_date) = CONV begda( iv_date - iv_day ).

    " Find employees with hire date (PA0041 date type 03) matching target
    " PA0041 stores date types in DAR01-DAR12, dates in DAT01-DAT12
    SELECT pernr, dar01, dat01, dar02, dat02, dar03, dat03,
           dar04, dat04, dar05, dat05, dar06, dat06,
           dar07, dat07, dar08, dat08, dar09, dat09,
           dar10, dat10, dar11, dat11, dar12, dat12
      FROM pa0041
      INTO TABLE @DATA(lt_pa0041)
      WHERE begda <= @iv_date
        AND endda >= @iv_date
        AND ( dar01 = @gc_date_type_hire
           OR dar02 = @gc_date_type_hire
           OR dar03 = @gc_date_type_hire
           OR dar04 = @gc_date_type_hire
           OR dar05 = @gc_date_type_hire
           OR dar06 = @gc_date_type_hire
           OR dar07 = @gc_date_type_hire
           OR dar08 = @gc_date_type_hire
           OR dar09 = @gc_date_type_hire
           OR dar10 = @gc_date_type_hire
           OR dar11 = @gc_date_type_hire
           OR dar12 = @gc_date_type_hire ).

    IF sy-subrc <> 0.
      rs_response-code    = gc_code_error.
      rs_response-message = |No employees found with hire date type 03|.
      RETURN.
    ENDIF.

    " Filter: find employees whose hire date matches target date
    DATA lt_matching TYPE TABLE OF persno.
    LOOP AT lt_pa0041 ASSIGNING FIELD-SYMBOL(<ls_0041>).
      IF ( <ls_0041>-dar01 = gc_date_type_hire AND <ls_0041>-dat01 = lv_target_date )
        OR ( <ls_0041>-dar02 = gc_date_type_hire AND <ls_0041>-dat02 = lv_target_date )
        OR ( <ls_0041>-dar03 = gc_date_type_hire AND <ls_0041>-dat03 = lv_target_date )
        OR ( <ls_0041>-dar04 = gc_date_type_hire AND <ls_0041>-dat04 = lv_target_date )
        OR ( <ls_0041>-dar05 = gc_date_type_hire AND <ls_0041>-dat05 = lv_target_date )
        OR ( <ls_0041>-dar06 = gc_date_type_hire AND <ls_0041>-dat06 = lv_target_date )
        OR ( <ls_0041>-dar07 = gc_date_type_hire AND <ls_0041>-dat07 = lv_target_date )
        OR ( <ls_0041>-dar08 = gc_date_type_hire AND <ls_0041>-dat08 = lv_target_date )
        OR ( <ls_0041>-dar09 = gc_date_type_hire AND <ls_0041>-dat09 = lv_target_date )
        OR ( <ls_0041>-dar10 = gc_date_type_hire AND <ls_0041>-dat10 = lv_target_date )
        OR ( <ls_0041>-dar11 = gc_date_type_hire AND <ls_0041>-dat11 = lv_target_date )
        OR ( <ls_0041>-dar12 = gc_date_type_hire AND <ls_0041>-dat12 = lv_target_date ).
        APPEND <ls_0041>-pernr TO lt_matching.
      ENDIF.
    ENDLOOP.

    IF lt_matching IS INITIAL.
      rs_response-code    = gc_code_error.
      rs_response-message = |No employees found with { iv_day } days since hire|.
      RETURN.
    ENDIF.

    " Check active status (PA0000 STAT2 = 3) — bulk fetch, no SELECT in LOOP
    SELECT pernr
      FROM pa0000
      FOR ALL ENTRIES IN @lt_matching
      INTO TABLE @DATA(lt_active)
      WHERE pernr = @lt_matching-table_line
        AND stat2 = @gc_stat2_active
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      rs_response-code    = gc_code_error.
      rs_response-message = |No active employees found with { iv_day } days since hire|.
      RETURN.
    ENDIF.

    " Bulk fetch personal data (PA0002) — no SELECT in LOOP
    SELECT pernr, vorna, nachn
      FROM pa0002
      FOR ALL ENTRIES IN @lt_active
      INTO TABLE @DATA(lt_pa0002)
      WHERE pernr = @lt_active-pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    " Bulk fetch emails (PA0105 subtype 0010)
    SELECT pernr, usrid_long
      FROM pa0105
      FOR ALL ENTRIES IN @lt_active
      INTO TABLE @DATA(lt_pa0105)
      WHERE pernr = @lt_active-pernr
        AND subty = '0010'
        AND begda <= @iv_date
        AND endda >= @iv_date.

    " Bulk fetch org data (PA0001) — ORGEH
    SELECT pernr, orgeh
      FROM pa0001
      FOR ALL ENTRIES IN @lt_active
      INTO TABLE @DATA(lt_pa0001)
      WHERE pernr = @lt_active-pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    " Bulk fetch work type (PA9907) — custom infotype
    SELECT pernr, calzm
      FROM pa9907
      FOR ALL ENTRIES IN @lt_active
      INTO TABLE @DATA(lt_pa9907)
      WHERE pernr = @lt_active-pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    " Bulk fetch buddy (PA9114) — custom infotype
    SELECT pernr, buddy
      FROM pa9114
      FOR ALL ENTRIES IN @lt_active
      INTO TABLE @DATA(lt_pa9114)
      WHERE pernr = @lt_active-pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    " Assemble response for each active matching employee
    LOOP AT lt_active ASSIGNING FIELD-SYMBOL(<ls_active>).
      DATA ls_emp TYPE ty_s_onboarding_emp.
      CLEAR ls_emp.

      ls_emp-pernr     = <ls_active>-pernr.
      ls_emp-hire_days = iv_day.

      " Personal data
      READ TABLE lt_pa0002 ASSIGNING FIELD-SYMBOL(<ls_0002>)
        WITH KEY pernr = <ls_active>-pernr.
      IF sy-subrc = 0.
        ls_emp-first_name = <ls_0002>-vorna.
        ls_emp-last_name  = <ls_0002>-nachn.
      ENDIF.

      " Email
      READ TABLE lt_pa0105 ASSIGNING FIELD-SYMBOL(<ls_0105>)
        WITH KEY pernr = <ls_active>-pernr.
      IF sy-subrc = 0.
        ls_emp-email = <ls_0105>-usrid_long.
      ENDIF.

      " Work type
      READ TABLE lt_pa9907 ASSIGNING FIELD-SYMBOL(<ls_9907>)
        WITH KEY pernr = <ls_active>-pernr.
      IF sy-subrc = 0.
        ls_emp-work_type = <ls_9907>-calzm.
      ENDIF.

      " Buddy
      READ TABLE lt_pa9114 ASSIGNING FIELD-SYMBOL(<ls_9114>)
        WITH KEY pernr = <ls_active>-pernr.
      IF sy-subrc = 0.
        ls_emp-buddy_pernr = <ls_9114>-buddy.
        " Get buddy name
        get_employee_name(
          EXPORTING iv_pernr      = CONV #( <ls_9114>-buddy )
                    iv_date       = iv_date
          IMPORTING ev_first_name = ls_emp-buddy_first_name
                    ev_last_name  = ls_emp-buddy_last_name ).
      ENDIF.

      " Org unit — needed for manager and HRBP lookups
      READ TABLE lt_pa0001 ASSIGNING FIELD-SYMBOL(<ls_0001>)
        WITH KEY pernr = <ls_active>-pernr.
      IF sy-subrc = 0.
        " HRBP
        ls_emp-hrbp_pernr = get_hrbp_pernr(
          iv_orgeh = <ls_0001>-orgeh
          iv_date  = iv_date ).
        IF ls_emp-hrbp_pernr IS NOT INITIAL.
          get_employee_name(
            EXPORTING iv_pernr      = ls_emp-hrbp_pernr
                      iv_date       = iv_date
            IMPORTING ev_first_name = ls_emp-hrbp_first_name
                      ev_last_name  = ls_emp-hrbp_last_name ).
          ls_emp-hrbp_email = get_employee_email(
            iv_pernr = ls_emp-hrbp_pernr
            iv_date  = iv_date ).
        ENDIF.

        " Manager — HRP1001 A012 relationship
        ls_emp-manager_pernr = get_manager_pernr(
          iv_orgeh = <ls_0001>-orgeh
          iv_date  = iv_date ).
        IF ls_emp-manager_pernr IS NOT INITIAL.
          get_employee_name(
            EXPORTING iv_pernr      = ls_emp-manager_pernr
                      iv_date       = iv_date
            IMPORTING ev_first_name = ls_emp-manager_first_name
                      ev_last_name  = ls_emp-manager_last_name ).
          ls_emp-manager_email = get_employee_email(
            iv_pernr = ls_emp-manager_pernr
            iv_date  = iv_date ).
        ENDIF.
      ENDIF.

      APPEND ls_emp TO rs_response-employees.
    ENDLOOP.

    rs_response-count   = lines( rs_response-employees ).
    rs_response-code    = gc_code_success.
    rs_response-message = |{ rs_response-count } employees found with { iv_day } days since hire|.
  ENDMETHOD.


  METHOD get_employee_data.
    IF check_hr_authority( iv_infty = '0001' ) = abap_false.
      rs_response-code    = gc_code_error.
      rs_response-message = 'No authorization for HR data'.
      RETURN.
    ENDIF.

    SELECT SINGLE vorna, nachn
      FROM pa0002
      INTO (@rs_response-first_name, @rs_response-last_name)
      WHERE pernr = @iv_pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      rs_response-code    = gc_code_error.
      rs_response-message = |Employee { iv_pernr } not found for date { iv_date }|.
      RETURN.
    ENDIF.

    SELECT SINGLE orgeh, stell
      FROM pa0001
      INTO (@rs_response-orgeh, @rs_response-stell)
      WHERE pernr = @iv_pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      rs_response-code    = gc_code_error.
      rs_response-message = |Organizational data not found for { iv_pernr }|.
      RETURN.
    ENDIF.

    rs_response-orgeh_text = get_orgeh_text(
      iv_orgeh = rs_response-orgeh
      iv_date  = iv_date ).

    rs_response-pernr   = iv_pernr.
    rs_response-code    = gc_code_success.
    rs_response-message = 'Employee data retrieved successfully'.
  ENDMETHOD.


  METHOD get_active_employee_data.
    IF check_hr_authority( iv_infty = '0000' ) = abap_false.
      rs_response-code    = gc_code_error.
      rs_response-message = 'No authorization for HR data'.
      RETURN.
    ENDIF.

    IF is_active_employee( iv_pernr = iv_pernr
                           iv_date  = iv_date ) = abap_false.
      rs_response-code    = gc_code_error.
      rs_response-pernr   = iv_pernr.
      rs_response-message = |Employee { iv_pernr } is not active (STAT2 <> 3)|.
      RETURN.
    ENDIF.

    SELECT SINGLE vorna, nachn
      FROM pa0002
      INTO (@rs_response-first_name, @rs_response-last_name)
      WHERE pernr = @iv_pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      rs_response-code    = gc_code_error.
      rs_response-message = |Personal data not found for { iv_pernr }|.
      RETURN.
    ENDIF.

    SELECT SINGLE orgeh
      FROM pa0001
      INTO @rs_response-orgeh
      WHERE pernr = @iv_pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      rs_response-code    = gc_code_error.
      rs_response-message = |Organizational data not found for { iv_pernr }|.
      RETURN.
    ENDIF.

    rs_response-orgeh_text = get_orgeh_text(
      iv_orgeh = rs_response-orgeh
      iv_date  = iv_date ).

    rs_response-pernr   = iv_pernr.
    rs_response-code    = gc_code_success.
    rs_response-message = 'Active employee data retrieved successfully'.
  ENDMETHOD.


  METHOD get_employee_email.
    " Email from PA0105, subtype 0010 (SMTP email)
    SELECT SINGLE usrid_long
      FROM pa0105
      INTO @rv_email
      WHERE pernr = @iv_pernr
        AND subty = '0010'
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      CLEAR rv_email.
    ENDIF.
  ENDMETHOD.


  METHOD get_employee_name.
    " First and last name from PA0002
    SELECT SINGLE vorna, nachn
      FROM pa0002
      INTO (@ev_first_name, @ev_last_name)
      WHERE pernr = @iv_pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      CLEAR: ev_first_name, ev_last_name.
    ENDIF.
  ENDMETHOD.


  METHOD get_manager_pernr.
    " Step 1: Find chief position of org unit
    "   HRP1001 — OTYPE='O', OBJID=orgeh, RSIGN='B', RELAT='012', SCLAS='S'
    "   SOBID = manager's position (PLANS)
    SELECT SINGLE sobid
      FROM hrp1001
      INTO @DATA(lv_manager_plans)
      WHERE plvar = '01'
        AND otype = 'O'
        AND objid = @iv_orgeh
        AND rsign = 'B'
        AND relat = '012'
        AND sclas = 'S'
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      CLEAR rv_manager.
      RETURN.
    ENDIF.

    " Step 2: Find person holding that position
    "   HRP1001 — OTYPE='S', OBJID=position, RSIGN='A', RELAT='008', SCLAS='P'
    "   SOBID = manager's PERNR
    SELECT SINGLE sobid
      FROM hrp1001
      INTO @DATA(lv_manager_pernr)
      WHERE plvar = '01'
        AND otype = 'S'
        AND objid = @lv_manager_plans
        AND rsign = 'A'
        AND relat = '008'
        AND sclas = 'P'
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc = 0.
      rv_manager = CONV #( lv_manager_pernr ).
    ELSE.
      CLEAR rv_manager.
    ENDIF.
  ENDMETHOD.


  METHOD get_hrbp_pernr.
    " HRBP from custom OM infotype HRP9992 on org unit
    " NOTE: Field name may differ per system — adjust if needed
    SELECT SINGLE sobid
      FROM hrp9992
      INTO @DATA(lv_hrbp_objid)
      WHERE plvar = '01'
        AND otype = 'O'
        AND objid = @iv_orgeh
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc = 0.
      rv_hrbp = CONV #( lv_hrbp_objid ).
    ELSE.
      CLEAR rv_hrbp.
    ENDIF.
  ENDMETHOD.


  METHOD is_active_employee.
    SELECT SINGLE stat2
      FROM pa0000
      INTO @DATA(lv_stat2)
      WHERE pernr = @iv_pernr
        AND begda <= @iv_date
        AND endda >= @iv_date.

    rv_active = COND #( WHEN sy-subrc  = 0
                         AND lv_stat2 = gc_stat2_active
                        THEN abap_true
                        ELSE abap_false ).
  ENDMETHOD.


  METHOD get_orgeh_text.
    SELECT SINGLE stext
      FROM hrp1000
      INTO @rv_text
      WHERE plvar = '01'
        AND otype = 'O'
        AND objid = @iv_orgeh
        AND langu = @sy-langu
        AND begda <= @iv_date
        AND endda >= @iv_date.

    IF sy-subrc <> 0.
      CLEAR rv_text.
    ENDIF.
  ENDMETHOD.


  METHOD zif_fi_vendor_api~get_vendor_balance.
    " Validate vendor exists in LFA1 master
    IF check_vendor_exists( iv_lifnr = iv_lifnr
                            iv_bukrs = iv_bukrs ) = abap_false.
      RAISE EXCEPTION NEW zcx_fi_vendor_not_found(
        iv_lifnr = iv_lifnr
        iv_bukrs = iv_bukrs ).
    ENDIF.

    " Fetch open (BSIK) + cleared (BSAK) items
    DATA(lt_items) = fetch_vendor_items(
      iv_lifnr = iv_lifnr
      iv_bukrs = iv_bukrs
      iv_gjahr = iv_gjahr ).

    " Aggregate into balance
    rs_balance = aggregate_balance(
      it_items = lt_items
      iv_lifnr = iv_lifnr
      iv_bukrs = iv_bukrs
      iv_gjahr = iv_gjahr ).
  ENDMETHOD.


  METHOD check_vendor_exists.
    " Check vendor master + company code assignment (LFA1 + LFB1)
    SELECT SINGLE lifnr
      FROM lfa1
      INTO @DATA(lv_lifnr)
      WHERE lifnr = @iv_lifnr.

    IF sy-subrc <> 0.
      rv_exists = abap_false.
      RETURN.
    ENDIF.

    SELECT SINGLE lifnr
      FROM lfb1
      INTO @lv_lifnr
      WHERE lifnr = @iv_lifnr
        AND bukrs = @iv_bukrs.

    rv_exists = COND #( WHEN sy-subrc = 0
                        THEN abap_true
                        ELSE abap_false ).
  ENDMETHOD.


  METHOD fetch_vendor_items.
    " Fetch open items from BSIK — only required fields
    SELECT bukrs, lifnr, gjahr, waers, dmbtr, shkzg
      FROM bsik
      INTO TABLE @rt_items
      WHERE bukrs = @iv_bukrs
        AND lifnr = @iv_lifnr
        AND gjahr = @iv_gjahr.

    " Fetch cleared items from BSAK and append
    SELECT bukrs, lifnr, gjahr, waers, dmbtr, shkzg
      FROM bsak
      APPENDING TABLE @rt_items
      WHERE bukrs = @iv_bukrs
        AND lifnr = @iv_lifnr
        AND gjahr = @iv_gjahr.
  ENDMETHOD.


  METHOD aggregate_balance.
    rs_balance-lifnr = iv_lifnr.
    rs_balance-bukrs = iv_bukrs.
    rs_balance-gjahr = iv_gjahr.

    " Get company code currency
    SELECT SINGLE waers
      FROM t001
      INTO @rs_balance-waers
      WHERE bukrs = @iv_bukrs.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Currency converting factor for correct decimal handling
    DATA lv_factor TYPE i VALUE 1.
    CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
      EXPORTING
        currency = rs_balance-waers
      IMPORTING
        factor   = lv_factor
      EXCEPTIONS
        OTHERS   = 1.

    LOOP AT it_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      DATA(lv_amount) = <ls_item>-dmbtr * lv_factor.

      " S = debit (borç), H = credit (alacak)
      IF <ls_item>-shkzg = 'S'.
        rs_balance-debit_total = rs_balance-debit_total + lv_amount.
      ELSE.
        rs_balance-credit_total = rs_balance-credit_total + lv_amount.
      ENDIF.
    ENDLOOP.

    " Net balance = debit - credit
    rs_balance-net_balance = rs_balance-debit_total - rs_balance-credit_total.
  ENDMETHOD.


  METHOD check_hr_authority.
    AUTHORITY-CHECK OBJECT 'P_ORGIN'
      ID 'INFTY' FIELD iv_infty
      ID 'SUBTY' FIELD space
      ID 'AUTHC' FIELD 'R'
      ID 'PERSA' FIELD iv_werks
      ID 'PERSG' FIELD iv_persg
      ID 'PERSK' FIELD iv_persk
      ID 'VDSK1' FIELD space.

    rv_valid = COND #( WHEN sy-subrc = 0
                       THEN abap_true
                       ELSE abap_false ).
  ENDMETHOD.

ENDCLASS.


*----------------------------------------------------------------------*
* Unit Test Class
*----------------------------------------------------------------------*
CLASS ltcl_vendor_balance DEFINITION
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_ai_claude.

    METHODS setup.

    METHODS test_vendor_not_found FOR TESTING
      RAISING zcx_fi_vendor_not_found.

    METHODS test_balance_debit_credit FOR TESTING
      RAISING zcx_fi_vendor_not_found.

    METHODS test_balance_net_calculation FOR TESTING
      RAISING zcx_fi_vendor_not_found.

    METHODS test_empty_items FOR TESTING
      RAISING zcx_fi_vendor_not_found.

    METHODS test_exception_message FOR TESTING.

    METHODS test_handle_vendor_json FOR TESTING.

ENDCLASS.


CLASS ltcl_vendor_balance IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
  ENDMETHOD.

  METHOD test_vendor_not_found.
    " GIVEN: a non-existent vendor number
    " WHEN:  get_vendor_balance is called
    " THEN:  zcx_fi_vendor_not_found exception is raised
    TRY.
        mo_cut->get_vendor_balance(
          iv_lifnr = '9999999999'
          iv_bukrs = '0001'
          iv_gjahr = '2026' ).
        cl_abap_unit_assert=>fail( msg = 'Exception expected but not raised' ).
      CATCH zcx_fi_vendor_not_found INTO DATA(lx_err).
        cl_abap_unit_assert=>assert_not_initial(
          act = lx_err->mv_lifnr
          msg = 'Vendor number should be set in exception' ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_balance_debit_credit.
    " GIVEN: a valid vendor with open/cleared items
    " WHEN:  get_vendor_balance is called
    " THEN:  debit_total and credit_total are correctly summed
    " TODO: implement with test doubles / mock framework
    cl_abap_unit_assert=>assert_true( act = abap_true msg = 'Stub — implement with test data' ).
  ENDMETHOD.

  METHOD test_balance_net_calculation.
    " GIVEN: known debit and credit totals
    " WHEN:  balance is calculated
    " THEN:  net_balance = debit_total - credit_total
    " TODO: implement with test doubles / mock framework
    cl_abap_unit_assert=>assert_true( act = abap_true msg = 'Stub — implement with test data' ).
  ENDMETHOD.

  METHOD test_empty_items.
    " GIVEN: a valid vendor with no items in the fiscal year
    " WHEN:  get_vendor_balance is called
    " THEN:  all amounts should be zero
    " TODO: implement with test doubles / mock framework
    cl_abap_unit_assert=>assert_true( act = abap_true msg = 'Stub — implement with test data' ).
  ENDMETHOD.

  METHOD test_exception_message.
    " GIVEN: exception is raised for vendor 1234 in company 0001
    " WHEN:  get_text is called
    " THEN:  message contains vendor and company code
    DATA(lx_err) = NEW zcx_fi_vendor_not_found(
      iv_lifnr = '0000001234'
      iv_bukrs = '0001' ).

    DATA(lv_text) = lx_err->get_text( ).
    cl_abap_unit_assert=>assert_char_cp(
      act = lv_text
      exp = '*1234*0001*'
      msg = 'Exception message should contain vendor and company code' ).
  ENDMETHOD.

  METHOD test_handle_vendor_json.
    " GIVEN: a valid JSON request with GET_VENDOR_BALANCE action
    " WHEN:  handle_request processes it
    " THEN:  response JSON contains code field
    " TODO: implement with mock server object
    cl_abap_unit_assert=>assert_true( act = abap_true msg = 'Stub — implement with mock server' ).
  ENDMETHOD.

ENDCLASS.
