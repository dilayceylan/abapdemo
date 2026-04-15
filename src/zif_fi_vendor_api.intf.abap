*&---------------------------------------------------------------------*
*& Interface: ZIF_FI_VENDOR_API
*& Açıklama:  FI Satıcı servis arayüzü
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*
INTERFACE zif_fi_vendor_api
  PUBLIC.

  " Vendor balance output structure
  TYPES: BEGIN OF ty_s_vendor_balance,
           lifnr       TYPE lifnr,        " Satıcı numarası
           bukrs       TYPE bukrs,        " Şirket kodu
           gjahr       TYPE gjahr,        " Mali yıl
           waers       TYPE waers,        " Para birimi
           debit_total TYPE wrbtr,        " Borç toplam
           credit_total TYPE wrbtr,       " Alacak toplam
           net_balance TYPE wrbtr,        " Net bakiye
         END OF ty_s_vendor_balance.

  " Vendor balance request structure (for JSON service)
  TYPES: BEGIN OF ty_s_vendor_request,
           action TYPE string,
           lifnr  TYPE lifnr,
           bukrs  TYPE bukrs,
           gjahr  TYPE gjahr,
         END OF ty_s_vendor_request.

  " Vendor balance response structure (for JSON service)
  TYPES: BEGIN OF ty_s_vendor_response,
           code    TYPE char1,
           message TYPE string,
           balance TYPE ty_s_vendor_balance,
         END OF ty_s_vendor_response.

  METHODS get_vendor_balance
    IMPORTING
      iv_lifnr          TYPE lifnr
      iv_bukrs          TYPE bukrs
      iv_gjahr          TYPE gjahr
    RETURNING
      VALUE(rs_balance) TYPE ty_s_vendor_balance
    RAISING
      zcx_fi_vendor_not_found.

ENDINTERFACE.
