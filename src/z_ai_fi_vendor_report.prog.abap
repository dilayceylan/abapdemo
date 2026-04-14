*&---------------------------------------------------------------------*
*& Report:    Z_AI_FI_VENDOR_REPORT
*& Açıklama:  FI satıcı bilgileri ALV raporu
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*
REPORT z_ai_fi_vendor_report.

*----------------------------------------------------------------------*
* Type definitions
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_s_output,
         lifnr TYPE lifnr,
         name1 TYPE name1_gp,
         name2 TYPE name2_gp,
         sortl TYPE sortl,
         stras TYPE stras_gp,
         ort01 TYPE ort01,
         pstlz TYPE pstlz,
         land1 TYPE land1,
         regio TYPE regio,
         telf1 TYPE telf1,
         telfx TYPE telfx,
         ktokk TYPE ktokk,
         bukrs TYPE bukrs,
         butxt TYPE butxt,
         akont TYPE akont,
         zterm TYPE dzterm,
         erdat TYPE erdat,
         ernam TYPE ernam,
         email TYPE ad_smtpadr,
       END OF ty_s_output,
       ty_t_output TYPE STANDARD TABLE OF ty_s_output WITH EMPTY KEY.

*----------------------------------------------------------------------*
* Global data
*----------------------------------------------------------------------*
DATA: gt_output   TYPE ty_t_output,
      go_alv_grid TYPE REF TO cl_gui_alv_grid.

DATA: gv_lifnr TYPE lifnr,
      gv_bukrs TYPE bukrs,
      gv_ktokk TYPE ktokk,
      gv_land1 TYPE land1.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_lifnr FOR gv_lifnr,
                  s_bukrs FOR gv_bukrs,
                  s_ktokk FOR gv_ktokk,
                  s_land1 FOR gv_land1.
SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* Event handler class — double click navigates to vendor master
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
      enrich_email,
      build_fieldcatalog
        RETURNING VALUE(rt_fieldcatalog) TYPE lvc_t_fcat,
      add_fieldcat
        IMPORTING
          iv_fieldname       TYPE lvc_fname
          iv_coltext         TYPE lvc_txtcol
          iv_outputlen       TYPE lvc_outlen
          iv_hotspot         TYPE abap_bool DEFAULT abap_false
        CHANGING
          ct_fieldcatalog    TYPE lvc_t_fcat,
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
      SET PARAMETER ID 'LIF' FIELD <ls_output>-lifnr.
      SET PARAMETER ID 'BUK' FIELD <ls_output>-bukrs.
      CALL TRANSACTION 'XK03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.

  METHOD on_hotspot_click.
    DATA(lv_index) = e_row_id-index.
    READ TABLE gt_output ASSIGNING FIELD-SYMBOL(<ls_output>) INDEX lv_index.
    IF sy-subrc = 0.
      MESSAGE |{ TEXT-m03 }: { <ls_output>-lifnr } - { <ls_output>-name1 }| TYPE 'S'.
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
      enrich_email( ).
      gt_output = mt_output.
      display_alv( ).
    ELSE.
      MESSAGE TEXT-m01 TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    " Vendor master + company code data + company text
    " JOIN ile tek sorguda — nested SELECT yok (ATC 3.1)
    SELECT lfa1~lifnr,
           lfa1~name1,
           lfa1~name2,
           lfa1~sortl,
           lfa1~stras,
           lfa1~ort01,
           lfa1~pstlz,
           lfa1~land1,
           lfa1~regio,
           lfa1~telf1,
           lfa1~telfx,
           lfa1~ktokk,
           lfa1~erdat,
           lfa1~ernam,
           lfb1~bukrs,
           lfb1~akont,
           lfb1~zterm,
           t001~butxt
      FROM lfa1
      INNER JOIN lfb1 ON lfb1~lifnr = lfa1~lifnr
      INNER JOIN t001 ON t001~bukrs = lfb1~bukrs
      WHERE lfa1~lifnr IN @s_lifnr
        AND lfb1~bukrs IN @s_bukrs
        AND lfa1~ktokk IN @s_ktokk
        AND lfa1~land1 IN @s_land1
      INTO CORRESPONDING FIELDS OF TABLE @mt_output.

    IF sy-subrc <> 0.
      CLEAR mt_output.
      RETURN.
    ENDIF.

    SORT mt_output BY bukrs lifnr.
  ENDMETHOD.

  METHOD enrich_email.
    " Email adresi ADR6 tablosundan — bulk fetch, LOOP içinde SELECT yok
    " Önce ADRNR'leri topla (LFA1'den)
    SELECT lifnr, adrnr
      FROM lfa1
      FOR ALL ENTRIES IN @mt_output
      WHERE lifnr = @mt_output-lifnr
      INTO TABLE @DATA(lt_lfa1_adr).

    IF lt_lfa1_adr IS INITIAL.
      RETURN.
    ENDIF.

    " ADR6'dan email adresleri — FOR ALL ENTRIES
    SELECT addrnumber, smtp_addr
      FROM adr6
      FOR ALL ENTRIES IN @lt_lfa1_adr
      WHERE addrnumber = @lt_lfa1_adr-adrnr
        AND flgdefault = 'X'
      INTO TABLE @DATA(lt_adr6).

    " Email'leri output'a eşleştir
    LOOP AT mt_output ASSIGNING FIELD-SYMBOL(<ls_output>).
      READ TABLE lt_lfa1_adr ASSIGNING FIELD-SYMBOL(<ls_adr>)
        WITH KEY lifnr = <ls_output>-lifnr.
      IF sy-subrc = 0.
        READ TABLE lt_adr6 ASSIGNING FIELD-SYMBOL(<ls_email>)
          WITH KEY addrnumber = <ls_adr>-adrnr.
        IF sy-subrc = 0.
          <ls_output>-email = <ls_email>-smtp_addr.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD build_fieldcatalog.
    add_fieldcat( EXPORTING iv_fieldname = 'LIFNR' iv_coltext = TEXT-c01 iv_outputlen = 10 iv_hotspot = abap_true CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'NAME1' iv_coltext = TEXT-c02 iv_outputlen = 35 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'NAME2' iv_coltext = TEXT-c03 iv_outputlen = 35 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'SORTL' iv_coltext = TEXT-c04 iv_outputlen = 10 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'ORT01' iv_coltext = TEXT-c05 iv_outputlen = 25 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'PSTLZ' iv_coltext = TEXT-c06 iv_outputlen = 10 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'LAND1' iv_coltext = TEXT-c07 iv_outputlen = 5  CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'REGIO' iv_coltext = TEXT-c08 iv_outputlen = 5  CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'STRAS' iv_coltext = TEXT-c09 iv_outputlen = 30 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'TELF1' iv_coltext = TEXT-c10 iv_outputlen = 16 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'TELFX' iv_coltext = TEXT-c11 iv_outputlen = 16 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'EMAIL' iv_coltext = TEXT-c12 iv_outputlen = 40 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'KTOKK' iv_coltext = TEXT-c13 iv_outputlen = 6  CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'BUKRS' iv_coltext = TEXT-c14 iv_outputlen = 6  CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'BUTXT' iv_coltext = TEXT-c15 iv_outputlen = 25 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'AKONT' iv_coltext = TEXT-c16 iv_outputlen = 10 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'ZTERM' iv_coltext = TEXT-c17 iv_outputlen = 6  CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'ERDAT' iv_coltext = TEXT-c18 iv_outputlen = 10 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
    add_fieldcat( EXPORTING iv_fieldname = 'ERNAM' iv_coltext = TEXT-c19 iv_outputlen = 12 CHANGING ct_fieldcatalog = rt_fieldcatalog ).
  ENDMETHOD.

  METHOD add_fieldcat.
    DATA ls_fc TYPE lvc_s_fcat.
    ls_fc-fieldname = iv_fieldname.
    ls_fc-coltext   = iv_coltext.
    ls_fc-outputlen = iv_outputlen.
    ls_fc-hotspot   = iv_hotspot.
    APPEND ls_fc TO ct_fieldcatalog.
  ENDMETHOD.

  METHOD build_layout.
    rs_layout-zebra      = abap_true.
    rs_layout-cwidth_opt = abap_true.
    rs_layout-grid_title = TEXT-t01.
    rs_layout-sel_mode   = 'A'.
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
