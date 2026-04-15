CLASS zcl_ai_claude DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_extension .

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

    CONSTANTS: gc_code_success      TYPE char1 VALUE 'S',
               gc_code_error        TYPE char1 VALUE 'E',
               gc_action_employee   TYPE string VALUE 'GET_EMPLOYEE',
               gc_action_active     TYPE string VALUE 'GET_ACTIVE_EMPLOYEE',
               gc_action_onboarding TYPE string VALUE 'GET_ONBOARDING',
               gc_stat2_active      TYPE pa0000-stat2 VALUE '3',
               gc_date_type_hire    TYPE char2 VALUE '03'.

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

  PROTECTED SECTION.
  PRIVATE SECTION.

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

    DATA ls_request TYPE ty_s_employee_request.
    DATA lv_json TYPE string.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = lv_cdata
          CHANGING  data = ls_request ).

        " Validate date — required for all services
        IF ls_request-date IS INITIAL.
          lv_json = /ui2/cl_json=>serialize(
            data = VALUE ty_s_employee_response(
              code    = gc_code_error
              message = 'DATE is required' ) ).
        ELSE.
          " Route by action parameter
          CASE to_upper( ls_request-action ).

            WHEN gc_action_onboarding.
              " Onboarding service — requires date + day
              IF ls_request-day IS INITIAL.
                lv_json = /ui2/cl_json=>serialize(
                  data = VALUE ty_s_onboarding_response(
                    code    = gc_code_error
                    message = 'DAY parameter is required' ) ).
              ELSE.
                DATA(ls_onboard_resp) = get_onboarding_data(
                  iv_date = ls_request-date
                  iv_day  = ls_request-day ).
                lv_json = /ui2/cl_json=>serialize(
                  data        = ls_onboard_resp
                  compress    = abap_true
                  pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
              ENDIF.

            WHEN gc_action_active.
              IF ls_request-pernr IS INITIAL.
                lv_json = /ui2/cl_json=>serialize(
                  data = VALUE ty_s_active_emp_response(
                    code = gc_code_error  message = 'PERNR is required' ) ).
              ELSE.
                DATA(ls_active_resp) = get_active_employee_data(
                  iv_pernr = ls_request-pernr
                  iv_date  = ls_request-date ).
                lv_json = /ui2/cl_json=>serialize(
                  data        = ls_active_resp
                  compress    = abap_true
                  pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
              ENDIF.

            WHEN gc_action_employee OR space.
              IF ls_request-pernr IS INITIAL.
                lv_json = /ui2/cl_json=>serialize(
                  data = VALUE ty_s_employee_response(
                    code = gc_code_error  message = 'PERNR is required' ) ).
              ELSE.
                DATA(ls_emp_resp) = get_employee_data(
                  iv_pernr = ls_request-pernr
                  iv_date  = ls_request-date ).
                lv_json = /ui2/cl_json=>serialize(
                  data        = ls_emp_resp
                  compress    = abap_true
                  pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).
              ENDIF.

            WHEN OTHERS.
              lv_json = /ui2/cl_json=>serialize(
                data = VALUE ty_s_employee_response(
                  code    = gc_code_error
                  message = |Unknown action: { ls_request-action }| ) ).

          ENDCASE.
        ENDIF.

      CATCH cx_root INTO DATA(lx_root).
        lv_json = /ui2/cl_json=>serialize(
          data = VALUE ty_s_employee_response(
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
