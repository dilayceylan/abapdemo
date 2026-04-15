*&---------------------------------------------------------------------*
*& Report:    Z_AI_FI_CUSTOMER_REPORT
*& Açıklama:  Müşteri açık kalem yaşlandırma analizi ALV raporu
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*& TR:        [Transport numarası]
*&---------------------------------------------------------------------*
REPORT z_ai_fi_customer_report.

INCLUDE z_ai_fi_cust_rpt_top.   " Tip ve veri tanımları
INCLUDE z_ai_fi_cust_rpt_sel.   " Selection screen
INCLUDE z_ai_fi_cust_rpt_f01.   " Local class ve iş mantığı

INITIALIZATION.
  p_keydt = sy-datum.

START-OF-SELECTION.
  lcl_report=>run( ).
