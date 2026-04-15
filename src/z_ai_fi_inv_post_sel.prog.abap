*&---------------------------------------------------------------------*
*& Include:   Z_AI_FI_INV_POST_SEL
*& Aciklama:  Selection screen tanimlari
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*

" Dosya secimi
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  PARAMETERS: p_file TYPE rlgrap-filename.
SELECTION-SCREEN END OF BLOCK b01.

" Kayit parametreleri
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.
  PARAMETERS: p_bukrs TYPE bukrs    OBLIGATORY,
              p_bldat TYPE bldat    OBLIGATORY,
              p_budat TYPE budat    OBLIGATORY,
              p_blart TYPE blart    DEFAULT 'KR'.
SELECTION-SCREEN END OF BLOCK b02.

" Calistirma modu
SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-b03.
  PARAMETERS: p_test TYPE abap_bool AS CHECKBOX DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK b03.

" Ornek Excel indir butonu
SELECTION-SCREEN BEGIN OF BLOCK b04 WITH FRAME TITLE TEXT-b04.
  SELECTION-SCREEN PUSHBUTTON /1(40) pb_tmpl USER-COMMAND tmpl.
SELECTION-SCREEN END OF BLOCK b04.

" Dosya secim dialogu
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  DATA lt_file_table TYPE filetable.
  DATA lv_rc         TYPE i.
  DATA(lv_title)  = CONV string( TEXT-f01 ).
  DATA(lv_filter) = CONV string( |Excel (*.xlsx)\|*.xlsx\|{ TEXT-f02 } (*.*)\|*.*| ).

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title      = lv_title
      default_extension = 'XLSX'
      file_filter       = lv_filter
    CHANGING
      file_table        = lt_file_table
      rc                = lv_rc
    EXCEPTIONS
      OTHERS            = 1 ).

  IF sy-subrc = 0 AND lv_rc > 0.
    READ TABLE lt_file_table ASSIGNING FIELD-SYMBOL(<ls_file>) INDEX 1.
    IF sy-subrc = 0.
      p_file = <ls_file>-filename.
    ENDIF.
  ENDIF.
