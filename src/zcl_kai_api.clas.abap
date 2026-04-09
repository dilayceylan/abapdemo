class ZCL_KAI_API definition
  public
  final
  create public .

public section.

  interfaces IF_HTTP_EXTENSION .

  methods CONSTRUCTOR .
  class-methods GET_VEN_STATEMENT
    importing
      !IV_LIFNR type LIFNR optional
      !IV_BUKRS type BUKRS optional
      !IV_BEGDA type BEGDA optional
      !IV_ENDDA type ENDDA optional
      !IV_REVERSED type FINS_XREVERSED optional
    exporting
      !ET_DATA type ZAI_001_TT_STATEMENT
      !ET_RETURN type ZAI_001_ST_RETURN .
  class-methods GET_CUS_STATEMENT
    importing
      value(IV_KUNNR) type KUNNR optional
      value(IV_BUKRS) type BUKRS optional
      value(IV_BEGDA) type BEGDA optional
      value(IV_ENDDA) type ENDDA optional
      value(IV_REVERSED) type FINS_XREVERSED optional
    exporting
      value(ET_DATA) type ZAI_001_TT_STATEMENT
      value(ET_RETURN) type ZAI_001_ST_RETURN .
  class-methods GET_PARTNER
    importing
      value(IV_PARTNER) type BU_PARTNER optional
      value(IV_NAME) type BU_NAMEOR1 optional
    exporting
      value(ET_DATA) type ZAI_001_TT_PARTNER
      value(ET_RETURN) type ZAI_001_ST_RETURN .
  class-methods CRT_COMPLETE_WI
    importing
      value(IS_APPROVE) type ZAI_001_ST_COMPLETE_WI optional
    exporting
      value(ET_RETURN) type ZAI_001_ST_RETURN .
  class-methods CRT_INVOICE
    importing
      value(REQUEST) type ZAI_001_ST_INVOICE optional
    exporting
      value(ET_RETURN) type ZAI_001_ST_RETURN .
  class-methods GET_BP_CREDIT_LIMIT
    importing
      value(IV_PARTNER) type BU_PARTNER optional
      value(IV_CREDIT_SGMNT) type UKM_CREDIT_SGMNT optional
    exporting
      value(ET_CREDITLIMIT) type UKM_T_BP_CMS_MALUSDSP_OUT
      value(ET_RETURN) type ZAI_001_ST_RETURN .
  class-methods GET_INV_INBOX
    importing
      value(IV_UNAME) type SYUNAME optional
      value(IV_EMAIL) type AD_SMTPADR optional
    exporting
      value(ET_INBOX) type ZAI_001_TT_INBOX
      value(ET_WFAPP) type ZAI_001_TT_WFAPP
      value(ET_RETURN) type ZAI_001_ST_RETURN .
  class-methods GET_INV_POOL
    importing
      value(IV_BEGDA) type BEGDA optional
      value(IV_ENDDA) type ENDDA optional
    exporting
      value(ET_INVOICE) type ZAI_001_TT_INVOICE_POOL
      value(ET_RETURN) type BAPIRET2_T .
  class-methods GET_SALES_ORDER
    importing
      value(IV_BEGDA) type BEGDA optional
      value(IV_ENDDA) type ENDDA optional
    exporting
      value(ET_RETURN) type ZAI_001_ST_RETURN
      value(ET_SALESORDER) type ZAI_001_TT_SALES_ORDER .
protected section.

  class-methods SET_STATICS
    importing
      value(IV_HATA) type STRING optional
      value(IV_MESAJ) type STRING optional
    changing
      value(CV_JSON) type STRING optional .
private section.
ENDCLASS.



CLASS ZCL_KAI_API IMPLEMENTATION.


  method CONSTRUCTOR.
  endmethod.


  METHOD crt_complete_wi.
    CALL FUNCTION 'ZAI_001_FM_CRT_COMPLETE_WI'
      EXPORTING
        is_approve = is_approve
      IMPORTING
        et_return  = et_return.

  ENDMETHOD.


  METHOD crt_invoice.
    CALL FUNCTION 'ZAI_001_FM_CRT_INVOICE'
      EXPORTING
        request   = request
      IMPORTING
        et_return = et_return.

  ENDMETHOD.


  METHOD get_bp_credit_limit.

    CALL FUNCTION 'ZAI_001_FM_GET_BP_CREDIT_LIMIT'
      EXPORTING
        iv_partner      = iv_partner
        iv_credit_sgmnt = iv_credit_sgmnt
      IMPORTING
        et_creditlimit  = et_creditlimit
        et_return       = et_return.

  ENDMETHOD.


  METHOD GET_CUS_STATEMENT.

    CALL FUNCTION 'ZAI_001_FM_GET_CUS_STATEMENT'
      EXPORTING
        iv_kunnr    = iv_kunnr
        iv_bukrs    = iv_bukrs
        iv_begda    = iv_begda
        iv_endda    = iv_endda
        iv_reversed = iv_reversed
      IMPORTING
        et_data     = et_data
        et_return   = et_return.

  ENDMETHOD.


        METHOD get_inv_inbox.
          CALL FUNCTION 'ZAI_001_FM_GET_INV_INBOX'
            EXPORTING
              iv_uname  = iv_uname
              iv_email  = iv_email
            IMPORTING
              et_inbox  = et_inbox
              et_wfapp  = et_wfapp
              et_return = et_return.

        ENDMETHOD.


  METHOD get_inv_pool.

    CALL FUNCTION 'ZAI_001_FM_GET_INV_POOL'
      EXPORTING
        iv_begda   = iv_begda
        iv_endda   = iv_endda
      IMPORTING
        et_invoice = et_invoice
        et_return  = et_return.

  ENDMETHOD.


  METHOD get_partner.

    CALL FUNCTION 'ZAI_001_FM_GET_PARTNER'
      EXPORTING
        iv_partner = iv_partner
        iv_name    = iv_name
      IMPORTING
        et_data    = et_Data
        et_return  = et_return.

  ENDMETHOD.


  METHOD get_sales_order.

    CALL FUNCTION 'ZAI_001_FM_GET_SALES_ORDER'
      EXPORTING
        iv_begda      = iv_begda
        iv_endda      = iv_endda
      IMPORTING
        et_salesorder = et_salesorder
        et_return     = et_return.

  ENDMETHOD.


  METHOD get_ven_statement.

    CALL FUNCTION 'ZAI_001_FM_GET_VEN_STATEMENT'
      EXPORTING
        iv_lifnr    = iv_lifnr
        iv_bukrs    = iv_bukrs
        iv_begda    = iv_begda
        iv_endda    = iv_endda
        iv_reversed = iv_reversed
      IMPORTING
        et_data     = et_data
        et_return   = et_return.

  ENDMETHOD.


