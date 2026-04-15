*&---------------------------------------------------------------------*
*& Include:   Z_AI_CUST_AGNT_RPT_TOP
*& Açıklama:  Tip tanımları, veri tanımları, sabitler
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*

" Yaşlandırma aralık sabitleri (gün)
CONSTANTS: gc_aging_30  TYPE i VALUE 30,
           gc_aging_60  TYPE i VALUE 60,
           gc_aging_90  TYPE i VALUE 90.

" ALV renk sabitleri
CONSTANTS: gc_color_red    TYPE i VALUE 6,  " C610 — kırmızı
           gc_color_yellow TYPE i VALUE 3.  " C310 — sarı

" Output structure for ALV
TYPES: BEGIN OF ty_s_output,
         kunnr       TYPE kunnr,        " Müşteri numarası
         name1       TYPE name1_gp,     " Müşteri adı
         bukrs       TYPE bukrs,        " Şirket kodu
         ktokd       TYPE ktokd,        " Hesap grubu
         waers       TYPE waers,        " Para birimi
         total_amt   TYPE wrbtr,        " Toplam borç
         not_due     TYPE wrbtr,        " Vadesi gelmemiş
         days_0_30   TYPE wrbtr,        " 0-30 gün
         days_31_60  TYPE wrbtr,        " 31-60 gün
         days_61_90  TYPE wrbtr,        " 61-90 gün
         days_over90 TYPE wrbtr,        " 90+ gün
         overdue_amt TYPE wrbtr,        " Toplam vade geçmiş
         cellcolor   TYPE lvc_t_scol,
       END OF ty_s_output,
       ty_t_output TYPE STANDARD TABLE OF ty_s_output WITH EMPTY KEY.

" BSID açık kalem yapısı
TYPES: BEGIN OF ty_s_bsid,
         bukrs TYPE bukrs,
         kunnr TYPE kunnr,
         waers TYPE waers,
         dmbtr TYPE dmbtr,
         shkzg TYPE shkzg,
         zfbdt TYPE dzfbdt,
         zbd1t TYPE dzbd1t,
         zbd2t TYPE dzbd2t,
         zbd3t TYPE dzbd3t,
         rebzg TYPE rebzg,
         rebzt TYPE rebzt,
       END OF ty_s_bsid,
       ty_t_bsid TYPE STANDARD TABLE OF ty_s_bsid WITH EMPTY KEY.

" KNA1 müşteri master yapısı
TYPES: BEGIN OF ty_s_kna1,
         kunnr TYPE kunnr,
         name1 TYPE name1_gp,
         ktokd TYPE ktokd,
       END OF ty_s_kna1,
       ty_t_kna1 TYPE STANDARD TABLE OF ty_s_kna1 WITH DEFAULT KEY.

" Global data
DATA: gt_output   TYPE ty_t_output,
      go_alv_grid TYPE REF TO cl_gui_alv_grid.

" Helper variables for selection screen references
DATA: gv_bukrs TYPE bukrs,
      gv_kunnr TYPE kunnr,
      gv_ktokd TYPE ktokd.
