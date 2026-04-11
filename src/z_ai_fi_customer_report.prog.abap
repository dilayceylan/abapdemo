*&---------------------------------------------------------------------*
*& Report:    Z_AI_FI_CUSTOMER_REPORT
*& Açıklama:  FI müşteri bilgileri ALV raporu
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
  " Default values set in selection screen include

START-OF-SELECTION.
  lcl_report=>run( ).
