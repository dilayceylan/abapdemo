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
      check_authority
        RETURNING VALUE(rv_ok) TYPE abap_bool,
      get_data,
      calculate_aging
        IMPORTING it_bsid TYPE ty_t_bsid
                  it_kna1 TYPE ty_t_kna1,
      set_cell_colors,
      build_fieldcatalog
        RETURNING VALUE(rt_fieldcatalog) TYPE lvc_t_fcat,
      build_layout
        RETURNING VALUE(rs_layout) TYPE lvc_s_layo,
      display_alv.

  PRIVATE SECTION.
    CLASS-METHODS:
      calculate_net_due_date
        IMPORTING is_bsid          TYPE ty_s_bsid
        RETURNING VALUE(rv_due_dt) TYPE sy-datum,
      add_fcat_entry
        IMPORTING iv_fieldname            TYPE lvc_fname
                  iv_coltext              TYPE lvc_txtcol
                  iv_outputlen            TYPE lvc_outlen DEFAULT 12
                  iv_do_sum               TYPE abap_bool DEFAULT abap_false
                  iv_hotspot              TYPE abap_bool DEFAULT abap_false
                  iv_cfieldname           TYPE lvc_cfname DEFAULT space
        RETURNING VALUE(rs_fcat)          TYPE lvc_s_fcat.
ENDCLASS.

*----------------------------------------------------------------------*
* Event handler class implementation
*----------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_hotspot_click.
    READ TABLE gt_output ASSIGNING FIELD-SYMBOL(<ls_output>)
      INDEX e_row_id-index.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Müşteri numarası hotspot — XD03'e navigasyon
    IF e_column_id-fieldname = 'KUNNR'.
      SET PARAMETER ID 'KUN' FIELD <ls_output>-kunnr.
      SET PARAMETER ID 'BUK' FIELD <ls_output>-bukrs.
      CALL TRANSACTION 'XD03' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Main report class implementation