METHOD if_http_extension~handle_request.
*----------------------------------------------------------------------*

* Credit Limit Details Structure

*----------------------------------------------------------------------*

  TYPES: BEGIN OF ty_credit_limit_details,
           muhatap_numarasi             TYPE string,
           kredi_bolumu                 TYPE string,
           para_birimi_anahtari         TYPE string,
           borc_toplami                 TYPE string,
           kredi_limiti                 TYPE string,
           kredi_limiti_yuzde_kullanimi TYPE string,
           kredi_limiti_kredili_mevduat TYPE string,
           ikon                         TYPE string,
           hedge_edilen_borc            TYPE string,
           musteri_kredi_grubu          TYPE string,
           kredi_limit_hesap            TYPE string,
           blokaj                       TYPE string,
           ozel_ilgi_gerekli            TYPE string,
           blokaj_neden                 TYPE string,
           yeniden_gonderim_tarihi      TYPE string,
           risk_sinifi                  TYPE string,
           musteri_kredi_grubu_1        TYPE string,
           kredi_bolum_tanimi           TYPE string,
           muhatap_tanim                TYPE string,
           yoneten                      TYPE string,
           diger_sorumlular             TYPE string,
           teminatlar                   TYPE string,
           kredi_bolumu_para_birimi     TYPE string,
           kredi_donemi_icindeki_borc   TYPE string,
           kredi_ufku_bitisi            TYPE string,
           gun_cinsinden_kredi_ufku     TYPE string,
         END OF ty_credit_limit_details.
*----------------------------------------------------------------------*
* Credit Limit Wrapper Structure
*---------------------------------------------------------------------*
  TYPES: BEGIN OF ty_credit_limit,
           credit_limit_details TYPE ty_credit_limit_details,
         END OF ty_credit_limit.
*----------------------------------------------------------------------*
* Main Response Structure
*----------------------------------------------------------------------*
  TYPES: BEGIN OF ty_credit_limit_response,
           code         TYPE string,
           message      TYPE string,
           credit_limit TYPE ty_credit_limit,
         END OF ty_credit_limit_response.

  DATA: es_creditlimit_response TYPE ty_credit_limit_response.


  TYPES: BEGIN OF ty_pay,
           ivpartner       TYPE bu_partner,
           muhatapKodu     TYPE bu_partner,
           MusteriNumarasi TYPE bu_partner,
           SirketKodu      TYPE ukm_credit_sgmnt,
           SaticiNo        TYPE lifnr,
