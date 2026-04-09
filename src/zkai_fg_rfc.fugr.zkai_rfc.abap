FUNCTION zkai_rfc.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUKRS) TYPE  BUKRS OPTIONAL
*"     VALUE(IV_ADRC) TYPE  FLAG OPTIONAL
*"     VALUE(IV_KNA1) TYPE  FLAG OPTIONAL
*"     VALUE(IV_LFA1) TYPE  FLAG OPTIONAL
*"     VALUE(IV_KNB1) TYPE  FLAG OPTIONAL
*"     VALUE(IV_KNKK) TYPE  FLAG OPTIONAL
*"     VALUE(IV_KNVV) TYPE  FLAG OPTIONAL
*"     VALUE(IV_LFB1) TYPE  FLAG OPTIONAL
*"     VALUE(IV_LFBK) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BNKA) TYPE  FLAG OPTIONAL
*"     VALUE(IV_TIBAN) TYPE  FLAG OPTIONAL
*"     VALUE(IV_PAYR) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BUT000) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BUT020) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BUT0ID) TYPE  FLAG OPTIONAL
*"     VALUE(IV_DFKKBPTAXNUM) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BKPF) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BSEG) TYPE  FLAG OPTIONAL
*"     VALUE(IV_ACDOCA) TYPE  FLAG OPTIONAL
*"     VALUE(IV_FAGLFLEXA) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BSIS) TYPE  FLAG OPTIONAL
*"     VALUE(IV_ANLA) TYPE  FLAG OPTIONAL
*"     VALUE(IV_ANEP) TYPE  FLAG OPTIONAL
*"     VALUE(IV_ANEK) TYPE  FLAG OPTIONAL
*"     VALUE(IV_TCURR) TYPE  FLAG OPTIONAL
*"     VALUE(IV_BELNR) TYPE  BELNR_D OPTIONAL
*"     VALUE(IV_LAST_DOCNR) TYPE  DOCNR OPTIONAL
*"     VALUE(IV_PACKAGESIZE) TYPE  I DEFAULT 10000
*"     VALUE(IV_ADR6) TYPE  FLAG OPTIONAL
*"     VALUE(IV_ADR2) TYPE  FLAG OPTIONAL
*"     VALUE(IV_CMS_SGM) TYPE  FLAG OPTIONAL
*"     VALUE(IV_TOTALS) TYPE  FLAG OPTIONAL
*"     VALUE(IV_CMS) TYPE  FLAG OPTIONAL
*"     VALUE(IV_ITEM) TYPE  FLAG OPTIONAL
*"  TABLES
*"      ET_KNA1 STRUCTURE  KNA1 OPTIONAL
*"      ET_KNB1 STRUCTURE  KNB1 OPTIONAL
*"      ET_KNVV STRUCTURE  KNVV OPTIONAL
*"      ET_LFA1 STRUCTURE  LFA1 OPTIONAL
*"      ET_LFB1 STRUCTURE  LFB1 OPTIONAL
*"      ET_LFBK STRUCTURE  LFBK OPTIONAL
*"      ET_BNKA STRUCTURE  BNKA OPTIONAL
*"      ET_TIBAN STRUCTURE  TIBAN OPTIONAL
*"      ET_PAYR STRUCTURE  PAYR OPTIONAL
*"      ET_BUT000 STRUCTURE  BUT000 OPTIONAL
*"      ET_BUT020 STRUCTURE  BUT020 OPTIONAL
*"      ET_BUT0ID STRUCTURE  BUT0ID OPTIONAL
*"      ET_DFKKBPTAXNUM STRUCTURE  DFKKBPTAXNUM OPTIONAL
*"      ET_BKPF STRUCTURE  BKPF OPTIONAL
*"      ET_BSEG STRUCTURE  BSEG OPTIONAL
*"      ET_ACDOCA STRUCTURE  ACDOCA OPTIONAL
*"      ET_FAGLFLEXA STRUCTURE  FAGLFLEXA OPTIONAL
*"      ET_ANLA STRUCTURE  ANLA OPTIONAL
*"      ET_ANEP STRUCTURE  ANEP OPTIONAL
*"      ET_ANEK STRUCTURE  ANEK OPTIONAL
*"      ET_TCURR STRUCTURE  TCURR OPTIONAL
*"      ET_KNKK STRUCTURE  KNKK OPTIONAL
*"      ET_ADRC STRUCTURE  ADRC OPTIONAL
*"      ET_ADR6 STRUCTURE  ADR6 OPTIONAL
*"      ET_ADR2 STRUCTURE  ADR2 OPTIONAL
*"      ET_CMS_SGM STRUCTURE  UKMBP_CMS_SGM OPTIONAL
*"      ET_TOTALS STRUCTURE  UKM_TOTALS OPTIONAL
*"      ET_CMS STRUCTURE  UKMBP_CMS OPTIONAL
*"      ET_ITEM STRUCTURE  UKM_ITEM OPTIONAL
*"----------------------------------------------------------------------
*═══════════════════════════════════════════════════════════════════════
* MÜŞTERİ TABLOLARI
*═══════════════════════════════════════════════════════════════════════

  IF iv_tcurr EQ abap_true.
    SELECT *
      FROM tcurr
      INTO TABLE @et_tcurr.
  ENDIF.

  " KNA1 - Müşteri Genel Verileri
  IF iv_kna1 EQ abap_true.
    SELECT *
      FROM kna1
      INTO TABLE @et_kna1.
  ENDIF.

  " KNB1 - Müşteri Şirket Kodu Verileri
  IF iv_knb1 EQ abap_true.
    IF iv_bukrs IS NOT INITIAL.
      SELECT *
        FROM knb1
        INTO TABLE @et_knb1
        WHERE bukrs = @iv_bukrs.
    ELSE.
      SELECT *
        FROM knb1
        INTO TABLE @et_knb1.
    ENDIF.
  ENDIF.

  " KNVV - Müşteri Satış Alanı Verileri
  IF iv_knvv EQ abap_true.
    SELECT *
      FROM knvv
      INTO TABLE @et_knvv.
  ENDIF.

  IF iv_knkk EQ abap_true.
    SELECT *
      FROM knkk
      INTO TABLE @et_knkk.
  ENDIF.


  IF iv_cms_sgm EQ abap_true.
    SELECT *
    FROM ukmbp_cms_sgm
    INTO TABLE @et_cms_sgm.

  ENDIF.

  IF iv_totals EQ abap_true.
    SELECT *
    FROM ukm_totals
    INTO TABLE @et_totals.

  ENDIF.

  IF iv_cms EQ abap_true.
    SELECT *
   FROM ukmbp_cms
   INTO TABLE @et_cms.
  ENDIF.

  IF iv_item EQ abap_true.
    SELECT *
   FROM ukm_item
   INTO TABLE @et_item.
  ENDIF.

