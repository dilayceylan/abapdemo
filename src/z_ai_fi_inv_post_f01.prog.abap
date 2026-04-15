*&---------------------------------------------------------------------*
*& Include:   Z_AI_FI_INV_POST_F01
*& Aciklama:  Local class tanimlari ve implementasyonlari
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Ana islem sinifi — tanim
*----------------------------------------------------------------------*
CLASS lcl_invoice_post DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      run,
      check_authority
        RETURNING VALUE(rv_ok) TYPE abap_bool,
      read_excel
        RETURNING VALUE(rt_rows) TYPE ty_t_excel_rows,
      validate_rows
        IMPORTING it_rows    TYPE ty_t_excel_rows
        EXPORTING et_valid   TYPE ty_t_excel_rows
                  et_results TYPE ty_t_results,
      post_invoices
        IMPORTING it_rows TYPE ty_t_excel_rows
        CHANGING  ct_results TYPE ty_t_results,
      set_cell_colors,
      build_fieldcatalog
        RETURNING VALUE(rt_fcat) TYPE lvc_t_fcat,
      build_layout
        RETURNING VALUE(rs_layout) TYPE lvc_s_layo,
      display_alv.

  PRIVATE SECTION.
    CLASS-METHODS:
      is_vendor_valid
        IMPORTING iv_lifnr        TYPE lifnr
                  iv_bukrs        TYPE bukrs
        RETURNING VALUE(rv_valid) TYPE abap_bool,

      post_single_invoice
        IMPORTING is_row           TYPE ty_s_excel_row
        RETURNING VALUE(rs_result) TYPE ty_s_result,

      add_fcat_entry
        IMPORTING iv_fieldname       TYPE lvc_fname
                  iv_coltext         TYPE lvc_txtcol
                  iv_outputlen       TYPE lvc_outlen DEFAULT 12
        RETURNING VALUE(rs_fcat)     TYPE lvc_s_fcat.
ENDCLASS.