*           ivname         TYPE bu_nameor1,
           MusteriNo       TYPE bu_partner,
           BaslangicTarihi TYPE string,
           BitisTarihi     TYPE string,
           TersKayit       TYPE fins_xreversed,
           firmaAdi        TYPE bu_nameor1,
           ivlifnr         TYPE lifnr,
           ivbukrs         TYPE bukrs,
           ivbegda         TYPE char10,
           ivendda         TYPE char10,
           ivreversed      TYPE fins_xreversed,
           ivkunnr         TYPE kunnr,
           ivcreditsgmnt   TYPE ukm_credit_sgmnt,
           ivuname         TYPE syuname,
           ivemail         TYPE ad_smtpadr,
           eguid           TYPE medevguid,
           comment         TYPE comment,
           wiresult        TYPE string,
           approveruserid  TYPE pernr_D,
           approvermail    TYPE ad_smtpadr,
           xblnr           TYPE xblnr,
           lifnr           TYPE  lifnr,
           frstid          TYPE zsd007_e001,
           adduserid       TYPE pernr_d,
           addmail         TYPE  ad_smtpadr,
         END OF ty_pay.

  TYPES: BEGIN OF ty_statement_details,
           row_index                   TYPE string,
           sirket_kodu                 TYPE string,
           muhasebe_hesabi             TYPE string,
           musteri_adi                 TYPE string,
           belge_no                    TYPE string,
           belge_turu                  TYPE string,
           kalem_metni                 TYPE string,
           belge_tarihi                TYPE string,
           kayit_tarihi                TYPE string,
           borc                        TYPE string,
           alacak                      TYPE string,
           belge_para_birimi           TYPE string,
           borc_ulusal_para_birimi     TYPE string,
           alacak_ulusal_para_birimi   TYPE string,
           ulusal_para_birimi          TYPE string,
           net_odeme_vadesi            TYPE string,
           geciken_gun_sayisi          TYPE string,
           odeme_bilgisi               TYPE string,
           denklestirme_belge_no       TYPE string,
           odeme_kosullari_anahtari    TYPE string,
           odeme_blokaji_anahtari      TYPE string,
           goruntuleme_degerleme_farki TYPE string,
           kdv_gostergesi              TYPE string,
           bakiye                      TYPE string,
           bakiye_ulusal_para_birimi   TYPE string,
         END OF ty_statement_details.

  TYPES: tt_statement_details TYPE STANDARD TABLE OF ty_statement_details WITH EMPTY KEY.

  TYPES: BEGIN OF ty_statement_response,
           code              TYPE string,
           message           TYPE string,
           statement_details TYPE tt_statement_details,
         END OF ty_statement_response.

  DATA: es_customer_response TYPE ty_statement_response,
        ls_statement_detail  TYPE ty_statement_details,
        lv_index             TYPE i.

  DATA: et_partner    TYPE zai_001_tt_partner.
  DATA: et_return     TYPE zai_001_st_return.
  DATA: et_statement  TYPE zai_001_tt_statement.
  DATA: ls_request   	TYPE zai_001_st_invoice.
  DATA: lv_begda TYPE begda,
        lv_endda TYPE endda.

  DATA: lv_action  TYPE string.
  DATA: lt_data    TYPE REF TO data.
  DATA: lv_json    TYPE string.
  DATA: lv_request TYPE string.
  FIELD-SYMBOLS: <ft_response> TYPE ANY TABLE.
  DATA: lv_methot  TYPE string.
  DATA: lv_hata    TYPE string.
  DATA: lv_hatamsj TYPE string.
  DATA: ls_pay TYPE ty_pay.
  DATA: is_approve  TYPE zai_001_st_complete_wi.
  DATA: et_creditlimit TYPE ukm_t_bp_cms_malusdsp_out.

*->get partner data
  DATA: es_partner_json        TYPE zai_001_st_partner_demo2.
  DATA: et_partner_details     TYPE zai_001_tt_partner_demo.
  DATA: es_partner_details_Str TYPE zai_001_st_partner_demo.

  lv_action = server->request->get_header_field( name = '~request_method' ).
  IF lv_action NE 'POST'.
    lv_hata = 'Unexpected'.
    lv_hatamsj = 'Post metodu dışında kullanmayınız!'.
    CALL METHOD server->response->set_status( code = '405' reason = 'Method Not Allowed' ).
  ELSE.
    lv_action = server->request->get_header_field( name = '~path_info' ).
    TRANSLATE lv_action TO UPPER CASE.
    lv_methot = lv_action+1.

    CLEAR lv_request.
    lv_request = server->request->get_cdata( ).
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
                 IN lv_request WITH space.

    cl_fdt_json=>json_to_data(
        EXPORTING
          iv_json = lv_request
        CHANGING
          ca_data = ls_pay ).

    CASE lv_methot.
      WHEN 'GET_PARTNER'.
        CALL METHOD (lv_methot)
          EXPORTING
            iv_partner = ls_pay-muhatapKodu
            iv_name    = ls_pay-firmaAdi
          IMPORTING
            et_data    = et_partner
            et_return  = et_return.
        IF NOT et_partner[] IS INITIAL.

          es_partner_json-code    = et_return-code.
          es_partner_json-message = et_return-message.

          CLEAR : et_partner_details[].

          LOOP AT et_partner INTO DATA(ls_partner).

            es_partner_details_str-name       = ls_partner-name.
            es_partner_details_str-partner    = ls_partner-partner.
            es_partner_details_str-tax_number = ls_partner-taxnum.

            APPEND es_partner_details_str TO et_partner_details[].
            CLEAR : es_partner_details_str.

          ENDLOOP.

          es_partner_json-partner_details = et_partner_details.

          lv_json = /ui2/cl_json=>serialize(
            data        = es_partner_json
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
            compress    = abap_false ).
        ELSE.
          CLEAR  lv_json.
          lv_hata     = 'NoContent'.
          lv_hatamsj  = 'İstenilen veri bulunamamıştır.'.
        ENDIF.

      WHEN 'GET_VEN_STATEMENT'.
        ls_pay-ivbegda = ls_pay-baslangictarihi.
        ls_pay-ivendda = ls_pay-bitistarihi.

        IF ls_pay-ivbegda IS INITIAL.
          ls_pay-ivbegda = '0000-00-00'.
        ENDIF.

        IF ls_pay-ivendda IS INITIAL.
          ls_pay-ivendda = '0000-00-00'.
        ENDIF.

        CONCATENATE ls_pay-ivbegda+0(4)
                    ls_pay-ivbegda+5(2)
                    ls_pay-ivbegda+8(2)
               INTO lv_begda.

        CONCATENATE ls_pay-ivendda+0(4)
                    ls_pay-ivendda+5(2)
                    ls_pay-ivendda+8(2)
               INTO lv_endda.

        ls_pay-ivlifnr = ls_pay-saticino.
        ls_pay-ivbukrs = ls_pay-sirketkodu.