*═══════════════════════════════════════════════════════════════════════
* VENDOR TABLOLARI
*═══════════════════════════════════════════════════════════════════════

  " LFA1 - Vendor Genel Verileri
  IF iv_lfa1 EQ abap_true.
    SELECT *
      FROM lfa1
      INTO TABLE @et_lfa1.
  ENDIF.

  " LFB1 - Vendor Şirket Kodu Verileri
  IF iv_lfb1 EQ abap_true.
    IF iv_bukrs IS NOT INITIAL.
      SELECT *
        FROM lfb1
        INTO TABLE @et_lfb1
        WHERE bukrs = @iv_bukrs.
    ELSE.
      SELECT *
        FROM lfb1
        INTO TABLE @et_lfb1.
    ENDIF.
  ENDIF.

  " LFBK - Vendor Banka Bilgileri
  IF iv_lfbk EQ abap_true.
    SELECT *
      FROM lfbk
      INTO TABLE @et_lfbk.
  ENDIF.

  IF iv_adrc EQ abap_True.
    SELECT *
       FROM adrc
       INTO TABLE @et_adrc.
  ENDIF.

  IF iv_adr2 EQ abap_True.
    SELECT *
       FROM adr2
       INTO TABLE @et_adr2.
  ENDIF.

  IF iv_adr6 EQ abap_True.
    SELECT *
       FROM adr6
       INTO TABLE @et_adr6.
  ENDIF.

*═══════════════════════════════════════════════════════════════════════
* BANKA TABLOLARI
*═══════════════════════════════════════════════════════════════════════

  " BNKA - Banka Master Verileri
  IF iv_bnka EQ abap_true.
    SELECT *
      FROM bnka
      INTO TABLE @et_bnka.
  ENDIF.

  " TIBAN - IBAN Bilgileri
  IF iv_tiban EQ abap_true.
    SELECT *
      FROM tiban
      INTO TABLE @et_tiban.
  ENDIF.

  " PAYR - Ödeme Bilgileri
  IF iv_payr EQ abap_true.
    IF iv_bukrs IS NOT INITIAL.
      SELECT *
        FROM payr
        INTO TABLE @et_payr
        WHERE zbukr = @iv_bukrs.
    ELSE.
      SELECT *
        FROM payr
        INTO TABLE @et_payr.
    ENDIF.
  ENDIF.

