*&---------------------------------------------------------------------*
*& Include:   Z_AI_FI_CUST_RPT_F01
*& Açıklama:  Local class tanımları ve implementasyonları
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Event handler class definition
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
* Main report class definition
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
* Event handler class implementation
*----------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_double_click.
    " Read selected row data
    DATA(lv_index) = e_row-index.
    READ TABLE gt_output ASSIGNING FIELD-SYMBOL(<ls_output>) INDEX lv_index.
    IF sy-subrc = 0.
      " Navigate to customer master display (XD03)
      SET PARAMETER ID 'KUN' FIELD <ls_output>-kunnr.
      SET PARAMETER ID 'BUK' FIELD <ls_output>-bukrs.
      CALL TRANSACTION 'XD03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.

  METHOD on_hotspot_click.
    " Read selected row for hotspot column
    DATA(lv_index) = e_row_id-index.
    READ TABLE gt_output ASSIGNING FIELD-SYMBOL(<ls_output>) INDEX lv_index.
    IF sy-subrc = 0.
      " Display customer detail message
      MESSAGE |{ TEXT-m03 }: { <ls_output>-kunnr } - { <ls_output>-name1 }| TYPE 'S'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Main report class implementation
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
    " Authority check for company code data
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD space
      ID 'ACTVT' FIELD '03'.

    IF sy-subrc <> 0.
      MESSAGE TEXT-m02 TYPE 'E'.
      RETURN.
    ENDIF.

    " Fetch customer master data with company code text
    " No SELECT * — only required fields (ATC 3.1)
    " No nested SELECT — using JOIN instead (ATC 3.1)
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
    " Build fieldcatalog explicitly via class method
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
        " Create ALV grid (list mode — no custom container needed)
        IF go_alv_grid IS NOT BOUND.
          go_alv_grid = NEW cl_gui_alv_grid(
            i_parent = cl_gui_container=>default_screen ).
        ENDIF.

        " Build fieldcatalog and layout via class methods
        DATA(lt_fieldcatalog) = build_fieldcatalog( ).
        DATA(ls_layout)       = build_layout( ).

        " Register event handler
        SET HANDLER lcl_event_handler=>on_double_click  FOR go_alv_grid.
        SET HANDLER lcl_event_handler=>on_hotspot_click FOR go_alv_grid.

        " Display ALV grid
        go_alv_grid->set_table_for_first_display(
          EXPORTING
            is_layout       = ls_layout
          CHANGING
            it_outtab       = gt_output
            it_fieldcatalog = lt_fieldcatalog ).

        " Force screen output for default_screen container
        WRITE space.

      CATCH cx_root INTO DATA(lx_root).
        MESSAGE lx_root->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