*        ls_pay-ivreversed = ls_pay-terskayit.

        CALL METHOD (lv_methot)
          EXPORTING
            iv_lifnr    = ls_pay-ivlifnr
            iv_bukrs    = ls_pay-ivbukrs
            iv_begda    = lv_begda
            iv_endda    = lv_endda
            iv_reversed = ls_pay-ivreversed
          IMPORTING
            et_data     = et_statement
            et_return   = et_Return.
        IF NOT et_statement IS INITIAL.

          es_customer_response-code = et_return-code.
          es_customer_response-message = et_return-message.

          LOOP AT et_statement INTO DATA(ls_stmt).
            lv_index = lv_index + 1.
            CLEAR: ls_statement_detail.
            ls_statement_detail-row_index                   = |{ lv_index }|.
            ls_statement_detail-sirket_kodu                 = ls_stmt-bukrs.
            ls_statement_detail-muhasebe_hesabi             = ls_stmt-hkont.
            ls_statement_detail-musteri_adi                 = ls_stmt-dname.
            ls_statement_detail-belge_no                    = ls_stmt-belnr.
            ls_statement_detail-belge_turu                  = ls_stmt-blart.
            ls_statement_detail-kalem_metni                 = ls_stmt-sgtxt.
            ls_statement_detail-belge_tarihi                = |{ ls_stmt-bldat DATE = ISO }|.
            ls_statement_detail-kayit_tarihi                = |{ ls_stmt-budat DATE = ISO }|.
            ls_statement_detail-borc                        = |{ ls_stmt-borc }|.
            ls_statement_detail-alacak                      = |{ ls_stmt-alacak }|.
            ls_statement_detail-belge_para_birimi           = ls_stmt-waers.
            ls_statement_detail-borc_ulusal_para_birimi     = |{ ls_stmt-borc_up }|.
            ls_statement_detail-alacak_ulusal_para_birimi   = |{ ls_stmt-alacak_up }|.
            ls_statement_detail-ulusal_para_birimi          = ls_stmt-waers_up.
            ls_statement_detail-net_odeme_vadesi            = |{ ls_stmt-faedt DATE = ISO }|.
            ls_statement_detail-geciken_gun_sayisi          = |{ ls_stmt-verzn }|.
            ls_statement_detail-odeme_bilgisi               = ls_stmt-zzodeme_bilgisi.
            ls_statement_detail-denklestirme_belge_no       = ls_stmt-augbl.
            ls_statement_detail-odeme_kosullari_anahtari    = ls_stmt-zterm.
            ls_statement_detail-odeme_blokaji_anahtari      = ls_stmt-zlspr.
            ls_statement_detail-goruntuleme_degerleme_farki = |{ ls_stmt-u_bwshb1 }|.
            ls_statement_detail-kdv_gostergesi              = ls_stmt-mwskz.
            ls_statement_detail-bakiye                      = |{ ls_stmt-tutar }|.
            ls_statement_detail-bakiye_ulusal_para_birimi   = |{ ls_stmt-tutar_up }|.
            APPEND ls_statement_detail TO es_customer_response-statement_details.
          ENDLOOP.

          lv_json = /ui2/cl_json=>serialize(
            data        = es_customer_response
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
            compress    = abap_false ).