*═══════════════════════════════════════════════════════════════════════
* BUSINESS PARTNER TABLOLARI
*═══════════════════════════════════════════════════════════════════════

  " BUT000 - BP Genel Bilgileri
  IF iv_but000 EQ abap_true.
    SELECT *
      FROM but000
      INTO TABLE @et_but000.
  ENDIF.

  " BUT020 - BP Adres Bilgileri
  IF iv_but020 EQ abap_true.
    SELECT *
      FROM but020
      INTO TABLE @et_but020.
  ENDIF.

  " BUT0ID - BP Kimlik Numaraları
  IF iv_but0id EQ abap_true.
    SELECT *
      FROM but0id
      INTO TABLE @et_but0id.
  ENDIF.

  CLEAR : et_dfkkbptaxnum.
  " DFKKBPTAXNUM - BP Vergi Numaraları
  IF iv_dfkkbptaxnum EQ abap_true.
    SELECT *
      FROM dfkkbptaxnum
      INTO TABLE @et_dfkkbptaxnum.
  ENDIF.

*═══════════════════════════════════════════════════════════════════════
* FI BELGE TABLOLARI
*═══════════════════════════════════════════════════════════════════════

  CLEAR : et_bkpf[].

  " BKPF - FI Belge Başlıkları
  IF iv_bkpf EQ abap_true.

    IF iv_belnr IS INITIAL.
      SELECT *
        FROM bkpf
        INTO TABLE @et_bkpf
        UP TO @iv_packagesize ROWS
        WHERE bukrs EQ @iv_bukrs
        ORDER BY belnr.
    ELSE.
      SELECT *
        UP TO @iv_packagesize ROWS
        FROM bkpf
        INTO TABLE @et_bkpf
        WHERE belnr GT @iv_belnr
         AND  bukrs EQ @iv_bukrs
         ORDER BY belnr.
    ENDIF.

  ENDIF.

  CLEAR : et_bseg[].

  " BSEG - FI Belge Kalemleri
  IF iv_bseg EQ abap_true.

    IF iv_belnr IS INITIAL.

      SELECT *
        FROM bseg
        INTO TABLE @et_bseg
        UP TO @iv_packagesize ROWS
        WHERE  bukrs EQ @iv_bukrs
        ORDER BY belnr.

    ELSE.

      SELECT *

        UP TO @iv_packagesize ROWS
        FROM bseg
        INTO TABLE @et_bseg
        WHERE belnr > @iv_belnr
        AND bukrs EQ @iv_bukrs
        ORDER BY belnr.

    ENDIF.
  ENDIF.

  CLEAR : et_acdoca[].
  " ACDOCA - Universal Journal (S/4HANA)
  IF iv_acdoca EQ abap_true.

    IF iv_belnr IS INITIAL.

      SELECT *
        UP TO @iv_packagesize ROWS
        FROM acdoca
        INTO TABLE @et_acdoca
        WHERE rbukrs = @iv_bukrs
        ORDER BY belnr.

    ELSE.

      SELECT *
        UP TO @iv_packagesize ROWS
        FROM acdoca
        INTO TABLE @et_acdoca
        WHERE rbukrs = @iv_bukrs
        AND belnr > @iv_belnr
        ORDER BY belnr.

    ENDIF.

  ENDIF.

  CLEAR : et_faglflexa[].
  " FAGLFLEXA - GL Flex Tablosu
  IF iv_faglflexa EQ abap_true.

    IF iv_last_docnr IS INITIAL.

      SELECT *
        UP TO @iv_packagesize ROWS
        FROM faglflexa
        INTO TABLE @et_faglflexa
         WHERE rbukrs = @iv_bukrs
        ORDER BY docnr.

    ELSE.

      SELECT *
        UP TO @iv_packagesize ROWS
        FROM faglflexa
        INTO TABLE @et_faglflexa
        WHERE docnr > @iv_last_docnr
         AND rbukrs = @iv_bukrs
      ORDER BY docnr.

    ENDIF.

  ENDIF.

*═══════════════════════════════════════════════════════════════════════
* GL AÇIK/KAPALI KALEMLER
*═══════════════════════════════════════════════════════════════════════

  " BSIS - GL Açık Kalemler
