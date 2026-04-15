*&---------------------------------------------------------------------*
*& Class:     ZCX_FI_VENDOR_NOT_FOUND
*& Açıklama:  Satıcı bulunamadı exception
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*
CLASS zcx_fi_vendor_not_found DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF vendor_not_found,
        msgid TYPE symsgid VALUE 'ZAI_CLAUDE_MSG',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'MV_LIFNR',
        attr2 TYPE scx_attrname VALUE 'MV_BUKRS',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF vendor_not_found.

    DATA mv_lifnr TYPE lifnr READ-ONLY.
    DATA mv_bukrs TYPE bukrs READ-ONLY.

    METHODS constructor
      IMPORTING
        iv_lifnr   TYPE lifnr OPTIONAL
        iv_bukrs   TYPE bukrs OPTIONAL
        !textid    LIKE if_t100_message=>t100key OPTIONAL
        !previous  LIKE previous OPTIONAL.

    METHODS get_text REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcx_fi_vendor_not_found IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).

    mv_lifnr = iv_lifnr.
    mv_bukrs = iv_bukrs.

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = vendor_not_found.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.

  METHOD get_text.
    result = |Vendor { mv_lifnr } not found in company code { mv_bukrs }|.
  ENDMETHOD.

ENDCLASS.