*----------------------------------------------------------------------*
* Ana islem sinifi — implementasyon
*----------------------------------------------------------------------*
CLASS lcl_invoice_post IMPLEMENTATION.

  METHOD run.
    " 1) Yetki kontrolu
    IF check_authority( ) = abap_false.
      MESSAGE TEXT-m01 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 2) Excel oku
    DATA(lt_rows) = read_excel( ).
    IF lt_rows IS INITIAL.
      MESSAGE TEXT-m02 TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " 3) Validasyon
    DATA lt_valid TYPE ty_t_excel_rows.
    validate_rows(
      EXPORTING it_rows    = lt_rows
      IMPORTING et_valid   = lt_valid
                et_results = gt_results ).

    " 4) Kayit (gecerli satirlar icin)
    IF lt_valid IS NOT INITIAL.
      post_invoices(
        EXPORTING it_rows    = lt_valid
        CHANGING  ct_results = gt_results ).
    ENDIF.

    " 5) Sonuc ALV
    IF gt_results IS NOT INITIAL.
      set_cell_colors( ).
      display_alv( ).
    ELSE.
      MESSAGE TEXT-m02 TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDMETHOD.


  METHOD check_authority.
    AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
      ID 'BUKRS' FIELD p_bukrs
      ID 'ACTVT' FIELD '01'.  " Kayit yetkisi

    rv_ok = COND #( WHEN sy-subrc = 0
                    THEN abap_true
                    ELSE abap_false ).
  ENDMETHOD.


  METHOD read_excel.
    " ALSM_EXCEL_TO_INTERNAL_TABLE ile Excel dosyasi oku
    DATA lt_excel TYPE TABLE OF alsmex_tabline.

    CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
      EXPORTING
        filename                = CONV rlgrap-filename( p_file )
        i_begin_col             = 1
        i_begin_row             = 2  " Baslik satirini atla
        i_end_col               = gc_max_excel_col
        i_end_row               = gc_max_excel_row
      TABLES
        intern                  = lt_excel
      EXCEPTIONS
        inconsistent_parameters = 1
        upload_ole              = 2
        OTHERS                  = 3.

    IF sy-subrc <> 0.
      MESSAGE TEXT-m03 TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " Ham veriyi yapisal tabloya donustur
    DATA ls_row TYPE ty_s_excel_row.
    DATA lv_prev_row TYPE i VALUE 0.

    SORT lt_excel BY row col.

    LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<ls_cell>).
      " Yeni satira gecis
      IF <ls_cell>-row <> lv_prev_row AND lv_prev_row > 0.
        APPEND ls_row TO rt_rows.
        CLEAR ls_row.
      ENDIF.

      lv_prev_row   = <ls_cell>-row.
      ls_row-row_no = <ls_cell>-row.

      " Sutun eslemesi: 1=tarih, 2=satici, 3=tutar, 4=PB,
      "                 5=vergi, 6=gider hesabi, 7=metin, 8=referans
      CASE <ls_cell>-col.
        WHEN 1.
          " Tarih: YYYYMMDD veya DD.MM.YYYY
          ls_row-bldat = <ls_cell>-value.
        WHEN 2.
          " Satici numarasi — sol sifir tamamlama
          ls_row-lifnr = |{ <ls_cell>-value ALPHA = IN }|.
        WHEN 3.
          ls_row-wrbtr = <ls_cell>-value.
        WHEN 4.
          ls_row-waers = <ls_cell>-value.
        WHEN 5.
          ls_row-mwskz = <ls_cell>-value.
        WHEN 6.
          ls_row-hkont = <ls_cell>-value.
        WHEN 7.
          ls_row-sgtxt = <ls_cell>-value.
        WHEN 8.
          ls_row-xblnr = <ls_cell>-value.
      ENDCASE.
    ENDLOOP.

    " Son satiri ekle
    IF ls_row-lifnr IS NOT INITIAL.
      APPEND ls_row TO rt_rows.
    ENDIF.
  ENDMETHOD.


  METHOD validate_rows.
    CLEAR: et_valid, et_results.

    " Satici numaralarini topla — toplu LFA1 sorgusu (LOOP icinde SELECT yok)
    DATA lt_lifnr TYPE SORTED TABLE OF lifnr WITH UNIQUE KEY table_line.
    LOOP AT it_rows ASSIGNING FIELD-SYMBOL(<ls_row>).
      INSERT <ls_row>-lifnr INTO TABLE lt_lifnr.
    ENDLOOP.

    " Toplu satici varlik kontrolu
    DATA lt_lfa1 TYPE SORTED TABLE OF lifnr WITH UNIQUE KEY table_line.
    IF lt_lifnr IS NOT INITIAL.
      SELECT lifnr
        FROM lfa1
        INTO TABLE @lt_lfa1
        FOR ALL ENTRIES IN @lt_lifnr
        WHERE lifnr = @lt_lifnr-table_line.
    ENDIF.

    " Her satiri dogrula
    LOOP AT it_rows ASSIGNING <ls_row>.
      DATA ls_result TYPE ty_s_result.
      CLEAR ls_result.
      ls_result-row_no = <ls_row>-row_no.
      ls_result-lifnr  = <ls_row>-lifnr.
      ls_result-wrbtr  = <ls_row>-wrbtr.
      ls_result-waers  = <ls_row>-waers.

      " Satici kontrolu — READ TABLE ile (SELECT degil)
      READ TABLE lt_lfa1 WITH TABLE KEY table_line = <ls_row>-lifnr
        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        ls_result-status  = gc_status_error.
        ls_result-message = TEXT-v01.  " Satici bulunamadi
        APPEND ls_result TO et_results.
        CONTINUE.
      ENDIF.

      " Tutar kontrolu
      IF <ls_row>-wrbtr <= 0.
        ls_result-status  = gc_status_error.
        ls_result-message = TEXT-v02.  " Tutar sifir veya negatif
        APPEND ls_result TO et_results.
        CONTINUE.
      ENDIF.

      " Tarih kontrolu
      IF <ls_row>-bldat IS INITIAL.
        ls_result-status  = gc_status_error.
        ls_result-message = TEXT-v03.  " Gecersiz tarih
        APPEND ls_result TO et_results.
        CONTINUE.
      ENDIF.

      " Para birimi kontrolu
      IF <ls_row>-waers IS INITIAL.
        ls_result-status  = gc_status_error.
        ls_result-message = TEXT-v04.  " Para birimi bos
        APPEND ls_result TO et_results.
        CONTINUE.
      ENDIF.

      " Gider hesabi kontrolu
      IF <ls_row>-hkont IS INITIAL.
        ls_result-status  = gc_status_error.
        ls_result-message = TEXT-v05.  " Gider hesabi bos
        APPEND ls_result TO et_results.
        CONTINUE.
      ENDIF.

      " Gecerli satir
      APPEND <ls_row> TO et_valid.
    ENDLOOP.
  ENDMETHOD.


  METHOD post_invoices.
    LOOP AT it_rows ASSIGNING FIELD-SYMBOL(<ls_row>).
      DATA(ls_result) = post_single_invoice( <ls_row> ).
      APPEND ls_result TO ct_results.
    ENDLOOP.
  ENDMETHOD.


  METHOD post_single_invoice.
    rs_result-row_no = is_row-row_no.
    rs_result-lifnr  = is_row-lifnr.
    rs_result-wrbtr  = is_row-wrbtr.
    rs_result-waers  = is_row-waers.

    " --- BAPI parametreleri ---

    " 1) Belge basligi (BAPIACHE09)
    DATA(ls_header) = VALUE bapiache09(
      obj_type   = gc_obj_type
      bus_act    = gc_bus_act
      username   = sy-uname
      comp_code  = p_bukrs
      doc_date   = is_row-bldat
      pstng_date = p_budat
      doc_type   = p_blart
      ref_doc_no = is_row-xblnr
      header_txt = is_row-sgtxt ).

    " 2) Satici hesap satiri (BAPIACAP09) — Kalem 1: Alacak
    DATA lt_ap TYPE STANDARD TABLE OF bapiacap09.
    APPEND VALUE bapiacap09(
      itemno_acc = '0000000001'
      vendor_no  = is_row-lifnr
      ) TO lt_ap.

    " 3) Defteri kebir satiri (BAPIACGL09) — Kalem 2: Borc (gider)
    DATA lt_gl TYPE STANDARD TABLE OF bapiacgl09.
    APPEND VALUE bapiacgl09(
      itemno_acc = '0000000002'
      gl_account = is_row-hkont
      item_text  = is_row-sgtxt
      tax_code   = is_row-mwskz
      ) TO lt_gl.

    " 4) Tutar satirlari (BAPIACCR09)
    DATA lt_curr TYPE STANDARD TABLE OF bapiaccr09.
    " Kalem 1: satici — alacak (negatif tutar = H)
    APPEND VALUE bapiaccr09(
      itemno_acc = '0000000001'
      currency   = is_row-waers
      amt_doccur = is_row-wrbtr * -1
      ) TO lt_curr.
    " Kalem 2: gider — borc (pozitif tutar = S)
    APPEND VALUE bapiaccr09(
      itemno_acc = '0000000002'
      currency   = is_row-waers
      amt_doccur = is_row-wrbtr
      ) TO lt_curr.

    " 5) BAPI cagir
    DATA lt_return TYPE STANDARD TABLE OF bapiret2.
    DATA lv_obj_key TYPE bapiache09-obj_key.

    CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
      EXPORTING
        documentheader = ls_header
      IMPORTING
        obj_key        = lv_obj_key
      TABLES
        accountgl      = lt_gl
        accountpayable = lt_ap
        currencyamount = lt_curr
        return         = lt_return.

    " 6) Sonuc degerlendirme
    READ TABLE lt_return ASSIGNING FIELD-SYMBOL(<ls_ret>)
      WITH KEY type = 'E'.

    IF sy-subrc = 0.
      " Hata var
      rs_result-status  = gc_status_error.
      rs_result-message = <ls_ret>-message.
      " Hatada rollback
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      " Basarili
      IF p_test = abap_true.
        " Test modu — commit yapma, rollback
        rs_result-status  = gc_status_success.
        rs_result-message = TEXT-m04.  " Test modu — belge olusturulmadi
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ELSE.
        " Gercek kayit — commit
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

        rs_result-belnr   = lv_obj_key(10).
        rs_result-gjahr   = lv_obj_key+14(4).
        rs_result-status  = gc_status_success.
        rs_result-message = TEXT-m05.  " Belge basariyla olusturuldu
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD is_vendor_valid.
    SELECT SINGLE lifnr
      FROM lfb1
      INTO @DATA(lv_lifnr)
      WHERE lifnr = @iv_lifnr
        AND bukrs = @iv_bukrs.

    rv_valid = COND #( WHEN sy-subrc = 0
                       THEN abap_true
                       ELSE abap_false ).
  ENDMETHOD.


  METHOD set_cell_colors.
    LOOP AT gt_results ASSIGNING FIELD-SYMBOL(<ls_result>).
      DATA lt_color TYPE lvc_t_scol.
      DATA ls_color TYPE lvc_s_scol.
      CLEAR: lt_color, ls_color.

      ls_color-fname     = 'STATUS'.
      ls_color-color-int = 1.

      IF <ls_result>-status = gc_status_error.
        ls_color-color-col = gc_color_red.
      ELSE.
        ls_color-color-col = gc_color_green.
      ENDIF.

      APPEND ls_color TO lt_color.
      <ls_result>-cellcolor = lt_color.
    ENDLOOP.
  ENDMETHOD.


  METHOD add_fcat_entry.
    rs_fcat-fieldname = iv_fieldname.
    rs_fcat-coltext   = iv_coltext.
    rs_fcat-outputlen = iv_outputlen.
  ENDMETHOD.


  METHOD build_fieldcatalog.
    APPEND add_fcat_entry( iv_fieldname = 'ROW_NO'
                           iv_coltext   = TEXT-c01
                           iv_outputlen = 6 ) TO rt_fcat.

    APPEND add_fcat_entry( iv_fieldname = 'LIFNR'
                           iv_coltext   = TEXT-c02
                           iv_outputlen = 10 ) TO rt_fcat.

    APPEND add_fcat_entry( iv_fieldname = 'WRBTR'
                           iv_coltext   = TEXT-c03
                           iv_outputlen = 16 ) TO rt_fcat.

    APPEND add_fcat_entry( iv_fieldname = 'WAERS'
                           iv_coltext   = TEXT-c04
                           iv_outputlen = 5 ) TO rt_fcat.

    APPEND add_fcat_entry( iv_fieldname = 'STATUS'
                           iv_coltext   = TEXT-c05
                           iv_outputlen = 6 ) TO rt_fcat.

    APPEND add_fcat_entry( iv_fieldname = 'BELNR'
                           iv_coltext   = TEXT-c06
                           iv_outputlen = 10 ) TO rt_fcat.

    APPEND add_fcat_entry( iv_fieldname = 'GJAHR'
                           iv_coltext   = TEXT-c07
                           iv_outputlen = 4 ) TO rt_fcat.

    APPEND add_fcat_entry( iv_fieldname = 'MESSAGE'
                           iv_coltext   = TEXT-c08
                           iv_outputlen = 60 ) TO rt_fcat.
  ENDMETHOD.


  METHOD build_layout.
    rs_layout-zebra      = abap_true.
    rs_layout-cwidth_opt = abap_true.
    rs_layout-sel_mode   = 'A'.
    rs_layout-ctab_fname = 'CELLCOLOR'.

    IF p_test = abap_true.
      rs_layout-grid_title = TEXT-t02.  " Test Modu Sonuclari
    ELSE.
      rs_layout-grid_title = TEXT-t01.  " Fatura Kayit Sonuclari
    ENDIF.
  ENDMETHOD.


  METHOD display_alv.
    TRY.
        IF go_alv_grid IS NOT BOUND.
          go_alv_grid = NEW cl_gui_alv_grid(
            i_parent = cl_gui_container=>default_screen ).
        ENDIF.

        DATA(lt_fcat)   = build_fieldcatalog( ).
        DATA(ls_layout) = build_layout( ).

        go_alv_grid->set_table_for_first_display(
          EXPORTING
            is_layout       = ls_layout
          CHANGING
            it_outtab       = gt_results
            it_fieldcatalog = lt_fcat ).

        WRITE space.

      CATCH cx_root INTO DATA(lx_root).
        MESSAGE lx_root->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
