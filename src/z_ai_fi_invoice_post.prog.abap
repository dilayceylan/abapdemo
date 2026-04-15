*&---------------------------------------------------------------------*
*& Report:    Z_AI_FI_INVOICE_POST
*& Aciklama:  Excel'den toplu satici faturasi kaydi
*&            BAPI_ACC_DOCUMENT_POST ile FI belge olusturma
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*
REPORT z_ai_fi_invoice_post.

INCLUDE z_ai_fi_inv_post_top.   " Tip ve veri tanimlari
INCLUDE z_ai_fi_inv_post_sel.   " Selection screen
INCLUDE z_ai_fi_inv_post_f01.   " Local class ve is mantigi

INITIALIZATION.
  p_bldat  = sy-datum.
  p_budat  = sy-datum.
  pb_tmpl  = TEXT-b05.  " Ornek Excel Sablonu Indir

START-OF-SELECTION.
  lcl_invoice_post=>run( ).