*  IF iv_bsis EQ abap_true.
*    IF iv_bukrs IS NOT INITIAL.
*      SELECT *
*        FROM bsis
*        INTO TABLE @et_bsis
*        WHERE bukrs = @iv_bukrs.
*    ELSE.
*      SELECT *
*        FROM bsis
*        INTO TABLE @et_bsis.
*    ENDIF.
*  ENDIF.
*
*  " BSAS - GL Kapalı Kalemler
*  IF iv_bsas EQ abap_true.
*    IF iv_bukrs IS NOT INITIAL.
*      SELECT *
*        FROM bsas
*        INTO TABLE @et_bsas
*        WHERE bukrs = @iv_bukrs.
*    ELSE.
*      SELECT *
*        FROM bsas
*        INTO TABLE @et_bsas.
*    ENDIF.
*  ENDIF.

*═══════════════════════════════════════════════════════════════════════
* MÜŞTERİ AÇIK/KAPALI KALEMLER
*═══════════════════════════════════════════════════════════════════════

*  " BSID - Müşteri Açık Kalemler
*  IF iv_bsid EQ abap_true.
*    IF iv_bukrs IS NOT INITIAL.
*      SELECT *
*        FROM bsid
*        INTO TABLE @et_bsid
*        WHERE bukrs = @iv_bukrs.
*    ELSE.
*      SELECT *
*        FROM bsid
*        INTO TABLE @et_bsid.
*    ENDIF.
*  ENDIF.
*
*  " BSAD - Müşteri Kapalı Kalemler
*  IF iv_bsad EQ abap_true.
*    IF iv_bukrs IS NOT INITIAL.
*      SELECT *
*        FROM bsad
*        INTO TABLE @et_bsad
*        WHERE bukrs = @iv_bukrs.
*    ELSE.
*      SELECT *
*        FROM bsad
*        INTO TABLE @et_bsad.
*    ENDIF.
*  ENDIF.
*
**═══════════════════════════════════════════════════════════════════════
** VENDOR AÇIK/KAPALI KALEMLER
**═══════════════════════════════════════════════════════════════════════
*
*  " BSIK - Vendor Açık Kalemler
*  IF iv_bsik EQ abap_true.
*    IF iv_bukrs IS NOT INITIAL.
*      SELECT *
*        FROM bsik
*        INTO TABLE @et_bsik
*        WHERE bukrs = @iv_bukrs.
*    ELSE.
*      SELECT *
*        FROM bsik
*        INTO TABLE @et_bsik.
*    ENDIF.
*  ENDIF.
*
*  " BSAK - Vendor Kapalı Kalemler
*  IF iv_bsak EQ abap_true.
*    IF iv_bukrs IS NOT INITIAL.
*      SELECT *
*        FROM bsak
*        INTO TABLE @et_bsak
*        WHERE bukrs = @iv_bukrs.
*    ELSE.
*      SELECT *
*        FROM bsak
*        INTO TABLE @et_bsak.
*    ENDIF.
*  ENDIF.

*═══════════════════════════════════════════════════════════════════════
* DURAN VARLIK TABLOLARI
*═══════════════════════════════════════════════════════════════════════

  " ANLA - Duran Varlık Master Verileri
  IF iv_anla EQ abap_true.
    IF iv_bukrs IS NOT INITIAL.
      SELECT *
        FROM anla
        INTO TABLE @et_anla
        WHERE bukrs = @iv_bukrs.
    ELSE.
      SELECT *
        FROM anla
        INTO TABLE @et_anla.
    ENDIF.
  ENDIF.

  " ANEP - Duran Varlık Dönemsel Değerler
  IF iv_anep EQ abap_true.
    IF iv_bukrs IS NOT INITIAL.
      SELECT *
        FROM anep
        INTO TABLE @et_anep
        WHERE bukrs = @iv_bukrs.
    ELSE.
      SELECT *
        FROM anep
        INTO TABLE @et_anep.
    ENDIF.
  ENDIF.

  " ANEK - Duran Varlık Belge Başlıkları
  IF iv_anek EQ abap_true.
    IF iv_bukrs IS NOT INITIAL.
      SELECT *
        FROM anek
        INTO TABLE @et_anek
        WHERE bukrs = @iv_bukrs.
    ELSE.
      SELECT *
        FROM anek
        INTO TABLE @et_anek.
    ENDIF.
  ENDIF.

ENDFUNCTION.
