*&---------------------------------------------------------------------*
*& Include:   Z_AI_FI_INV_POST_TOP
*& Aciklama:  Tip tanimlari, veri tanimlari, sabitler
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*

" Sabitler
CONSTANTS: gc_status_success TYPE char1    VALUE 'S',
           gc_status_error   TYPE char1    VALUE 'E',
           gc_doc_type       TYPE blart    VALUE 'KR',     " Satici faturasi
           gc_bus_act        TYPE bapiache09-bus_act VALUE 'RFBU',   " FI belge islemi
           gc_obj_type       TYPE bapiache09-obj_type VALUE 'BKPFF',
           gc_debit_credit_s TYPE shkzg    VALUE 'S',      " Soll / Borc
           gc_debit_credit_h TYPE shkzg    VALUE 'H',      " Haben / Alacak
           gc_posting_key_31 TYPE bschl    VALUE '31',     " Satici fatura
           gc_posting_key_40 TYPE bschl    VALUE '40',     " Borc kaydi
           gc_max_excel_row  TYPE i        VALUE 9999,
           gc_max_excel_col  TYPE i        VALUE 10.

" Excel'den okunan ham satir yapisi
TYPES: BEGIN OF ty_s_excel_row,
         row_no    TYPE i,            " Satir numarasi
         bldat     TYPE bldat,        " Belge tarihi
         lifnr     TYPE lifnr,        " Satici numarasi
         wrbtr     TYPE wrbtr,        " Tutar
         waers     TYPE waers,        " Para birimi
         mwskz     TYPE mwskz,        " Vergi kodu
         hkont     TYPE hkont,        " Gider hesabi
         sgtxt     TYPE sgtxt,        " Metin
         xblnr     TYPE xblnr,        " Referans belge no
       END OF ty_s_excel_row,
       ty_t_excel_rows TYPE STANDARD TABLE OF ty_s_excel_row WITH EMPTY KEY.

" Sonuc ALV yapisi
TYPES: BEGIN OF ty_s_result,
         row_no    TYPE i,            " Satir numarasi
         lifnr     TYPE lifnr,        " Satici numarasi
         wrbtr     TYPE wrbtr,        " Tutar
         waers     TYPE waers,        " Para birimi
         status    TYPE char1,        " S = Basarili, E = Hatali
         belnr     TYPE belnr_d,      " Olusturulan belge no
         gjahr     TYPE gjahr,        " Mali yil
         message   TYPE bapi_msg,     " Mesaj
         cellcolor TYPE lvc_t_scol,
       END OF ty_s_result,
       ty_t_results TYPE STANDARD TABLE OF ty_s_result WITH EMPTY KEY.

" ALV renk sabitleri
CONSTANTS: gc_color_green TYPE i VALUE 5,   " C510 — yesil (basarili)
           gc_color_red   TYPE i VALUE 6.   " C610 — kirmizi (hatali)

" Global data
DATA: gt_results  TYPE ty_t_results,
      go_alv_grid TYPE REF TO cl_gui_alv_grid.

" Selection screen referanslari
DATA: gv_file  TYPE string.