*          camelCase → PascalCase dönüşümü (ilk harfi büyük yap)
          REPLACE ALL OCCURRENCES OF '"code"' IN lv_json WITH '"Code"'.
          REPLACE ALL OCCURRENCES OF '"message"' IN lv_json WITH '"Message"'.
          REPLACE ALL OCCURRENCES OF '"statementDetails"' IN lv_json WITH '"StatementDetails"'.
          REPLACE ALL OCCURRENCES OF '"rowIndex"' IN lv_json WITH '"RowIndex"'.
          REPLACE ALL OCCURRENCES OF '"sirketKodu"' IN lv_json WITH '"SirketKodu"'.
          REPLACE ALL OCCURRENCES OF '"muhasebeHesabi"' IN lv_json WITH '"MuhasebeHesabi"'.
          REPLACE ALL OCCURRENCES OF '"musteriAdi"' IN lv_json WITH '"MusteriAdi"'.
          REPLACE ALL OCCURRENCES OF '"belgeNo"' IN lv_json WITH '"BelgeNo"'.
          REPLACE ALL OCCURRENCES OF '"belgeTuru"' IN lv_json WITH '"BelgeTuru"'.
          REPLACE ALL OCCURRENCES OF '"kalemMetni"' IN lv_json WITH '"KalemMetni"'.
          REPLACE ALL OCCURRENCES OF '"belgeTarihi"' IN lv_json WITH '"BelgeTarihi"'.
          REPLACE ALL OCCURRENCES OF '"kayitTarihi"' IN lv_json WITH '"KayitTarihi"'.
          REPLACE ALL OCCURRENCES OF '"borc"' IN lv_json WITH '"Borc"'.
          REPLACE ALL OCCURRENCES OF '"alacak"' IN lv_json WITH '"Alacak"'.
          REPLACE ALL OCCURRENCES OF '"belgeParaBirimi"' IN lv_json WITH '"BelgeParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"borcUlusalParaBirimi"' IN lv_json WITH '"BorcUlusalParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"alacakUlusalParaBirimi"' IN lv_json WITH '"AlacakUlusalParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"ulusalParaBirimi"' IN lv_json WITH '"UlusalParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"netOdemeVadesi"' IN lv_json WITH '"NetOdemeVadesi"'.
          REPLACE ALL OCCURRENCES OF '"gecikenGunSayisi"' IN lv_json WITH '"GecikenGunSayisi"'.
          REPLACE ALL OCCURRENCES OF '"odemeBilgisi"' IN lv_json WITH '"OdemeBilgisi"'.
          REPLACE ALL OCCURRENCES OF '"denklestirmeBelgeNo"' IN lv_json WITH '"DenklestirmeBelgeNo"'.
          REPLACE ALL OCCURRENCES OF '"odemeKosullariAnahtari"' IN lv_json WITH '"OdemeKosullariAnahtari"'.
          REPLACE ALL OCCURRENCES OF '"odemeBlokajiAnahtari"' IN lv_json WITH '"OdemeBlokajiAnahtari"'.
          REPLACE ALL OCCURRENCES OF '"goruntulemeDegerlemeFarki"' IN lv_json WITH '"GoruntulemeDegerlemeFarki"'.
          REPLACE ALL OCCURRENCES OF '"kdvGostergesi"' IN lv_json WITH '"KdvGostergesi"'.
          REPLACE ALL OCCURRENCES OF '"bakiye"' IN lv_json WITH '"Bakiye"'.
          REPLACE ALL OCCURRENCES OF '"bakiyeUlusalParaBirimi"' IN lv_json WITH '"BakiyeUlusalParaBirimi"'.
        ELSE.
          CLEAR  lv_json.
          lv_hata     = 'NoContent'.
          lv_hatamsj  = 'İstenilen veri bulunamamıştır.'.
        ENDIF.
      WHEN 'GET_CUS_STATEMENT'.

        ls_pay-ivbegda = ls_pay-baslangictarihi.
        ls_pay-ivendda = ls_pay-bitistarihi.

        IF ls_pay-ivbegda IS INITIAL.
          ls_pay-ivbegda = '0000-00-00'.
        ENDIF.

        IF ls_pay-ivendda IS INITIAL.
          ls_pay-ivendda = '0000-00-00'.
        ENDIF.

        CONCATENATE ls_pay-ivbegda+0(4)
                    ls_pay-ivbegda+5(2)
                    ls_pay-ivbegda+8(2)
               INTO lv_begda.

        CONCATENATE ls_pay-ivendda+0(4)
                    ls_pay-ivendda+5(2)
                    ls_pay-ivendda+8(2)
               INTO lv_endda.

        ls_pay-ivkunnr = ls_pay-musterino.
        ls_pay-ivbukrs = ls_pay-sirketkodu.
        ls_pay-ivreversed = ls_pay-terskayit.

        CALL METHOD (lv_methot)
          EXPORTING
            iv_kunnr    = ls_pay-ivkunnr
            iv_bukrs    = ls_pay-ivbukrs
            iv_begda    = lv_begda
            iv_endda    = lv_endda
            iv_reversed = ls_pay-ivreversed
          IMPORTING
            et_data     = et_statement
            et_return   = et_Return.
        IF NOT et_statement IS INITIAL.

          es_customer_response-code = et_return-code.
          es_customer_response-message = et_return-message.

          CLEAR : ls_stmt.
          LOOP AT et_statement INTO ls_stmt.
            lv_index = lv_index + 1.
            CLEAR: ls_statement_detail.
            ls_statement_detail-row_index                   = |{ lv_index }|.
            ls_statement_detail-sirket_kodu                 = ls_stmt-bukrs.
            ls_statement_detail-muhasebe_hesabi             = ls_stmt-hkont.
            ls_statement_detail-musteri_adi                 = ls_stmt-dname.
            ls_statement_detail-belge_no                    = ls_stmt-belnr.
            ls_statement_detail-belge_turu                  = ls_stmt-blart.
            ls_statement_detail-kalem_metni                 = ls_stmt-sgtxt.
            ls_statement_detail-belge_tarihi                = |{ ls_stmt-bldat DATE = ISO }|.
            ls_statement_detail-kayit_tarihi                = |{ ls_stmt-budat DATE = ISO }|.
            ls_statement_detail-borc                        = |{ ls_stmt-borc }|.
            ls_statement_detail-alacak                      = |{ ls_stmt-alacak }|.
            ls_statement_detail-belge_para_birimi           = ls_stmt-waers.
            ls_statement_detail-borc_ulusal_para_birimi     = |{ ls_stmt-borc_up }|.
            ls_statement_detail-alacak_ulusal_para_birimi   = |{ ls_stmt-alacak_up }|.
            ls_statement_detail-ulusal_para_birimi          = ls_stmt-waers_up.
            ls_statement_detail-net_odeme_vadesi            = |{ ls_stmt-faedt DATE = ISO }|.
            ls_statement_detail-geciken_gun_sayisi          = |{ ls_stmt-verzn }|.
            ls_statement_detail-odeme_bilgisi               = ls_stmt-zzodeme_bilgisi.
            ls_statement_detail-denklestirme_belge_no       = ls_stmt-augbl.
            ls_statement_detail-odeme_kosullari_anahtari    = ls_stmt-zterm.
            ls_statement_detail-odeme_blokaji_anahtari      = ls_stmt-zlspr.
            ls_statement_detail-goruntuleme_degerleme_farki = |{ ls_stmt-u_bwshb1 }|.
            ls_statement_detail-kdv_gostergesi              = ls_stmt-mwskz.
            ls_statement_detail-bakiye                      = |{ ls_stmt-tutar }|.
            ls_statement_detail-bakiye_ulusal_para_birimi   = |{ ls_stmt-tutar_up }|.
            APPEND ls_statement_detail TO es_customer_response-statement_details.
          ENDLOOP.

          lv_json = /ui2/cl_json=>serialize(
            data        = es_customer_response
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
            compress    = abap_false ).

