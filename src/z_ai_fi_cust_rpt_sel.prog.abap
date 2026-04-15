*&---------------------------------------------------------------------*
*& Include:   Z_AI_FI_CUST_RPT_SEL
*& Açıklama:  Selection screen tanımları
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_bukrs FOR gv_bukrs OBLIGATORY,
                  s_kunnr FOR gv_kunnr,
                  s_ktokd FOR gv_ktokd.
  PARAMETERS:     p_keydt TYPE sy-datum OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b01.
