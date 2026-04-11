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

    " Request structure for employee service
    TYPES: BEGIN OF ty_s_employee_request,
             pernr TYPE persno,
             date  TYPE begda,
           END OF ty_s_employee_request.

    CONSTANTS: gc_code_success TYPE char1 VALUE 'S',
               gc_code_error   TYPE char1 VALUE 'E'.

    METHODS get_employee_data
      IMPORTING
        iv_pernr           TYPE persno
        iv_date            TYPE begda
      RETURNING
        VALUE(rs_response) TYPE ty_s_employee_response.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS get_orgeh_text
      IMPORTING
        iv_orgeh       TYPE orgeh
        iv_date        TYPE begda
      RETURNING
        VALUE(rv_text) TYPE stext.

    METHODS check_hr_authority
      IMPORTING
        iv_infty        TYPE infty
        iv_werks        TYPE persa DEFAULT space
        iv_persg        TYPE persg DEFAULT space
        iv_persk        TYPE persk DEFAULT space
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

ENDCLASS.



CLASS zcl_ai_claude IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    " Read request data
    DATA(lv_cdata) = server->request->get_cdata( ).

    " Parse JSON request
    DATA ls_request TYPE ty_s_employee_request.
    DATA ls_response TYPE ty_s_employee_response.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json = lv_cdata
          CHANGING  data = ls_request ).

        " Validate input
        IF ls_request-pernr IS INITIAL.
          ls_response-code    = gc_code_error.
          ls_response-message = 'PERNR is required'.
        ELSEIF ls_request-date IS INITIAL.
          ls_response-code    = gc_code_error.
          ls_response-message = 'DATE is required'.
        ELSE.
          " Get employee data
          ls_response = get_employee_data(
            iv_pernr = ls_request-pernr
            iv_date  = ls_request-date ).
        ENDIF.

      CATCH cx_root INTO DATA(lx_root).
        ls_response-code    = gc_code_error.
        ls_response-message = lx_root->get_text( ).
    ENDTRY.

    " Build JSON response
    DATA(lv_json) = /ui2/cl_json=>serialize(
      data        = ls_response
      compress    = abap_true
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    " Set response
    server->response->set_cdata( lv_json ).
    server->response->set_header_field(
      name  = 'Content-Type'
      value = 'application/json' ).

    " Set HTTP status code
    IF ls_response-code = gc_code_success.
      server->response->set_status(
        code   = 200
        reason = 'OK' ).
    ELSE.
      server->response->set_status(
        code   = 400
        reason = 'Bad Request' ).
    ENDIF.

  ENDMETHOD.


  METHOD get_employee_data.
    " Authority check for HR data
    IF check_hr_authority( iv_infty = '0001' ) = abap_false.
      rs_response-code    = gc_code_error.
      rs_response-message = 'No authorization for HR data'.
      RETURN.
    ENDIF.

    " Fetch personal data (PA0002) — first name, last name
    " Only required fields, no SELECT * (ATC 3.1)
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

    " Fetch organizational data (PA0001) — ORGEH, STELL
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

    " Get org unit text from HRP1000
    rs_response-orgeh_text = get_orgeh_text(
      iv_orgeh = rs_response-orgeh
      iv_date  = iv_date ).

    " Set success response
    rs_response-pernr   = iv_pernr.
    rs_response-code    = gc_code_success.
    rs_response-message = 'Employee data retrieved successfully'.
  ENDMETHOD.


  METHOD get_orgeh_text.
    " Organization unit text from HRP1000
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
    " HR authorization check for infotype access
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