*          camelCase → PascalCase dönüşümü (ilk harfi büyük yap)
          REPLACE ALL OCCURRENCES OF '"code"' IN lv_json WITH '"Code"'.
          REPLACE ALL OCCURRENCES OF '"message"' IN lv_json WITH '"Message"'.
          REPLACE ALL OCCURRENCES OF '"statementDetails"' IN lv_json WITH '"StatementDetails"'.
          REPLACE ALL OCCURRENCES OF '"rowIndex"' IN lv_json WITH '"RowIndex"'.
          REPLACE ALL OCCURRENCES OF '"sirketKodu"' IN lv_json WITH '"SirketKodu"'.
          REPLACE ALL OCCURRENCES OF '"muhasebeHesabi"' IN lv_json WITH '"MuhasebeHesabi"'.
          REPLACE ALL OCCURRENCES OF '"musteriAdi"' IN lv_json WITH '"MusteriAdi"'.
          REPLACE ALL OCCURRENCES OF '"belgeNo"' IN lv_json WITH '"BelgeNo"'.
          REPLACE ALL OCCURRENCES OF '"belgeTuru"' IN lv_json WITH '"BelgeTuru"'.
          REPLACE ALL OCCURRENCES OF '"kalemMetni"' IN lv_json WITH '"KalemMetni"'.
          REPLACE ALL OCCURRENCES OF '"belgeTarihi"' IN lv_json WITH '"BelgeTarihi"'.
          REPLACE ALL OCCURRENCES OF '"kayitTarihi"' IN lv_json WITH '"KayitTarihi"'.
          REPLACE ALL OCCURRENCES OF '"borc"' IN lv_json WITH '"Borc"'.
          REPLACE ALL OCCURRENCES OF '"alacak"' IN lv_json WITH '"Alacak"'.
          REPLACE ALL OCCURRENCES OF '"belgeParaBirimi"' IN lv_json WITH '"BelgeParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"borcUlusalParaBirimi"' IN lv_json WITH '"BorcUlusalParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"alacakUlusalParaBirimi"' IN lv_json WITH '"AlacakUlusalParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"ulusalParaBirimi"' IN lv_json WITH '"UlusalParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"netOdemeVadesi"' IN lv_json WITH '"NetOdemeVadesi"'.
          REPLACE ALL OCCURRENCES OF '"gecikenGunSayisi"' IN lv_json WITH '"GecikenGunSayisi"'.
          REPLACE ALL OCCURRENCES OF '"odemeBilgisi"' IN lv_json WITH '"OdemeBilgisi"'.
          REPLACE ALL OCCURRENCES OF '"denklestirmeBelgeNo"' IN lv_json WITH '"DenklestirmeBelgeNo"'.
          REPLACE ALL OCCURRENCES OF '"odemeKosullariAnahtari"' IN lv_json WITH '"OdemeKosullariAnahtari"'.
          REPLACE ALL OCCURRENCES OF '"odemeBlokajiAnahtari"' IN lv_json WITH '"OdemeBlokajiAnahtari"'.
          REPLACE ALL OCCURRENCES OF '"goruntulemeDegerlemeFarki"' IN lv_json WITH '"GoruntulemeDegerlemeFarki"'.
          REPLACE ALL OCCURRENCES OF '"kdvGostergesi"' IN lv_json WITH '"KdvGostergesi"'.
          REPLACE ALL OCCURRENCES OF '"bakiye"' IN lv_json WITH '"Bakiye"'.
          REPLACE ALL OCCURRENCES OF '"bakiyeUlusalParaBirimi"' IN lv_json WITH '"BakiyeUlusalParaBirimi"'.

        ELSE.
          CLEAR  lv_json.
          lv_hata     = 'NoContent'.
          lv_hatamsj  = 'İstenilen veri bulunamamıştır.'.
        ENDIF.
      WHEN 'CRT_COMPLETE_WI'.

        MOVE-CORRESPONDING ls_pay TO is_approve.

        is_approve-approver_mail   = ls_pay-approvermail.
        is_approve-approver_userid = ls_pay-approveruserid.
        is_approve-wi_result       = ls_pay-wiresult.

        CALL METHOD (lv_methot)
          EXPORTING
            is_approve = is_approve
          IMPORTING
            et_return  = et_Return.
        IF NOT et_Return IS INITIAL.
          cl_fdt_json=>data_to_json(
              EXPORTING
                ia_data = et_Return
              RECEIVING
                rv_json = lv_json ).
        ELSE.
          CLEAR  lv_json.
          lv_hata     = 'NoContent'.
          lv_hatamsj  = 'İstenilen veri bulunamamıştır.'.
        ENDIF.
      WHEN 'CRT_INVOICE'.

        MOVE-CORRESPONDING ls_pay TO ls_request.
        ls_request-add_userid       = ls_pay-adduserid.
        ls_request-add_mail         = ls_pay-addmail.
        ls_request-approver_mail    = ls_pay-approvermail.
        ls_request-approver_userid  = ls_pay-approveruserid.

        CALL METHOD (lv_methot)
          EXPORTING
            request   = ls_request
          IMPORTING
            et_return = et_Return.
        IF NOT et_Return IS INITIAL.
          cl_fdt_json=>data_to_json(
              EXPORTING
                ia_data = et_Return
              RECEIVING
                rv_json = lv_json ).
        ELSE.
          CLEAR  lv_json.
          lv_hata     = 'NoContent'.
          lv_hatamsj  = 'İstenilen veri bulunamamıştır.'.
        ENDIF.

      WHEN 'GET_BP_CREDIT_LIMIT'.

        ls_pay-ivpartner     = ls_pay-musterinumarasi.
        ls_pay-ivcreditsgmnt = ls_pay-sirketkodu.

        CALL METHOD (lv_methot)
          EXPORTING
            iv_partner      = ls_pay-ivpartner
            iv_credit_sgmnt = ls_pay-ivcreditsgmnt
          IMPORTING
            et_creditlimit  = et_creditlimit
            et_return       = et_Return.
        IF NOT et_creditlimit IS INITIAL.
          es_creditlimit_response-code = et_return-code.
          es_creditlimit_response-message = et_return-message.
          LOOP AT et_creditlimit INTO DATA(es_creditlimit).
            " Credit Limit Details eşleme
            es_creditlimit_response-credit_limit-credit_limit_details-muhatap_numarasi             = es_creditlimit-partner.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_bolumu                 = es_creditlimit-credit_sgmnt.
            es_creditlimit_response-credit_limit-credit_limit_details-para_birimi_anahtari         = es_creditlimit-currency.
            es_creditlimit_response-credit_limit-credit_limit_details-borc_toplami                 = es_creditlimit-amount.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_limiti                 = es_creditlimit-credit_limit.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_limiti_yuzde_kullanimi = es_creditlimit-credit_limit_used.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_limiti_kredili_mevduat = es_creditlimit-credit_limit_usedw.
            es_creditlimit_response-credit_limit-credit_limit_details-ikon                         = es_creditlimit-icon.
            es_creditlimit_response-credit_limit-credit_limit_details-hedge_edilen_borc            = es_creditlimit-amount_sec.
            es_creditlimit_response-credit_limit-credit_limit_details-musteri_kredi_grubu          = es_creditlimit-cust_group.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_limit_hesap            = es_creditlimit-cred_lim_calc.
            es_creditlimit_response-credit_limit-credit_limit_details-blokaj                       = es_creditlimit-xblocked.
            es_creditlimit_response-credit_limit-credit_limit_details-ozel_ilgi_gerekli            = es_creditlimit-xcritical.
            es_creditlimit_response-credit_limit-credit_limit_details-blokaj_neden                 = es_creditlimit-block_reason.
            es_creditlimit_response-credit_limit-credit_limit_details-yeniden_gonderim_tarihi      = es_creditlimit-follow_up_dt.
            es_creditlimit_response-credit_limit-credit_limit_details-risk_sinifi                  = es_creditlimit-risk_class.
            es_creditlimit_response-credit_limit-credit_limit_details-musteri_kredi_grubu_1        = es_creditlimit-credit_group.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_bolum_tanimi           = es_creditlimit-credit_sgmnt_txt.
            es_creditlimit_response-credit_limit-credit_limit_details-muhatap_tanim                = es_creditlimit-descrip.
            es_creditlimit_response-credit_limit-credit_limit_details-yoneten                      = es_creditlimit-bp_coach.
            es_creditlimit_response-credit_limit-credit_limit_details-diger_sorumlular             = es_creditlimit-bp_coach_list.
            es_creditlimit_response-credit_limit-credit_limit_details-teminatlar                   = es_creditlimit-security_amnt.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_bolumu_para_birimi     = es_creditlimit-security_waers.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_donemi_icindeki_borc   = es_creditlimit-amount_dyn.
            es_creditlimit_response-credit_limit-credit_limit_details-kredi_ufku_bitisi            = es_creditlimit-horizon_date.
            es_creditlimit_response-credit_limit-credit_limit_details-gun_cinsinden_kredi_ufku     = es_creditlimit-horizon_days.
          ENDLOOP.
          " JSON'a dönüştür
          lv_json = /ui2/cl_json=>serialize(
          data        = es_creditlimit_response
          pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          compress    = abap_false ).
          " camelCase → PascalCase dönüşümü
          REPLACE ALL OCCURRENCES OF '"code"' IN lv_json WITH '"Code"'.
          REPLACE ALL OCCURRENCES OF '"message"' IN lv_json WITH '"Message"'.
          REPLACE ALL OCCURRENCES OF '"creditLimit"' IN lv_json WITH '"CreditLimit"'.
          REPLACE ALL OCCURRENCES OF '"creditLimitDetails"' IN lv_json WITH '"CreditLimitDetails"'.
          REPLACE ALL OCCURRENCES OF '"muhatapNumarasi"' IN lv_json WITH '"MuhatapNumarasi"'.
          REPLACE ALL OCCURRENCES OF '"krediBolumu"' IN lv_json WITH '"KrediBolumu"'.
          REPLACE ALL OCCURRENCES OF '"paraBirimiAnahtari"' IN lv_json WITH '"ParaBirimiAnahtari"'.
          REPLACE ALL OCCURRENCES OF '"borcToplami"' IN lv_json WITH '"BorcToplami"'.
          REPLACE ALL OCCURRENCES OF '"krediLimiti"' IN lv_json WITH '"KrediLimiti"'.
          REPLACE ALL OCCURRENCES OF '"krediLimitiYuzdeCinsindenKullanimi"' IN lv_json WITH '"KrediLimitiYuzdeCinsindenKullanimi"'.
          REPLACE ALL OCCURRENCES OF '"krediLimitiKrediliMevduatTutari"' IN lv_json WITH '"KrediLimitiKrediliMevduatTutari"'.
          REPLACE ALL OCCURRENCES OF '"ikon"' IN lv_json WITH '"Ikon"'.
          REPLACE ALL OCCURRENCES OF '"hedgeEdilenBorc"' IN lv_json WITH '"HedgeEdilenBorc"'.
          REPLACE ALL OCCURRENCES OF '"musteriKrediGrubu"' IN lv_json WITH '"MusteriKrediGrubu"'.
          REPLACE ALL OCCURRENCES OF '"krediLimitHesap"' IN lv_json WITH '"KrediLimitHesap"'.
          REPLACE ALL OCCURRENCES OF '"blokaj"' IN lv_json WITH '"Blokaj"'.
          REPLACE ALL OCCURRENCES OF '"ozelIlgiGerekli"' IN lv_json WITH '"OzelIlgiGerekli"'.
          REPLACE ALL OCCURRENCES OF '"blokajNeden"' IN lv_json WITH '"BlokajNeden"'.
          REPLACE ALL OCCURRENCES OF '"yenidenGonderimTarihi"' IN lv_json WITH '"YenidenGonderimTarihi"'.
          REPLACE ALL OCCURRENCES OF '"riskSinifi"' IN lv_json WITH '"RiskSinifi"'.
          REPLACE ALL OCCURRENCES OF '"musteriKrediGrubu1"' IN lv_json WITH '"MusteriKrediGrubu1"'.
          REPLACE ALL OCCURRENCES OF '"krediBolumTanimi"' IN lv_json WITH '"KrediBolumTanimi"'.
          REPLACE ALL OCCURRENCES OF '"muhatapTanim"' IN lv_json WITH '"MuhatapTanim"'.
          REPLACE ALL OCCURRENCES OF '"yoneten"' IN lv_json WITH '"Yoneten"'.
          REPLACE ALL OCCURRENCES OF '"digerSorumlular"' IN lv_json WITH '"DigerSorumlular"'.
          REPLACE ALL OCCURRENCES OF '"teminatlar"' IN lv_json WITH '"Teminatlar"'.
          REPLACE ALL OCCURRENCES OF '"krediBolumuParaBirimi"' IN lv_json WITH '"KrediBolumuParaBirimi"'.
          REPLACE ALL OCCURRENCES OF '"krediDonemiIcindekiBorc"' IN lv_json WITH '"KrediDonemiIcindekiBorc"'.
          REPLACE ALL OCCURRENCES OF '"krediUfkuBitisi"' IN lv_json WITH '"KrediUfkuBitisi"'.
          REPLACE ALL OCCURRENCES OF '"gunCinsindenKrediUfku"' IN lv_json WITH '"GunCinsindenKrediUfku"'.

