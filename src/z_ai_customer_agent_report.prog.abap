*&---------------------------------------------------------------------*
*& Report:    Z_AI_CUSTOMER_AGENT_REPORT
*& Açıklama:  Müşteri açık kalem yaşlandırma analizi ALV raporu
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*& TR:        [Transport numarası]
*&---------------------------------------------------------------------*
REPORT z_ai_customer_agent_report.

INCLUDE z_ai_cust_agnt_rpt_top.   " Tip ve veri tanımları
INCLUDE z_ai_cust_agnt_rpt_sel.   " Selection screen
INCLUDE z_ai_cust_agnt_rpt_f01.   " Local class ve iş mantığı

INITIALIZATION.
  p_keydt = sy-datum.

START-OF-SELECTION.
  lcl_report=>run( ).
