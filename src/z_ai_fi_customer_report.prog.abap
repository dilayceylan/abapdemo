*&---------------------------------------------------------------------*
*& Report:    Z_AI_FI_CUSTOMER_REPORT
*& Açıklama:  FI müşteri bilgileri ALV raporu
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*
REPORT z_ai_fi_customer_report.

*----------------------------------------------------------------------*
* Constants
*----------------------------------------------------------------------*
CONSTANTS: gc_status_success TYPE char1 VALUE 'S',
           gc_status_error   TYPE char1 VALUE 'E'.

*----------------------------------------------------------------------*
* Type definitions
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_s_output,
         bukrs      TYPE bukrs,
         butxt      TYPE butxt,
         kunnr      TYPE kunnr,
         name1      TYPE name1_gp,
         ort01      TYPE ort01,
         pstlz      TYPE pstlz,
         land1      TYPE land1,
         stras      TYPE stras_gp,
         telf1      TYPE telf1,
         erdat      TYPE erdat,
         cellcolor  TYPE lvc_t_scol,
       END OF ty_s_output,
       ty_t_output TYPE STANDARD TABLE OF ty_s_output WITH EMPTY KEY.

*----------------------------------------------------------------------*
* Global data
*----------------------------------------------------------------------*
DATA: gt_output    TYPE ty_t_output,
      go_alv_grid  TYPE REF TO cl_gui_alv_grid.

DATA: gv_bukrs TYPE bukrs,
      gv_kunnr TYPE kunnr.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_bukrs FOR gv_bukrs,
                  s_kunnr FOR gv_kunnr.
SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* Event handler class
*----------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_double_click
        FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING e_row e_column,
      on_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id.
ENDCLASS.

*----------------------------------------------------------------------*
* Main report class
*----------------------------------------------------------------------*
CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      run,
      get_data,
      build_fieldcatalog
        RETURNING VALUE(rt_fieldcatalog) TYPE lvc_t_fcat,
      build_layout
        RETURNING VALUE(rs_layout) TYPE lvc_s_layo,
      display_alv.

  PRIVATE SECTION.
    CLASS-DATA:
      mt_output TYPE ty_t_output.
ENDCLASS.

*----------------------------------------------------------------------*
* Event handler implementation
*----------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_double_click.
    DATA(lv_index) = e_row-index.
    READ TABLE gt_output ASSIGNING FIELD-SYMBOL(<ls_output>) INDEX lv_index.
    IF sy-subrc = 0.
      SET PARAMETER ID 'KUN' FIELD <ls_output>-kunnr.
      SET PARAMETER ID 'BUK' FIELD <ls_output>-bukrs.
      CALL TRANSACTION 'XD03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.

  METHOD on_hotspot_click.
    DATA(lv_index) = e_row_id-index.
    READ TABLE gt_output ASSIGNING FIELD-SYMBOL(<ls_output>) INDEX lv_index.
    IF sy-subrc = 0.
      MESSAGE |{ TEXT-m03 }: { <ls_output>-kunnr } - { <ls_output>-name1 }| TYPE 'S'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Main report implementation
*----------------------------------------------------------------------*
CLASS lcl_report IMPLEMENTATION.

  METHOD run.
    get_data( ).
    IF mt_output IS NOT INITIAL.
      gt_output = mt_output.
      display_alv( ).
    ELSE.
      MESSAGE TEXT-m01 TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD space
      ID 'ACTVT' FIELD '03'.

    IF sy-subrc <> 0.
      MESSAGE TEXT-m02 TYPE 'E'.
      RETURN.
    ENDIF.

    SELECT kna1~kunnr,
           kna1~name1,
           kna1~ort01,
           kna1~pstlz,
           kna1~land1,
           kna1~stras,
           kna1~telf1,
           kna1~erdat,
           knb1~bukrs,
           t001~butxt
      FROM kna1
      INNER JOIN knb1 ON knb1~kunnr = kna1~kunnr
      INNER JOIN t001 ON t001~bukrs = knb1~bukrs
      INTO TABLE @mt_output
      WHERE knb1~bukrs IN @s_bukrs
        AND kna1~kunnr IN @s_kunnr.

    IF sy-subrc <> 0.
      CLEAR mt_output.
    ENDIF.

    SORT mt_output BY bukrs kunnr.
  ENDMETHOD.

  METHOD build_fieldcatalog.
    DATA ls_fieldcat TYPE lvc_s_fcat.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'BUKRS'.
    ls_fieldcat-coltext   = TEXT-c01.
    ls_fieldcat-outputlen = 6.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'BUTXT'.
    ls_fieldcat-coltext   = TEXT-c02.
    ls_fieldcat-outputlen = 25.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'KUNNR'.
    ls_fieldcat-coltext   = TEXT-c03.
    ls_fieldcat-outputlen = 10.
    ls_fieldcat-hotspot   = abap_true.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'NAME1'.
    ls_fieldcat-coltext   = TEXT-c04.
    ls_fieldcat-outputlen = 35.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'ORT01'.
    ls_fieldcat-coltext   = TEXT-c05.
    ls_fieldcat-outputlen = 25.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'PSTLZ'.
    ls_fieldcat-coltext   = TEXT-c06.
    ls_fieldcat-outputlen = 10.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'LAND1'.
    ls_fieldcat-coltext   = TEXT-c07.
    ls_fieldcat-outputlen = 5.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'STRAS'.
    ls_fieldcat-coltext   = TEXT-c08.
    ls_fieldcat-outputlen = 30.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'TELF1'.
    ls_fieldcat-coltext   = TEXT-c09.
    ls_fieldcat-outputlen = 16.
    APPEND ls_fieldcat TO rt_fieldcatalog.

    CLEAR ls_fieldcat.
    ls_fieldcat-fieldname = 'ERDAT'.
    ls_fieldcat-coltext   = TEXT-c10.
    ls_fieldcat-outputlen = 10.
    APPEND ls_fieldcat TO rt_fieldcatalog.
  ENDMETHOD.

  METHOD build_layout.
    rs_layout-zebra      = abap_true.
    rs_layout-cwidth_opt = abap_true.
    rs_layout-grid_title = TEXT-t01.
    rs_layout-sel_mode   = 'A'.
    rs_layout-ctab_fname = 'CELLCOLOR'.
  ENDMETHOD.

  METHOD display_alv.
    TRY.
        IF go_alv_grid IS NOT BOUND.
          go_alv_grid = NEW cl_gui_alv_grid(
            i_parent = cl_gui_container=>default_screen ).
        ENDIF.

        DATA(lt_fieldcatalog) = build_fieldcatalog( ).
        DATA(ls_layout)       = build_layout( ).

        SET HANDLER lcl_event_handler=>on_double_click  FOR go_alv_grid.
        SET HANDLER lcl_event_handler=>on_hotspot_click FOR go_alv_grid.

        go_alv_grid->set_table_for_first_display(
          EXPORTING
            is_layout       = ls_layout
          CHANGING
            it_outtab       = gt_output
            it_fieldcatalog = lt_fieldcatalog ).

        WRITE space.

      CATCH cx_root INTO DATA(lx_root).
        MESSAGE lx_root->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Program events
*----------------------------------------------------------------------*
INITIALIZATION.
  " Default values

START-OF-SELECTION.
  lcl_report=>run( ).