*----------------------------------------------------------------------*
CLASS lcl_report IMPLEMENTATION.

  METHOD run.
    IF check_authority( ) = abap_false.
      MESSAGE TEXT-m02 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    get_data( ).

    IF gt_output IS NOT INITIAL.
      set_cell_colors( ).
      display_alv( ).
    ELSE.
      MESSAGE TEXT-m01 TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDMETHOD.

  METHOD check_authority.
    rv_ok = abap_false.
    LOOP AT s_bukrs ASSIGNING FIELD-SYMBOL(<ls_bukrs>).
      AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
        ID 'BUKRS' FIELD <ls_bukrs>-low
        ID 'ACTVT' FIELD '03'.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
    ENDLOOP.
    rv_ok = abap_true.
  ENDMETHOD.

  METHOD get_data.
    " BSID — müşteri açık kalemleri
    DATA lt_bsid TYPE ty_t_bsid.

    SELECT bukrs, kunnr, waers, dmbtr, shkzg,
           zfbdt, zbd1t, zbd2t, zbd3t, rebzg, rebzt
      FROM bsid
      INTO TABLE @lt_bsid
      WHERE bukrs IN @s_bukrs
        AND kunnr IN @s_kunnr.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " KNA1 — müşteri master verileri
    DATA lt_kna1 TYPE ty_t_kna1.

    SELECT kunnr, name1, ktokd
      FROM kna1
      INTO TABLE @lt_kna1
      FOR ALL ENTRIES IN @lt_bsid
      WHERE kunnr = @lt_bsid-kunnr
        AND ktokd IN @s_ktokd.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SORT lt_kna1 BY kunnr.

    calculate_aging( it_bsid = lt_bsid
                     it_kna1 = lt_kna1 ).
  ENDMETHOD.

  METHOD calculate_aging.
    DATA ls_output TYPE ty_s_output.

    LOOP AT it_bsid ASSIGNING FIELD-SYMBOL(<ls_bsid>).
      " Müşteri master'da olmayanları atla
      READ TABLE it_kna1 ASSIGNING FIELD-SYMBOL(<ls_kna1>)
        WITH KEY kunnr = <ls_bsid>-kunnr BINARY SEARCH.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " Net tutar hesabı (S = borç, H = alacak)
      DATA(lv_amount) = COND dmbtr(
        WHEN <ls_bsid>-shkzg = 'S' THEN <ls_bsid>-dmbtr
        ELSE <ls_bsid>-dmbtr * -1 ).

      " Net vade tarihi hesapla
      DATA(lv_due_date) = calculate_net_due_date( <ls_bsid> ).

      " Gecikme gün sayısı (key date'e göre)
      DATA(lv_overdue_days) = COND i(
        WHEN p_keydt > lv_due_date THEN p_keydt - lv_due_date
        ELSE 0 ).

      " Mevcut müşteri satırını bul veya yeni oluştur
      READ TABLE gt_output ASSIGNING FIELD-SYMBOL(<ls_out>)
        WITH KEY kunnr = <ls_bsid>-kunnr
                 bukrs = <ls_bsid>-bukrs.

      IF sy-subrc <> 0.
        CLEAR ls_output.
        ls_output-kunnr = <ls_bsid>-kunnr.
        ls_output-bukrs = <ls_bsid>-bukrs.
        ls_output-name1 = <ls_kna1>-name1.
        ls_output-ktokd = <ls_kna1>-ktokd.
        ls_output-waers = <ls_bsid>-waers.
        APPEND ls_output TO gt_output.

        READ TABLE gt_output ASSIGNING <ls_out>
          INDEX lines( gt_output ).
      ENDIF.

      " Toplam borç
      <ls_out>-total_amt = <ls_out>-total_amt + lv_amount.

      " Yaşlandırma sepetlerine dağıt
      IF lv_overdue_days = 0.
        <ls_out>-not_due = <ls_out>-not_due + lv_amount.
      ELSEIF lv_overdue_days <= gc_aging_30.
        <ls_out>-days_0_30 = <ls_out>-days_0_30 + lv_amount.
      ELSEIF lv_overdue_days <= gc_aging_60.
        <ls_out>-days_31_60 = <ls_out>-days_31_60 + lv_amount.
      ELSEIF lv_overdue_days <= gc_aging_90.
        <ls_out>-days_61_90 = <ls_out>-days_61_90 + lv_amount.
      ELSE.
        <ls_out>-days_over90 = <ls_out>-days_over90 + lv_amount.
      ENDIF.

      " Toplam vade geçmiş tutar
      IF lv_overdue_days > 0.
        <ls_out>-overdue_amt = <ls_out>-overdue_amt + lv_amount.
      ENDIF.
    ENDLOOP.

    SORT gt_output BY bukrs kunnr.
  ENDMETHOD.

  METHOD calculate_net_due_date.
    " Net vade tarihi: baseline date + en uzun ödeme koşulu
    rv_due_dt = is_bsid-zfbdt.

    IF rv_due_dt IS INITIAL.
      rv_due_dt = sy-datum.
      RETURN.
    ENDIF.

    " En uzun vade süresini al
    DATA(lv_days) = COND dzbd1t(
      WHEN is_bsid-zbd3t > 0 THEN is_bsid-zbd3t
      WHEN is_bsid-zbd2t > 0 THEN is_bsid-zbd2t
      WHEN is_bsid-zbd1t > 0 THEN is_bsid-zbd1t
      ELSE 0 ).

    rv_due_dt = rv_due_dt + lv_days.
  ENDMETHOD.

  METHOD set_cell_colors.
    LOOP AT gt_output ASSIGNING FIELD-SYMBOL(<ls_output>).
      DATA lt_color TYPE lvc_t_scol.
      DATA ls_color TYPE lvc_s_scol.
      CLEAR: lt_color, ls_color.

      " 90+ gün — kırmızı
      IF <ls_output>-days_over90 > 0.
        ls_color-fname     = 'DAYS_OVER90'.
        ls_color-color-col = gc_color_red.
        ls_color-color-int = 1.
        APPEND ls_color TO lt_color.
      ENDIF.

      " 61-90 gün — sarı
      IF <ls_output>-days_61_90 > 0.
        ls_color-fname     = 'DAYS_61_90'.
        ls_color-color-col = gc_color_yellow.
        ls_color-color-int = 1.
        APPEND ls_color TO lt_color.
      ENDIF.

      <ls_output>-cellcolor = lt_color.
    ENDLOOP.
  ENDMETHOD.

  METHOD add_fcat_entry.
    rs_fcat-fieldname  = iv_fieldname.
    rs_fcat-coltext    = iv_coltext.
    rs_fcat-outputlen  = iv_outputlen.
    rs_fcat-do_sum     = iv_do_sum.
    rs_fcat-hotspot    = iv_hotspot.
    rs_fcat-cfieldname = iv_cfieldname.
  ENDMETHOD.

  METHOD build_fieldcatalog.
    APPEND add_fcat_entry( iv_fieldname = 'KUNNR'
                           iv_coltext   = TEXT-c01
                           iv_outputlen = 10
                           iv_hotspot   = abap_true ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'NAME1'
                           iv_coltext   = TEXT-c02
                           iv_outputlen = 35 ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'BUKRS'
                           iv_coltext   = TEXT-c03
                           iv_outputlen = 6 ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'KTOKD'
                           iv_coltext   = TEXT-c04
                           iv_outputlen = 6 ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'WAERS'
                           iv_coltext   = TEXT-c05
                           iv_outputlen = 5 ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'TOTAL_AMT'
                           iv_coltext   = TEXT-c06
                           iv_outputlen = 18
                           iv_do_sum    = abap_true
                           iv_cfieldname = 'WAERS' ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'NOT_DUE'
                           iv_coltext   = TEXT-c07
                           iv_outputlen = 16
                           iv_do_sum    = abap_true
                           iv_cfieldname = 'WAERS' ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'DAYS_0_30'
                           iv_coltext   = TEXT-c08
                           iv_outputlen = 16
                           iv_do_sum    = abap_true
                           iv_cfieldname = 'WAERS' ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'DAYS_31_60'
                           iv_coltext   = TEXT-c09
                           iv_outputlen = 16
                           iv_do_sum    = abap_true
                           iv_cfieldname = 'WAERS' ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'DAYS_61_90'
                           iv_coltext   = TEXT-c10
                           iv_outputlen = 16
                           iv_do_sum    = abap_true
                           iv_cfieldname = 'WAERS' ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'DAYS_OVER90'
                           iv_coltext   = TEXT-c11
                           iv_outputlen = 16
                           iv_do_sum    = abap_true
                           iv_cfieldname = 'WAERS' ) TO rt_fieldcatalog.

    APPEND add_fcat_entry( iv_fieldname = 'OVERDUE_AMT'
                           iv_coltext   = TEXT-c12
                           iv_outputlen = 18
                           iv_do_sum    = abap_true
                           iv_cfieldname = 'WAERS' ) TO rt_fieldcatalog.
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

        SET HANDLER lcl_event_handler=>on_hotspot_click FOR go_alv_grid.

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