*          cl_fdt_json=>data_to_json(
*            EXPORTING
*              ia_data = es_creditlimit_response
*            RECEIVING
*              rv_json = lv_json ).
        ELSE.
          CLEAR lv_json.
          lv_hata    = 'NoContent'.
          lv_hatamsj = 'İstenilen veri bulunamamıştır.'.
        ENDIF.

      WHEN 'GET_INV_INBOX'.
      WHEN 'GET_INV_POOL'.
      WHEN 'GET_SALES_ORDER'.
    ENDCASE.
  ENDIF.

  CALL METHOD server->response->set_header_field(
      name  = 'Content-Type'
      value = 'application/json; charset=iso-8859-1' ).
  server->response->set_cdata( lv_json ).
ENDMETHOD.


METHOD set_statics.
  IF iv_hata IS INITIAL.
    CONCATENATE '{'
              '"resultType":"Ok",'
              '"success":true,'
              '"messages":[],'
              '"data":'
              cv_json
              '}'
         INTO cv_json .
  ELSE.
    CLEAR cv_json.
    CONCATENATE '{'
              '"resultType":"' iv_hata '",'
              '"success":false,'
              '"messages":["'
              iv_mesaj '"],'
              '"data":null'
              '}'
         INTO cv_json .
  ENDIF.

ENDMETHOD.
ENDCLASS.
