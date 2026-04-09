*&---------------------------------------------------------------------*
*& Report ZKAI_FI_DATA_MASKING
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zkai_fi_data_masking.
*&---------------------------------------------------------------------*
*& SELECTION SCREEN - Parametre Girişleri
*&---------------------------------------------------------------------*
*& Açıklama: S/4HANA FI Demo Sistem Veri Maskeleme Programı
*&
*& Fonksiyon: RFC ile uzak sistemden veri çeker, karakterleri scramble
*&            ederek maskeler ve yerel sisteme kaydeder.
*&
*& Karakter Dönüşüm Kuralları:
*& - Harfler : A→X, B→Y, C→Z, ... (alfabe ters çevrilmiş)
*& - Rakamlar: 0→9, 1→8, 2→7, ... (rakamlar ters çevrilmiş)
*& - Türkçe  : Ç→Z, Ğ→S, İ→Q, Ö→K, Ş→G, Ü→E
*& - Özel    : Boşluk, nokta, tire vb. değişmez
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& GLOBAL DATA DECLARATIONS
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_log,
         table_name   TYPE tabname,
         record_count TYPE i,
         status       TYPE char10,
         message      TYPE char100,
         timestamp    TYPE timestamp,
       END OF ty_log.

DATA: gt_log           TYPE TABLE OF ty_log,
      gv_total_records TYPE i,
      gv_success_count TYPE i,
      gv_error_count   TYPE i.

" Blok 1: RFC Bağlantı Parametreleri
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_rfc   TYPE rfcdest OBLIGATORY DEFAULT 'FINBTR@KAICLNT400',           " RFC Destination (SM59'da tanımlı)
    p_bukrs TYPE bukrs  OBLIGATORY. " Şirket kodu
SELECTION-SCREEN END OF BLOCK b1.

" Blok 2: Çalışma Modu
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_test   TYPE abap_bool AS CHECKBOX DEFAULT abap_true,  " Test modu (kaydetme)
    p_sample TYPE char50.                                    " Örnek dönüşüm test
  PARAMETERS:
   " Master Data Tabloları
   p_job  TYPE abap_bool AS CHECKBOX . "DEFAULT abap_true.
SELECTION-SCREEN END OF BLOCK b2.

" Blok 3: Maskelenecek Tablo Grupları
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS:
    " FI Belge Tabloları
    p_tcurr  TYPE abap_Bool AS CHECKBOX,
    p_acdoca TYPE abap_bool AS CHECKBOX,  " ACDOCA - Universal Journal
    p_bkpf   TYPE abap_bool AS CHECKBOX,  " BKPF - Belge Başlıkları
    p_bseg   TYPE abap_bool AS CHECKBOX,  " BSEG - Belge Kalemleri
    p_bsxx   TYPE abap_bool AS CHECKBOX,  " BSIS/BSAS/BSIK/BSAK/BSID/BSAD
    p_fagl   TYPE abap_bool AS CHECKBOX.  " FAGLFLEXA
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-004.
  PARAMETERS:
    " Master Data Tabloları
    p_knkk  TYPE abap_bool AS CHECKBOX,
    p_cust  TYPE abap_bool AS CHECKBOX  DEFAULT abap_true,  " KNA1/KNB1/KNVV
    p_vend  TYPE abap_bool AS CHECKBOX,  " LFA1/LFB1/LFBK
    p_bank  TYPE abap_bool AS CHECKBOX,  " BNKA/TIBAN
    p_asset TYPE abap_bool AS CHECKBOX,  " ANLA/ANEP/ANEK
    p_bp    TYPE abap_bool AS CHECKBOX,  " BUT000/BUT0ID/DFKKBPTAXNUM
    p_adrs  TYPE abap_bool AS CHECKBOX,
    p_clmt  TYPE abap_bool AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b4.


*&---------------------------------------------------------------------*
*& TEXT ELEMENTS
*&---------------------------------------------------------------------*
*TEXT-001: rfc Bağlantı Ayarları
*TEXT-002: çalışma Modu
*TEXT-003: fi Belge Tabloları
*TEXT-004: Master Data Tabloları
*TEXT-005: işlem Başlatıldı
*TEXT-006: Dönüşüm örnekleri
*&---------------------------------------------------------------------*
*& INITIALIZATION - Başlangıç Ayarları
*&---------------------------------------------------------------------*
INITIALIZATION.
  " Varsayılan değerler ayarlanabilir
*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN - Parametre Kontrolleri
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.
  " RFC bağlantı kontrolü
  IF p_rfc IS INITIAL.
    MESSAGE 'RFC Destination girilmelidir!' TYPE 'E'.
  ENDIF.
*&---------------------------------------------------------------------*
*& START-OF-SELECTION - Ana İşlem
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  " Örnek dönüşüm testi
  IF p_sample IS NOT INITIAL.
    PERFORM show_sample_test USING p_sample.
  ENDIF.

  " Dönüşüm kurallarını göster
*  PERFORM show_conversion_rules.

  IF p_job NE 'X'.

    " Örnek dönüşümler tablosu
    PERFORM show_sample_transformations.

    " Kullanıcı onayı (gerçek modda)
    IF p_test = abap_false.
      PERFORM get_user_confirmation.
    ENDIF.

    " İşlem başlangıç bilgisi
    PERFORM show_start_info.

  ENDIF.

  " Maskeleme işlemlerini çalıştır
  PERFORM execute_masking.

  IF p_job NE 'X'.
    " Sonuçları göster
    PERFORM show_results.

    " Özet istatistikleri göster
    PERFORM show_summary.

    " Final mesajı göster
    PERFORM show_final_message.
  ENDIF.

*&---------------------------------------------------------------------*
*& FORM show_sample_test
*&---------------------------------------------------------------------*
*& Kullanıcının girdiği örnek metni dönüştürüp gösterir
*&---------------------------------------------------------------------*
FORM show_sample_test USING pv_input TYPE char50.
  DATA: lv_output TYPE string.

  PERFORM scramble_text USING pv_input CHANGING lv_output.

  ULINE.
  WRITE: / '╔══════════════════════════════════════════════════════════╗'.
  WRITE: / '║             ÖRNEK DÖNÜŞÜM TESTİ                          ║'.
  WRITE: / '╠══════════════════════════════════════════════════════════╣'.
  WRITE: / |║ Orijinal : { pv_input WIDTH = 45 }║|.
  WRITE: / |║ Scrambled: { lv_output WIDTH = 45 }║|.
  WRITE: / '╚══════════════════════════════════════════════════════════╝'.
  ULINE.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM show_conversion_rules
*&---------------------------------------------------------------------*
*& Karakter dönüşüm kurallarını ekrana yazdırır
*&---------------------------------------------------------------------*
FORM show_conversion_rules.
  WRITE: / '┌────────────────────────────────────────────────────────────┐'.
  WRITE: / '│                KARAKTER DÖNÜŞÜM KURALLARI                  │'.
  WRITE: / '├────────────────────────────────────────────────────────────┤'.
  WRITE: / '│ HARFLER : A→X, B→Y, C→Z, D→W, E→V, F→T, G→S, H→R, I→Q ...  │'.
  WRITE: / '│ RAKAMLAR: 0→9, 1→8, 2→7, 3→6, 4→5, 5→4, 6→3, 7→2, 8→1, 9→0 │'.
  WRITE: / '│ TÜRKÇE  : Ç→Z, Ğ→S, İ→Q, Ö→K, Ş→G, Ü→E                     │'.
  WRITE: / '│ ÖZEL    : Boşluk, @, ., -, / vb. → Değişmez                │'.
  WRITE: / '└────────────────────────────────────────────────────────────┘'.
  SKIP.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM show_sample_transformations
*&---------------------------------------------------------------------*
*& Örnek dönüşümleri tablo halinde gösterir
*&---------------------------------------------------------------------*
FORM show_sample_transformations.
  DATA: lv_out1 TYPE string,
        lv_out2 TYPE string,
        lv_out3 TYPE string,
        lv_out4 TYPE string,
        lv_out5 TYPE string,
        lv_out6 TYPE string,
        lv_out7 TYPE string.

  PERFORM scramble_text   USING 'Ahmet Yılmaz'         CHANGING lv_out1.
  PERFORM scramble_text   USING 'Istanbul'             CHANGING lv_out2.
  PERFORM scramble_number USING '05321234567'          CHANGING lv_out3.
  PERFORM scramble_iban   USING 'TR330006100519786457' CHANGING lv_out4.
  PERFORM scramble_email  USING 'ahmet@firma.com'      CHANGING lv_out5.
  PERFORM scramble_text   USING 'Fatura No: ABC-123'   CHANGING lv_out6.
  PERFORM partial_mask    USING '12345678901' 2 2      CHANGING lv_out7.

  WRITE: / '┌──────────────────────────────┬──────────────────────────────┐'.
  WRITE: / '│          ORİJİNAL            │          SCRAMBLED           │'.
  WRITE: / '├──────────────────────────────┼──────────────────────────────┤'.
  WRITE: / |│ { 'Ahmet Yılmaz' WIDTH = 28 } │ { lv_out1 WIDTH = 28 } │|.
  WRITE: / |│ { 'Istanbul' WIDTH = 28 } │ { lv_out2 WIDTH = 28 } │|.
  WRITE: / |│ { '05321234567' WIDTH = 28 } │ { lv_out3 WIDTH = 28 } │|.
  WRITE: / |│ { 'TR330006100519786457' WIDTH = 28 } │ { lv_out4 WIDTH = 28 } │|.
  WRITE: / |│ { 'ahmet@firma.com' WIDTH = 28 } │ { lv_out5 WIDTH = 28 } │|.
  WRITE: / |│ { 'Fatura No: ABC-123' WIDTH = 28 } │ { lv_out6 WIDTH = 28 } │|.
  WRITE: / |│ { '12345678901 (TC Kimlik)' WIDTH = 28 } │ { lv_out7 WIDTH = 28 } │|.
  WRITE: / '└──────────────────────────────┴──────────────────────────────┘'.
  SKIP.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM get_user_confirmation
*&---------------------------------------------------------------------*
*& Gerçek modda kullanıcıdan onay alır
*&---------------------------------------------------------------------*
FORM get_user_confirmation.
  DATA: lv_answer TYPE c LENGTH 1.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Onay Gerekli'
      text_question         = 'Veriler kalıcı olarak değiştirilecek. Devam etmek istiyor musunuz?'
      text_button_1         = 'Evet'
      text_button_2         = 'Hayır'
      default_button        = '2'
      display_cancel_button = abap_false
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    WRITE: / '❌ İşlem kullanıcı tarafından iptal edildi.'.
    STOP.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM show_start_info
*&---------------------------------------------------------------------*
*& İşlem başlangıç bilgilerini gösterir
*&---------------------------------------------------------------------*
FORM show_start_info.
  DATA: lv_test_text TYPE string.

  IF p_test = abap_true.
    lv_test_text = 'EVET (Kaydetme yok)'.
  ELSE.
    lv_test_text = 'HAYIR (Gerçek kayıt)'.
  ENDIF.

  WRITE: / '═══════════════════════════════════════════════════════════════'.
  WRITE: / '                    VERİ MASKELEME BAŞLATILDI                  '.
  WRITE: / '═══════════════════════════════════════════════════════════════'.
  WRITE: / |RFC Destination : { p_rfc }|.
  WRITE: / |Şirket Kodu     : { p_bukrs }|.
  WRITE: / |Test Modu       : { lv_test_text }|.
  WRITE: / |Başlangıç Zamanı: { sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
  SKIP.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM execute_masking
*&---------------------------------------------------------------------*
*& Tüm maskeleme işlemlerini sırayla çalıştırır
*&---------------------------------------------------------------------*
FORM execute_masking.
  DATA: lv_count TYPE i.

  " Tabloları temizle
  CLEAR: gt_log, gv_total_records, gv_success_count, gv_error_count.

  "═══════════════════════════════════════════════════════════════
  " ADIM 1: BANKA VE TEMEL TABLOLAR
  "═══════════════════════════════════════════════════════════════
  IF p_bank = abap_true.
    PERFORM mask_bnka  CHANGING lv_count.
    PERFORM add_log USING 'BNKA' lv_count 'SUCCESS' 'Banka master verileri maskelendi'.

    PERFORM mask_tiban CHANGING lv_count.
    PERFORM add_log USING 'TIBAN' lv_count 'SUCCESS' 'IBAN verileri maskelendi'.

    PERFORM mask_payr  CHANGING lv_count.
    PERFORM add_log USING 'PAYR' lv_count 'SUCCESS' 'Ödeme verileri maskelendi'.
  ENDIF.

  "═══════════════════════════════════════════════════════════════
  " ADIM 2: BUSINESS PARTNER TABLOLARI
  "═══════════════════════════════════════════════════════════════
  IF p_bp = abap_true.
    PERFORM mask_but000 CHANGING lv_count.
    PERFORM add_log USING 'BUT000' lv_count 'SUCCESS' 'BP genel bilgileri maskelendi'.

    PERFORM mask_but020 CHANGING lv_count.
    PERFORM add_log USING 'BUT020' lv_count 'SUCCESS' 'BP adres bilgileri maskelendi'.

    PERFORM mask_but0id CHANGING lv_count.
    PERFORM add_log USING 'BUT0ID' lv_count 'SUCCESS' 'BP kimlik numaraları maskelendi'.

    PERFORM mask_dfkkbptaxnum CHANGING lv_count.
    PERFORM add_log USING 'DFKKBPTAXNUM' lv_count 'SUCCESS' 'BP vergi numaraları maskelendi'.
  ENDIF.

  "═══════════════════════════════════════════════════════════════
  " ADIM 3: MÜŞTERİ MASTER DATA
  "═══════════════════════════════════════════════════════════════
  IF p_cust = abap_true.
    PERFORM mask_kna1 CHANGING lv_count.
    PERFORM add_log USING 'KNA1' lv_count 'SUCCESS' 'Müşteri genel verileri maskelendi'.

    PERFORM mask_knb1 CHANGING lv_count.
    PERFORM add_log USING 'KNB1' lv_count 'SUCCESS' 'Müşteri şirket kodu verileri maskelendi'.

    PERFORM mask_knvv CHANGING lv_count.
    PERFORM add_log USING 'KNVV' lv_count 'SUCCESS' 'Müşteri satış alanı verileri maskelendi'.


  ENDIF.
  IF p_knkk EQ abap_true.

    PERFORM mask_knkk CHANGING lv_count.
    PERFORM add_log USING 'KNKK' lv_count 'SUCCESS' 'Müşteri satış alanı verileri maskelendi'.

  ENDIF.
  "═══════════════════════════════════════════════════════════════
  " ADIM 4: VENDOR MASTER DATA
  "═══════════════════════════════════════════════════════════════
  IF p_vend = abap_true.
    PERFORM mask_lfa1 CHANGING lv_count.
    PERFORM add_log USING 'LFA1' lv_count 'SUCCESS' 'Vendor genel verileri maskelendi'.

    PERFORM mask_lfb1 CHANGING lv_count.
    PERFORM add_log USING 'LFB1' lv_count 'SUCCESS' 'Vendor şirket kodu verileri maskelendi'.


    PERFORM mask_lfbk CHANGING lv_count.
    PERFORM add_log USING 'LFBK' lv_count 'SUCCESS' 'Vendor banka verileri maskelendi'.
  ENDIF.

  IF  p_clmt = abap_true.
    PERFORM mask_UKMBP_CMS CHANGING lv_count.
    PERFORM add_log USING 'UKMBP_CMS' lv_count 'SUCCESS' 'Credit Limit maskelendi'.

    PERFORM mask_UKM_TOTALS CHANGING lv_count.
    PERFORM add_log USING 'UKM_TOTALS' lv_count 'SUCCESS' 'Credit Limit maskelendi'.

    PERFORM mask_UKM_ITEM CHANGING lv_count.
    PERFORM add_log USING 'UKM_ITEM' lv_count 'SUCCESS' 'Credit Limit maskelendi'.

    PERFORM mask_UKMBP_CMS_SGM CHANGING lv_count.
    PERFORM add_log USING 'UKMBP_CMS_SGM' lv_count 'SUCCESS' 'Credit Limit maskelendi'.


    PERFORM mask_UKM_COMMITMENTS CHANGING lv_count.
    PERFORM add_log USING 'UKM_COMMITMENTS' lv_count 'SUCCESS' 'Credit Limit maskelendi'.

    PERFORM mask_UKM_TRANSFER_VECTOR CHANGING lv_count.
    PERFORM add_log USING 'UKM_TRANSFER_VECTOR' lv_count 'SUCCESS' 'Credit Limit maskelendi'.



  ENDIF.
  "═══════════════════════════════════════════════════════════════
  " ADIM 5: DURAN VARLIK TABLOLARI
  "═══════════════════════════════════════════════════════════════
  IF p_asset = abap_true.
    PERFORM mask_anla CHANGING lv_count.
    PERFORM add_log USING 'ANLA' lv_count 'SUCCESS' 'Duran varlık master verileri maskelendi'.

    PERFORM mask_anep CHANGING lv_count.
    PERFORM add_log USING 'ANEP' lv_count 'SUCCESS' 'Duran varlık dönemsel değerler maskelendi'.

    PERFORM mask_anek CHANGING lv_count.
    PERFORM add_log USING 'ANEK' lv_count 'SUCCESS' 'Duran varlık belge başlıkları maskelendi'.
  ENDIF.

  "═══════════════════════════════════════════════════════════════
  " ADIM 6: FI BELGE TABLOLARI
  "═══════════════════════════════════════════════════════════════
  IF p_bkpf = abap_true.
    PERFORM mask_bkpf CHANGING lv_count.
    IF p_job NE 'X'.
      PERFORM add_log USING 'BKPF' lv_count 'SUCCESS' 'FI belge başlıkları maskelendi'.
    ENDIF.
  ENDIF.

  IF p_bseg = abap_true.
    PERFORM mask_bseg CHANGING lv_count.
    IF p_job NE 'X'.
      PERFORM add_log USING 'BSEG' lv_count 'SUCCESS' 'FI belge kalemleri maskelendi'.
    ENDIF.
  ENDIF.

  IF p_acdoca = abap_true.
    PERFORM mask_acdoca CHANGING lv_count.
    IF p_job NE 'X'.
      PERFORM add_log USING 'ACDOCA' lv_count 'SUCCESS' 'Universal Journal maskelendi'.
    ENDIF.
  ENDIF.

  IF p_fagl = abap_true.
    PERFORM mask_faglflexa CHANGING lv_count.
    IF p_job NE 'X'.
      PERFORM add_log USING 'FAGLFLEXA' lv_count 'SUCCESS' 'GL Flex tablosu maskelendi'.
    ENDIF.
  ENDIF.

  "═══════════════════════════════════════════════════════════════
  " ADIM 7: FI BELGE TABLOLARI
  "═══════════════════════════════════════════════════════════════
  IF p_tcurr = abap_true.
    PERFORM mask_TCURR CHANGING lv_count.
    PERFORM add_log USING 'TCURR' lv_count 'SUCCESS' 'FI belge başlıkları maskelendi'.
  ENDIF.
  "ADRC,ADR6,ADR2


  IF p_adrs = abap_true.
    PERFORM mask_adrc CHANGING lv_count.
    PERFORM add_log USING 'ADRC' lv_count 'SUCCESS' 'Adres verileri maskelendi'.

    PERFORM mask_adr6 CHANGING lv_count.
    PERFORM add_log USING 'ADR6' lv_count 'SUCCESS' 'Adres verileri maskelendi'.
    PERFORM mask_adr2 CHANGING lv_count.
    PERFORM add_log USING 'ADR2' lv_count 'SUCCESS' 'Adres verileri maskelendi'.
  ENDIF.

  "═══════════════════════════════════════════════════════════════
  " COMMIT
  "═══════════════════════════════════════════════════════════════
  IF p_test = abap_false.
    COMMIT WORK AND WAIT.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM show_results
*&---------------------------------------------------------------------*
*& İşlem sonuçlarını tablo halinde gösterir
*&---------------------------------------------------------------------*
FORM show_results.
  DATA: lv_icon TYPE string.

  WRITE: / '═══════════════════════════════════════════════════════════════'.
  WRITE: / '                        İŞLEM SONUÇLARI                        '.
  WRITE: / '═══════════════════════════════════════════════════════════════'.
  SKIP.

  WRITE: / '┌─────────────────┬──────────┬──────────┬─────────────────────────────────────────┐'.
  WRITE: / '│      TABLO      │  KAYIT   │  DURUM   │              AÇIKLAMA                   │'.
  WRITE: / '├─────────────────┼──────────┼──────────┼─────────────────────────────────────────┤'.

  LOOP AT gt_log ASSIGNING FIELD-SYMBOL(<fs_log>).
    CASE <fs_log>-status.
      WHEN 'SUCCESS'.
        lv_icon = '✓'.
      WHEN 'WARNING'.
        lv_icon = '⚠'.
      WHEN 'ERROR'.
        lv_icon = '✗'.
      WHEN OTHERS.
        lv_icon = '•'.
    ENDCASE.

    WRITE: / |│ { <fs_log>-table_name WIDTH = 15 } │ { <fs_log>-record_count WIDTH = 8 } │ { lv_icon } { <fs_log>-status WIDTH = 7 } │ { <fs_log>-message WIDTH = 39 } │|.

    " İstatistik hesapla
    gv_total_records = gv_total_records + <fs_log>-record_count.
    CASE <fs_log>-status.
      WHEN 'SUCCESS'.
        gv_success_count = gv_success_count + 1.
      WHEN 'ERROR'.
        gv_error_count = gv_error_count + 1.
    ENDCASE.
  ENDLOOP.

  WRITE: / '└─────────────────┴──────────┴──────────┴─────────────────────────────────────────┘'.
  SKIP.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM show_summary
*&---------------------------------------------------------------------*
*& Özet istatistikleri gösterir
*&---------------------------------------------------------------------*
FORM show_summary.
  WRITE: / '┌───────────────────────────────────────────────────────────────┐'.
  WRITE: / '│                       ÖZET İSTATİSTİKLER                      │'.
  WRITE: / '├───────────────────────────────────────────────────────────────┤'.
  WRITE: / |│ Toplam İşlenen Tablo Sayısı  : { lines( gt_log ) WIDTH = 10 }                    │|.
  WRITE: / |│ Toplam Maskelenen Kayıt      : { gv_total_records WIDTH = 10 }                    │|.
  WRITE: / |│ Başarılı İşlem Sayısı        : { gv_success_count WIDTH = 10 }                    │|.
  WRITE: / |│ Hatalı İşlem Sayısı          : { gv_error_count WIDTH = 10 }                    │|.
  WRITE: / |│ Bitiş Zamanı                 : { sy-datum DATE = USER } { sy-uzeit TIME = USER }             │|.
  WRITE: / '└───────────────────────────────────────────────────────────────┘'.
  SKIP.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM show_final_message
*&---------------------------------------------------------------------*
*& Final mesajını gösterir
*&---------------------------------------------------------------------*
FORM show_final_message.
  IF p_test = abap_true.
    WRITE: / '⚠️  TEST MODU: Veriler değiştirilmedi, sadece simülasyon yapıldı.'.
    WRITE: / '    Gerçek maskeleme için "Test Modu" checkbox''ını kaldırın.'.
  ELSE.
    WRITE: / '✓ VERİ MASKELEME TAMAMLANDI!'.
    WRITE: / '  Tüm değişiklikler veritabanına kaydedildi.'.
  ENDIF.
  WRITE: / '═══════════════════════════════════════════════════════════════'.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM add_log
*&---------------------------------------------------------------------*
*& Log tablosuna kayıt ekler
*&---------------------------------------------------------------------*
FORM add_log USING pv_table   TYPE tabname
                   pv_count   TYPE i
                   pv_status  TYPE char10
                   pv_message TYPE char100.
  DATA: ls_log TYPE ty_log.

  ls_log-table_name   = pv_table.
  ls_log-record_count = pv_count.
  ls_log-status       = pv_status.
  ls_log-message      = pv_message.
  GET TIME STAMP FIELD ls_log-timestamp.

  APPEND ls_log TO gt_log.
ENDFORM.


*&---------------------------------------------------------------------*
*&      KARAKTER DÖNÜŞÜM PERFORMLARI
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& FORM get_mapped_char
*&---------------------------------------------------------------------*
*& Tek bir karakteri dönüşüm kuralına göre değiştirir
*& A→X, B→Y, 0→9, 1→8 vb.
*&---------------------------------------------------------------------*
FORM get_mapped_char USING    pv_char   TYPE c
                     CHANGING pv_result TYPE c.

  CASE pv_char.
      " Büyük harfler
    WHEN 'A'.
      pv_result = 'E'.
    WHEN 'B'.
      pv_result = 'Y'.
    WHEN 'C'.
      pv_result = 'Z'.
    WHEN 'D'.
      pv_result = 'W'.
    WHEN 'A'.
      pv_result = 'V'.
    WHEN 'F'.
      pv_result = 'T'.
    WHEN 'G'.
      pv_result = 'S'.
    WHEN 'H'.
      pv_result = 'R'.
    WHEN 'I'.
      pv_result = 'Q'.
    WHEN 'J'.
      pv_result = 'P'.
    WHEN 'K'.
      pv_result = 'O'.
    WHEN 'L'.
      pv_result = 'N'.
    WHEN 'M'.
      pv_result = 'M'.
    WHEN 'N'.
      pv_result = 'L'.
    WHEN 'O'.
      pv_result = 'K'.
    WHEN 'P'.
      pv_result = 'J'.
    WHEN 'Q'.
      pv_result = 'I'.
    WHEN 'R'.
      pv_result = 'H'.
    WHEN 'S'.
      pv_result = 'G'.
    WHEN 'T'.
      pv_result = 'F'.
    WHEN 'U'.
      pv_result = 'E'.
    WHEN 'V'.
      pv_result = 'D'.
    WHEN 'W'.
      pv_result = 'C'.
    WHEN 'X'.
      pv_result = 'B'.
    WHEN 'Y'.
      pv_result = 'A'.
    WHEN 'Z'.
      pv_result = 'U'.

      " Küçük harfler
    WHEN 'a'.
      pv_result = 'x'.
    WHEN 'b'.
      pv_result = 'y'.
    WHEN 'c'.
      pv_result = 'z'.
    WHEN 'd'.
      pv_result = 'w'.
    WHEN 'e'.
      pv_result = 'v'.
    WHEN 'f'.
      pv_result = 't'.
    WHEN 'g'.
      pv_result = 's'.
    WHEN 'h'.
      pv_result = 'r'.
    WHEN 'i'.
      pv_result = 'q'.
    WHEN 'j'.
      pv_result = 'p'.
    WHEN 'k'.
      pv_result = 'o'.
    WHEN 'l'.
      pv_result = 'n'.
    WHEN 'm'.
      pv_result = 'm'.
    WHEN 'n'.
      pv_result = 'l'.
    WHEN 'o'.
      pv_result = 'k'.
    WHEN 'p'.
      pv_result = 'j'.
    WHEN 'q'.
      pv_result = 'i'.
    WHEN 'r'.
      pv_result = 'h'.
    WHEN 's'.
      pv_result = 'g'.
    WHEN 't'.
      pv_result = 'f'.
    WHEN 'u'.
      pv_result = 'e'.
    WHEN 'v'.
      pv_result = 'd'.
    WHEN 'w'.
      pv_result = 'c'.
    WHEN 'x'.
      pv_result = 'b'.
    WHEN 'y'.
      pv_result = 'a'.
    WHEN 'z'.
      pv_result = 'u'.

      " Türkçe karakterler
    WHEN 'Ç'.
      pv_result = 'Z'.
    WHEN 'ç'.
      pv_result = 'z'.
    WHEN 'Ğ'.
      pv_result = 'S'.
    WHEN 'ğ'.
      pv_result = 's'.
    WHEN 'İ'.
      pv_result = 'Q'.
    WHEN 'ı'.
      pv_result = 'q'.
    WHEN 'Ö'.
      pv_result = 'K'.
    WHEN 'ö'.
      pv_result = 'k'.
    WHEN 'Ş'.
      pv_result = 'G'.
    WHEN 'ş'.
      pv_result = 'g'.
    WHEN 'Ü'.
      pv_result = 'E'.
    WHEN 'ü'.
      pv_result = 'e'.

      " Rakamlar
    WHEN '0'.
      pv_result = '9'.
    WHEN '1'.
      pv_result = '8'.
    WHEN '2'.
      pv_result = '7'.
    WHEN '3'.
      pv_result = '6'.
    WHEN '4'.
      pv_result = '5'.
    WHEN '5'.
      pv_result = '4'.
    WHEN '6'.
      pv_result = '3'.
    WHEN '7'.
      pv_result = '2'.
    WHEN '8'.
      pv_result = '1'.
    WHEN '9'.
      pv_result = '0'.

      " Özel karakterler - değişmez
    WHEN OTHERS.
      pv_result = pv_char.
  ENDCASE.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM scramble_text
*&---------------------------------------------------------------------*
*& Metin içindeki tüm karakterleri dönüştürür
*& Örnek: "Ahmet Yılmaz" → "Xrmvf Aqnmxu"
*&---------------------------------------------------------------------*
FORM scramble_text USING    pv_input  TYPE clike
                   CHANGING pv_output TYPE string.


  DATA: lv_len  TYPE i,
        lv_char TYPE c LENGTH 1,
        lv_idx  TYPE i.

  CLEAR pv_output.

  IF pv_input IS INITIAL.
    RETURN.
  ENDIF.

  lv_len = strlen( pv_input ).

  DO lv_len TIMES.
    lv_idx = sy-index - 1.
    lv_char = pv_input+lv_idx(1).

    " Boşluk ve özel karakterleri koru
    IF lv_char = ' ' OR lv_char = '.' OR lv_char = '-' OR lv_char = '@' OR lv_char = '/'.
      pv_output = pv_output && lv_char.
      " Çift indeksli karakterleri yıldızla (2, 4, 6...)
    ELSEIF sy-index MOD 2 = 0.
      pv_output = pv_output && '*'.
    ELSE.
      pv_output = pv_output && lv_char.
    ENDIF.
  ENDDO.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM scramble_number
*&---------------------------------------------------------------------*
*& Sadece rakamları dönüştürür
*& Örnek: "05321234567" → "94678765432"
*&---------------------------------------------------------------------*
FORM scramble_number USING    pv_input  TYPE clike
                     CHANGING pv_output TYPE string.

  DATA: lv_len    TYPE i,
        lv_char   TYPE c LENGTH 1,
        lv_mapped TYPE c LENGTH 1,
        lv_idx    TYPE i.

  CLEAR pv_output.

  IF pv_input IS INITIAL.
    RETURN.
  ENDIF.

  lv_len = strlen( pv_input ).

  DO lv_len TIMES.
    lv_idx = sy-index - 1.
    lv_char = pv_input+lv_idx(1).

    " Sadece rakamları dönüştür
    IF lv_char CA '0123456789'.
      PERFORM get_mapped_char USING lv_char CHANGING lv_mapped.
    ELSE.
      lv_mapped = lv_char.
    ENDIF.

    pv_output = pv_output && lv_mapped.
  ENDDO.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM scramble_iban
*&---------------------------------------------------------------------*
*& IBAN formatını koruyarak scramble eder
*& İlk 2 karakter (ülke kodu) korunur
*& Örnek: "TR330006100519786457" → "TR669993899480213542"
*&---------------------------------------------------------------------*
FORM scramble_iban USING    pv_input  TYPE clike
                   CHANGING pv_output TYPE string.

  DATA: lv_country   TYPE string,
        lv_rest      TYPE string,
        lv_scrambled TYPE string,
        lv_len       TYPE i,
        lv_idx       TYPE i,
        lv_char      TYPE c LENGTH 1.

  CLEAR pv_output.

  IF pv_input IS INITIAL.
    RETURN.
  ENDIF.

  IF strlen( pv_input ) >= 2.
    lv_country = pv_input(2).
    lv_rest = pv_input+2.
    " Rest kısmını yıldızla
    lv_len = strlen( lv_rest ).
    DO lv_len TIMES.
      lv_idx = sy-index - 1.
      lv_char = lv_rest+lv_idx(1).
      IF sy-index MOD 2 = 0.
        lv_scrambled = lv_scrambled && '*'.
      ELSE.
        lv_scrambled = lv_scrambled && lv_char.
      ENDIF.
    ENDDO.
    pv_output = lv_country && lv_scrambled.
  ELSE.
    PERFORM scramble_text USING pv_input CHANGING pv_output.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM scramble_email
*&---------------------------------------------------------------------*
*& Email adresinde @ öncesini scramble eder, domain korunur
*& Örnek: "ahmet@firma.com" → "xrmvf@firma.com"
*&---------------------------------------------------------------------*
FORM scramble_email USING    pv_input  TYPE clike
                    CHANGING pv_output TYPE string.

  DATA: lv_user      TYPE string,
        lv_domain    TYPE string,
        lv_at_pos    TYPE i,
        lv_scrambled TYPE string,
        lv_len       TYPE i,
        lv_idx       TYPE i,
        lv_char      TYPE c LENGTH 1.

  CLEAR pv_output.

  IF pv_input IS INITIAL.
    RETURN.
  ENDIF.

  lv_at_pos = find( val = pv_input sub = '@' ).

  IF lv_at_pos > 0.
    lv_user = pv_input(lv_at_pos).
    lv_domain = pv_input+lv_at_pos.
    " User kısmını yıldızla
    lv_len = strlen( lv_user ).
    DO lv_len TIMES.
      lv_idx = sy-index - 1.
      lv_char = lv_user+lv_idx(1).
      IF lv_char = '.' OR lv_char = '-' OR lv_char = '_'.
        lv_scrambled = lv_scrambled && lv_char.
      ELSEIF sy-index MOD 2 = 0.
        lv_scrambled = lv_scrambled && '*'.
      ELSE.
        lv_scrambled = lv_scrambled && lv_char.
      ENDIF.
    ENDDO.
    pv_output = lv_scrambled && lv_domain.
  ELSE.
    PERFORM scramble_text USING pv_input CHANGING pv_output.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM partial_mask
*&---------------------------------------------------------------------*
*& Kısmi maskeleme - baştan ve sondan belirli karakterleri gösterir
*& Örnek: "12345678901" → "12*******01"
*&---------------------------------------------------------------------*
FORM partial_mask USING    pv_input         TYPE clike
                           pv_visible_start TYPE i
                           pv_visible_end   TYPE i
                  CHANGING pv_output        TYPE string.

  DATA: lv_len      TYPE i,
        lv_start    TYPE string,
        lv_end      TYPE string,
        lv_mask     TYPE string,
        lv_mask_len TYPE i.

  CLEAR pv_output.

  IF pv_input IS INITIAL.
    RETURN.
  ENDIF.

  lv_len = strlen( pv_input ).

  " Metin çok kısaysa tamamen maskele
  IF lv_len <= pv_visible_start + pv_visible_end.
    DO lv_len TIMES.
      lv_mask = lv_mask && '*'.
    ENDDO.
    pv_output = lv_mask.
    RETURN.
  ENDIF.

  " Baştan görünür kısım
  lv_start = pv_input(pv_visible_start).

  " Sondan görünür kısım
  DATA(lv_end_start) = lv_len - pv_visible_end.
  lv_end = pv_input+lv_end_start(pv_visible_end).

  " Ortadaki maskeleme
  lv_mask_len = lv_len - pv_visible_start - pv_visible_end.
  DO lv_mask_len TIMES.
    lv_mask = lv_mask && '*'.
  ENDDO.

  pv_output = lv_start && lv_mask && lv_end.
ENDFORM.


*&---------------------------------------------------------------------*
*&      TABLO MASKELEME PERFORMLARI
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& FORM mask_acdoca
*&---------------------------------------------------------------------*
*& ACDOCA - Universal Journal (S/4HANA ana FI tablosu)
*& Maskelenen: KUNNR, LIFNR, SGTXT, ZUONR, XREF1_HD, XREF2_HD, XREF3,
*&             EBELN, VBELN, NAME1
*&---------------------------------------------------------------------*
FORM mask_acdoca CHANGING pv_count TYPE i.
  DATA: lt_acdoca     TYPE TABLE OF acdoca,
        lv_last_belnr TYPE belnr_d,
        lv_temp       TYPE string.

  DO.

    CLEAR lt_acdoca.

    CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
      EXPORTING
        iv_acdoca      = abap_true
        iv_bukrs       = p_bukrs
        iv_belnr       = lv_last_belnr
        iv_packagesize = 10000
      TABLES
        et_acdoca      = lt_acdoca.

    IF lt_acdoca IS INITIAL.
      EXIT.
    ENDIF.

    LOOP AT lt_acdoca ASSIGNING FIELD-SYMBOL(<fs>).

      lv_last_belnr = <fs>-belnr.

      " SGTXT
      IF <fs>-sgtxt IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
        <fs>-sgtxt = lv_temp.
      ENDIF.

      " ZUONR
      IF <fs>-zuonr IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
        <fs>-zuonr = lv_temp.
      ENDIF.

    ENDLOOP.

    IF p_test = abap_false.
      MODIFY acdoca FROM TABLE lt_acdoca.
      COMMIT WORK.
    ENDIF.

  ENDDO.

  pv_count = pv_count + lines( lt_acdoca ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bseg
*&---------------------------------------------------------------------*
*& BSEG - FI Belge Kalemleri
*& Maskelenen: KUNNR, LIFNR, SGTXT, ZUONR, XREF1, XREF2, XREF3, HBKID
*&---------------------------------------------------------------------*
FORM mask_bseg CHANGING pv_count TYPE i.

  DATA: lt_bseg       TYPE TABLE OF bseg,
        lv_last_belnr TYPE belnr_d,
        lv_temp       TYPE string.

  DO.

    CLEAR: lt_bseg[].

    CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
      EXPORTING
        iv_bseg        = abap_true
        iv_belnr       = lv_last_belnr
        iv_packagesize = 1000
        iv_bukrs       = p_bukrs
      TABLES
        et_bseg        = lt_bseg.

    IF lt_bseg IS INITIAL.
      EXIT.
    ENDIF.

    LOOP AT lt_bseg ASSIGNING FIELD-SYMBOL(<fs>).

      lv_last_belnr = <fs>-belnr.

      IF <fs>-sgtxt IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
        <fs>-sgtxt = lv_temp.
      ENDIF.

      IF <fs>-zuonr IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
        <fs>-zuonr = lv_temp.
      ENDIF.

      IF <fs>-xref1 IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-xref1 CHANGING lv_temp.
        <fs>-xref1 = lv_temp.
      ENDIF.

      IF <fs>-xref2 IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-xref2 CHANGING lv_temp.
        <fs>-xref2 = lv_temp.
      ENDIF.

      IF <fs>-xref3 IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-xref3 CHANGING lv_temp.
        <fs>-xref3 = lv_temp.
      ENDIF.

      IF <fs>-hbkid IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-hbkid CHANGING lv_temp.
        <fs>-hbkid = lv_temp.
      ENDIF.

    ENDLOOP.

    IF p_test = abap_false.
      MODIFY bseg FROM TABLE lt_bseg.
      COMMIT WORK.
    ENDIF.

    pv_count = pv_count + lines( lt_bseg ).

  ENDDO.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bkpf
*&---------------------------------------------------------------------*
*& BKPF - FI Belge Başlıkları
*& Maskelenen: BKTXT, XBLNR, AWKEY, USNAM
*&---------------------------------------------------------------------*
FORM mask_bkpf CHANGING pv_count TYPE i.
  DATA: lt_bkpf       TYPE TABLE OF bkpf,
        lv_last_belnr TYPE belnr_d,
        lv_temp       TYPE string.

  DO.

    CLEAR lt_bkpf.

    CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
      EXPORTING
        iv_bkpf        = abap_true
        iv_packagesize = 10000
        iv_belnr       = lv_last_belnr
        iv_bukrs       = p_bukrs
      TABLES
        et_bkpf        = lt_bkpf.

    IF lt_bkpf IS INITIAL.
      EXIT.
    ENDIF.

    LOOP AT lt_bkpf ASSIGNING FIELD-SYMBOL(<fs>).

      lv_last_belnr = <fs>-belnr.

      IF <fs>-bktxt IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-bktxt CHANGING lv_temp.
        <fs>-bktxt = lv_temp.
      ENDIF.

      IF <fs>-xblnr IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-xblnr CHANGING lv_temp.
        <fs>-xblnr = lv_temp.
      ENDIF.

      IF <fs>-awkey IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-awkey CHANGING lv_temp.
        <fs>-awkey = lv_temp.
      ENDIF.

      IF <fs>-usnam IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-usnam CHANGING lv_temp.
        <fs>-usnam = lv_temp.
      ENDIF.

    ENDLOOP.
    IF p_test = abap_false.
      MODIFY bKPF FROM TABLE @lt_BKPF.
    ENDIF.

    pv_count = lines( lt_bKPF ).

  ENDDO.
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bsis
*&---------------------------------------------------------------------*
*& BSIS - GL Açık Kalemler
*& Maskelenen: KUNNR, LIFNR, SGTXT, ZUONR, XREF1, XREF2
*&---------------------------------------------------------------------*
FORM mask_bsis CHANGING pv_count TYPE i.
  DATA: lt_bsis TYPE TABLE OF bsis,
        lv_temp TYPE string.

  SELECT * FROM bsis INTO TABLE @lt_bsis
    WHERE bukrs = @p_bukrs.

  LOOP AT lt_bsis ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-sgtxt IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
      <fs>-sgtxt = lv_temp.
    ENDIF.

    IF <fs>-zuonr IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
      <fs>-zuonr = lv_temp.
    ENDIF.

*    IF <fs>-xref1 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref1 CHANGING lv_temp.
*      <fs>-xref1 = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref2 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref2 CHANGING lv_temp.
*      <fs>-xref2 = lv_temp.
*    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
*    MODIFY bsis FROM TABLE @lt_bsis.
  ENDIF.

  pv_count = lines( lt_bsis ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bsas
*&---------------------------------------------------------------------*
*& BSAS - GL Kapalı Kalemler
*&---------------------------------------------------------------------*
FORM mask_bsas CHANGING pv_count TYPE i.
*  DATA: lt_bsas TYPE TABLE OF bsas,
*        lv_temp TYPE string.
*
*  SELECT * FROM bsas INTO TABLE @lt_bsas
*    WHERE bukrs = @p_bukrs.
*
*  LOOP AT lt_bsas ASSIGNING FIELD-SYMBOL(<fs>).
*    IF <fs>-sgtxt IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
*      <fs>-sgtxt = lv_temp.
*    ENDIF.
*
*    IF <fs>-zuonr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
*      <fs>-zuonr = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref1 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref1 CHANGING lv_temp.
*      <fs>-xref1 = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref2 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref2 CHANGING lv_temp.
*      <fs>-xref2 = lv_temp.
*    ENDIF.
*  ENDLOOP.
*
*  IF p_test = abap_false.
*    MODIFY bsas FROM TABLE @lt_bsas.
*  ENDIF.
*
*  pv_count = lines( lt_bsas ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bsik
*&---------------------------------------------------------------------*
*& BSIK - Vendor Açık Kalemler
*& Maskelenen: LIFNR, SGTXT, ZUONR, XREF1, XREF2
*&---------------------------------------------------------------------*
FORM mask_bsik CHANGING pv_count TYPE i.
*  DATA: lt_bsik TYPE TABLE OF bsik,
*        lv_temp TYPE string.
*
*  SELECT * FROM bsik INTO TABLE @lt_bsik
*    WHERE bukrs = @p_bukrs.
*
*  LOOP AT lt_bsik ASSIGNING FIELD-SYMBOL(<fs>).
*    IF <fs>-lifnr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-lifnr CHANGING lv_temp.
*      <fs>-lifnr = lv_temp.
*    ENDIF.
*
*    IF <fs>-sgtxt IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
*      <fs>-sgtxt = lv_temp.
*    ENDIF.
*
*    IF <fs>-zuonr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
*      <fs>-zuonr = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref1 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref1 CHANGING lv_temp.
*      <fs>-xref1 = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref2 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref2 CHANGING lv_temp.
*      <fs>-xref2 = lv_temp.
*    ENDIF.
*  ENDLOOP.
*
*  IF p_test = abap_false.
*    MODIFY bsik FROM TABLE @lt_bsik.
*  ENDIF.
*
*  pv_count = lines( lt_bsik ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bsak
*&---------------------------------------------------------------------*
*& BSAK - Vendor Kapalı Kalemler
*&---------------------------------------------------------------------*
FORM mask_bsak CHANGING pv_count TYPE i.
*  DATA: lt_bsak TYPE TABLE OF bsak,
*        lv_temp TYPE string.
*
*  SELECT * FROM bsak INTO TABLE @lt_bsak
*    WHERE bukrs = @p_bukrs.
*
*  LOOP AT lt_bsak ASSIGNING FIELD-SYMBOL(<fs>).
*    IF <fs>-lifnr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-lifnr CHANGING lv_temp.
*      <fs>-lifnr = lv_temp.
*    ENDIF.
*
*    IF <fs>-sgtxt IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
*      <fs>-sgtxt = lv_temp.
*    ENDIF.
*
*    IF <fs>-zuonr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
*      <fs>-zuonr = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref1 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref1 CHANGING lv_temp.
*      <fs>-xref1 = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref2 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref2 CHANGING lv_temp.
*      <fs>-xref2 = lv_temp.
*    ENDIF.
*  ENDLOOP.
*
*  IF p_test = abap_false.
*    MODIFY bsak FROM TABLE @lt_bsak.
*  ENDIF.
*
*  pv_count = lines( lt_bsak ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bsid
*&---------------------------------------------------------------------*
*& BSID - Müşteri Açık Kalemler
*& Maskelenen: KUNNR, SGTXT, ZUONR, XREF1, XREF2
*&---------------------------------------------------------------------*
FORM mask_bsid CHANGING pv_count TYPE i.
*  DATA: lt_bsid TYPE TABLE OF bsid,
*        lv_temp TYPE string.
*
*  SELECT * FROM bsid INTO TABLE @lt_bsid
*    WHERE bukrs = @p_bukrs.
*
*  LOOP AT lt_bsid ASSIGNING FIELD-SYMBOL(<fs>).
*    IF <fs>-kunnr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-kunnr CHANGING lv_temp.
*      <fs>-kunnr = lv_temp.
*    ENDIF.
*
*    IF <fs>-sgtxt IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
*      <fs>-sgtxt = lv_temp.
*    ENDIF.
*
*    IF <fs>-zuonr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
*      <fs>-zuonr = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref1 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref1 CHANGING lv_temp.
*      <fs>-xref1 = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref2 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref2 CHANGING lv_temp.
*      <fs>-xref2 = lv_temp.
*    ENDIF.
*  ENDLOOP.
*
*  IF p_test = abap_false.
*    MODIFY bsid FROM TABLE @lt_bsid.
*  ENDIF.
*
*  pv_count = lines( lt_bsid ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bsad
*&---------------------------------------------------------------------*
*& BSAD - Müşteri Kapalı Kalemler
*&---------------------------------------------------------------------*
FORM mask_bsad CHANGING pv_count TYPE i.
*  DATA: lt_bsad TYPE TABLE OF bsad,
*        lv_temp TYPE string.
*
*  SELECT * FROM bsad INTO TABLE @lt_bsad
*    WHERE bukrs = @p_bukrs.
*
*  LOOP AT lt_bsad ASSIGNING FIELD-SYMBOL(<fs>).
*    IF <fs>-kunnr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-kunnr CHANGING lv_temp.
*      <fs>-kunnr = lv_temp.
*    ENDIF.
*
*    IF <fs>-sgtxt IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
*      <fs>-sgtxt = lv_temp.
*    ENDIF.
*
*    IF <fs>-zuonr IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-zuonr CHANGING lv_temp.
*      <fs>-zuonr = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref1 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref1 CHANGING lv_temp.
*      <fs>-xref1 = lv_temp.
*    ENDIF.
*
*    IF <fs>-xref2 IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-xref2 CHANGING lv_temp.
*      <fs>-xref2 = lv_temp.
*    ENDIF.
*  ENDLOOP.
*
*  IF p_test = abap_false.
*    MODIFY bsad FROM TABLE @lt_bsad.
*  ENDIF.

*  pv_count = lines( lt_bsad ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_faglflexa
*&---------------------------------------------------------------------*
*& FAGLFLEXA - GL Flex Tablosu
*& Maskelenen: KUNNR, LIFNR, SGTXT, ZUONR, XREF1, XREF2, XREF3
*&---------------------------------------------------------------------*
FORM mask_faglflexa CHANGING pv_count TYPE i.

  DATA: lt_faglflexa  TYPE TABLE OF faglflexa,
        lv_last_docnr TYPE belnr_d,
        lv_temp       TYPE string.

  DO.
    CLEAR lt_faglflexa.

    CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
      EXPORTING
        iv_faglflexa   = abap_true
        iv_packagesize = 10000
        iv_last_docnr  = lv_last_docnr
        iv_bukrs       = p_bukrs
      TABLES
        et_faglflexa   = lt_faglflexa.

    IF lt_faglflexa IS INITIAL.
      EXIT.
    ENDIF.
    LOOP AT lt_faglflexa ASSIGNING FIELD-SYMBOL(<fs>).
      lv_last_docnr = <fs>-docnr.
      IF <fs>-usnam IS NOT INITIAL.
        PERFORM scramble_text USING <fs>-usnam CHANGING lv_temp.
        <fs>-usnam = lv_temp.
      ENDIF.
    ENDLOOP.

    IF p_test = abap_false.
      MODIFY faglflexa FROM TABLE lt_faglflexa.
    ENDIF.

  ENDDO.
ENDFORM.
*&---------------------------------------------------------------------*
*& FORM mask_kna1
*&---------------------------------------------------------------------*
*& KNA1 - Müşteri Genel Verileri
*& Maskelenen: NAME1-4, STRAS, ORT01, PSTLZ, TELF1-2, STCD1-2, STCEG
*&---------------------------------------------------------------------*
FORM mask_kna1 CHANGING pv_count TYPE i.
  DATA: lt_kna1 TYPE TABLE OF kna1,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_kna1 = abap_true
    TABLES
      et_kna1 = lt_kna1.

  LOOP AT lt_kna1 ASSIGNING FIELD-SYMBOL(<fs>).
    " İsimler
    IF <fs>-name1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name1 CHANGING lv_temp.
      <fs>-name1 = lv_temp.
    ENDIF.

    IF <fs>-sortl IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-sortl CHANGING lv_temp.
      <fs>-sortl = lv_temp.
    ENDIF.

    IF <fs>-name2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name2 CHANGING lv_temp.
      <fs>-name2 = lv_temp.
    ENDIF.

    IF <fs>-name3 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name3 CHANGING lv_temp.
      <fs>-name3 = lv_temp.
    ENDIF.

    IF <fs>-name4 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name4 CHANGING lv_temp.
      <fs>-name4 = lv_temp.
    ENDIF.

    " Adres
    IF <fs>-stras IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-stras CHANGING lv_temp.
      <fs>-stras = lv_temp.
    ENDIF.

    IF <fs>-ort01 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-ort01 CHANGING lv_temp.
      <fs>-ort01 = lv_temp.
    ENDIF.

    IF <fs>-pstlz IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-pstlz CHANGING lv_temp.
      <fs>-pstlz = lv_temp.
    ENDIF.

    " Telefon
    IF <fs>-telf1 IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-telf1 CHANGING lv_temp.
      <fs>-telf1 = lv_temp.
    ENDIF.

    IF <fs>-telf2 IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-telf2 CHANGING lv_temp.
      <fs>-telf2 = lv_temp.
    ENDIF.

    " Vergi numaraları
    IF <fs>-stcd1 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-stcd1 2 2 CHANGING lv_temp.
      <fs>-stcd1 = lv_temp.
    ENDIF.

    IF <fs>-stcd2 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-stcd2 2 2 CHANGING lv_temp.
      <fs>-stcd2 = lv_temp.
    ENDIF.

    IF <fs>-stceg IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-stceg 2 2 CHANGING lv_temp.
      <fs>-stceg = lv_temp.
    ENDIF.

    IF <fs>-mcod1 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-mcod1 2 2 CHANGING lv_temp.
      <fs>-mcod1 = lv_temp.
    ENDIF.

    IF <fs>-mcod2 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-mcod2 2 2 CHANGING lv_temp.
      <fs>-mcod2 = lv_temp.
    ENDIF.

    IF <fs>-mcod3 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-mcod3 2 2 CHANGING lv_temp.
      <fs>-mcod3 = lv_temp.
    ENDIF.

  ENDLOOP.

  IF p_test = abap_false.
    UPDATE kna1 FROM TABLE @lt_kna1.
    COMMIT WORK AND WAIT.
  ENDIF.

  pv_count = lines( lt_kna1 ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_knb1
*&---------------------------------------------------------------------*
*& KNB1 - Müşteri Şirket Kodu Verileri
*&---------------------------------------------------------------------*
FORM mask_knb1 CHANGING pv_count TYPE i.
  DATA: lt_knb1 TYPE TABLE OF knb1,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_knb1 = abap_true
    TABLES
      et_knb1 = lt_knb1.

*  LOOP AT lt_knb1 ASSIGNING FIELD-SYMBOL(<fs>).
*    IF <fs>-zterm IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-zterm CHANGING lv_temp.
*      <fs>-zterm = lv_temp.
*    ENDIF.
*  ENDLOOP.

  IF p_test = abap_false.
    MODIFY knb1 FROM TABLE @lt_knb1.
  ENDIF.

  pv_count = lines( lt_knb1 ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_knvv
*&---------------------------------------------------------------------*
*& KNVV - Müşteri Satış Alanı Verileri
*&---------------------------------------------------------------------*
FORM mask_knvv CHANGING pv_count TYPE i.
  DATA: lt_knvv TYPE TABLE OF knvv,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_knvv = abap_true
    TABLES
      et_knvv = lt_knvv.

*  LOOP AT lt_knvv ASSIGNING FIELD-SYMBOL(<fs>).
**    IF <fs>-lifnr IS NOT INITIAL.
**      PERFORM scramble_text USING <fs>-lifnr CHANGING lv_temp.
**      <fs>-lifnr = lv_temp.
**    ENDIF.
*  ENDLOOP.
*
  IF p_test = abap_false.
    MODIFY knvv FROM TABLE @lt_knvv.
  ENDIF.

  pv_count = lines( lt_knvv ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_lfa1
*&---------------------------------------------------------------------*
*& LFA1 - Vendor Genel Verileri
*& Maskelenen: NAME1-4, STRAS, ORT01, PSTLZ, TELF1, STCD1-2, STCEG
*&---------------------------------------------------------------------*
FORM mask_lfa1 CHANGING pv_count TYPE i.
  DATA: lt_lfa1 TYPE TABLE OF lfa1,
        lv_temp TYPE string.

*  SELECT * FROM lfa1 INTO TABLE @lt_lfa1.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_LFA1 = abap_true
    TABLES
      et_LFa1 = lt_LFa1.

  LOOP AT lt_lfa1 ASSIGNING FIELD-SYMBOL(<fs>).
    " İsimler
    IF <fs>-name1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name1 CHANGING lv_temp.
      <fs>-name1 = lv_temp.
    ENDIF.

    IF <fs>-name2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name2 CHANGING lv_temp.
      <fs>-name2 = lv_temp.
    ENDIF.

    IF <fs>-name3 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name3 CHANGING lv_temp.
      <fs>-name3 = lv_temp.
    ENDIF.

    IF <fs>-name4 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name4 CHANGING lv_temp.
      <fs>-name4 = lv_temp.
    ENDIF.

    " Adres
    IF <fs>-stras IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-stras CHANGING lv_temp.
      <fs>-stras = lv_temp.
    ENDIF.

    IF <fs>-ort01 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-ort01 CHANGING lv_temp.
      <fs>-ort01 = lv_temp.
    ENDIF.

    IF <fs>-ort02 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-ort02 CHANGING lv_temp.
      <fs>-ort02 = lv_temp.
    ENDIF.

    IF <fs>-sortl IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-sortl CHANGING lv_temp.
      <fs>-sortl = lv_temp.
    ENDIF.

    IF <fs>-regio IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-regio CHANGING lv_temp.
      <fs>-regio = lv_temp.
    ENDIF.


    IF <fs>-telfx IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-telfx CHANGING lv_temp.
      <fs>-telfx = lv_temp.
    ENDIF.

    IF <fs>-pstlz IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-pstlz CHANGING lv_temp.
      <fs>-pstlz = lv_temp.
    ENDIF.
    IF <fs>-telfx IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-telfx CHANGING lv_temp.
      <fs>-telfx = lv_temp.
    ENDIF.
    " Telefon
    IF <fs>-telf1 IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-telf1 CHANGING lv_temp.
      <fs>-telf1 = lv_temp.
    ENDIF.

    " Vergi numaraları
    IF <fs>-stcd1 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-stcd1 2 2 CHANGING lv_temp.
      <fs>-stcd1 = lv_temp.
    ENDIF.

    IF <fs>-stcd2 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-stcd2 2 2 CHANGING lv_temp.
      <fs>-stcd2 = lv_temp.
    ENDIF.

    IF <fs>-stceg IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-stceg 2 2 CHANGING lv_temp.
      <fs>-stceg = lv_temp.
    ENDIF.


    IF <fs>-mcod1 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-mcod1 2 2 CHANGING lv_temp.
      <fs>-mcod1 = lv_temp.
    ENDIF.

    IF <fs>-mcod2 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-mcod2 2 2 CHANGING lv_temp.
      <fs>-mcod2 = lv_temp.
    ENDIF.

    IF <fs>-mcod3 IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-mcod3 2 2 CHANGING lv_temp.
      <fs>-mcod3 = lv_temp.
    ENDIF.

  ENDLOOP.

  IF p_test = abap_false.
    MODIFY lfa1 FROM TABLE @lt_lfa1.
  ENDIF.

  pv_count = lines( lt_lfa1 ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_lfb1
*&---------------------------------------------------------------------*
*& LFB1 - Vendor Şirket Kodu Verileri
*&---------------------------------------------------------------------*
FORM mask_lfb1 CHANGING pv_count TYPE i.
  DATA: lt_lfb1 TYPE TABLE OF lfb1,
        lv_temp TYPE string.


  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_lfb1  = abap_true
      iv_bukrs = p_bukrs
    TABLES
      et_lfb1  = lt_lfb1.

  " LFB1'de dunning text ve alternatif ödeme alanları maskelenir
  " Bu alanlar sisteme göre değişebilir

  IF p_test = abap_false.
    MODIFY lfb1 FROM TABLE @lt_lfb1.
  ENDIF.

  pv_count = lines( lt_lfb1 ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_lfbk
*&---------------------------------------------------------------------*
*& LFBK - Vendor Banka Bilgileri
*& Maskelenen: BANKS, BANKL, BANKN
*&---------------------------------------------------------------------*
FORM mask_lfbk CHANGING pv_count TYPE i.
  DATA: lt_lfbk TYPE TABLE OF lfbk,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_lfbk = abap_true
    TABLES
      et_lfbk = lt_lfbk.

  LOOP AT lt_lfbk ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-bankl IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-bankl CHANGING lv_temp.
      <fs>-bankl = lv_temp.
    ENDIF.

    IF <fs>-bankn IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-bankn CHANGING lv_temp.
      <fs>-bankn = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY lfbk FROM TABLE @lt_lfbk.
  ENDIF.

  pv_count = lines( lt_lfbk ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_bnka
*&---------------------------------------------------------------------*
*& BNKA - Banka Master Verileri
*& Maskelenen: BANKA, STRAS, SWIFT
*&---------------------------------------------------------------------*
FORM mask_bnka CHANGING pv_count TYPE i.
  DATA: lt_bnka TYPE TABLE OF bnka,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_bnka = abap_true
    TABLES
      et_bnka = lt_bnka.


  LOOP AT lt_bnka ASSIGNING FIELD-SYMBOL(<fs>).
*    IF <fs>-banka IS NOT INITIAL.
*      PERFORM scramble_text USING <fs>-banka CHANGING lv_temp.
*      <fs>-banka = lv_temp.
*    ENDIF.

    IF <fs>-stras IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-stras CHANGING lv_temp.
      <fs>-stras = lv_temp.
    ENDIF.

    IF <fs>-swift IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-swift CHANGING lv_temp.
      <fs>-swift = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY bnka FROM TABLE @lt_bnka.
  ENDIF.

  pv_count = lines( lt_bnka ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_payr
*&---------------------------------------------------------------------*
*& PAYR - Ödeme Bilgileri
*& Maskelenen: EMPFG, CHECT, BANKN
*&---------------------------------------------------------------------*
FORM mask_payr CHANGING pv_count TYPE i.
  DATA: lt_payr TYPE TABLE OF payr,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_payr  = abap_true
      iv_bukrs = p_bukrs
    TABLES
      et_payr  = lt_payr.

*  SELECT * FROM payr INTO TABLE @lt_payr
*    WHERE zbukr = @p_bukrs.

  LOOP AT lt_payr ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-empfg IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-empfg CHANGING lv_temp.
      <fs>-empfg = lv_temp.
    ENDIF.

    IF <fs>-chect IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-chect CHANGING lv_temp.
      <fs>-chect = lv_temp.
    ENDIF.

    IF <fs>-zbnkn IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-zbnkn CHANGING lv_temp.
      <fs>-zbnkn = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY payr FROM TABLE @lt_payr.
  ENDIF.

  pv_count = lines( lt_payr ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_tiban
*&---------------------------------------------------------------------*
*& TIBAN - IBAN Bilgileri
*& Maskelenen: IBAN (ülke kodu korunur)
*&---------------------------------------------------------------------*
FORM mask_tiban CHANGING pv_count TYPE i.
  DATA: lt_tiban TYPE TABLE OF tiban,
        lv_temp  TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_tiban = abap_true
    TABLES
      et_tiban = lt_tiban.

  LOOP AT lt_tiban ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-iban IS NOT INITIAL.
      PERFORM scramble_iban USING <fs>-iban CHANGING lv_temp.
      <fs>-iban = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY tiban FROM TABLE @lt_tiban.
  ENDIF.

  pv_count = lines( lt_tiban ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_anla
*&---------------------------------------------------------------------*
*& ANLA - Duran Varlık Master Verileri
*& Maskelenen: TXT50, INVNR, SERNR, HERST, LIESSION
*&---------------------------------------------------------------------*
FORM mask_anla CHANGING pv_count TYPE i.
  DATA: lt_anla TYPE TABLE OF anla,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_anla  = abap_true
      iv_bukrs = p_bukrs
    TABLES
      et_anla  = lt_anla.

  LOOP AT lt_anla ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-txt50 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-txt50 CHANGING lv_temp.
      <fs>-txt50 = lv_temp.
    ENDIF.

    IF <fs>-invnr IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-invnr CHANGING lv_temp.
      <fs>-invnr = lv_temp.
    ENDIF.

    IF <fs>-sernr IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-sernr CHANGING lv_temp.
      <fs>-sernr = lv_temp.
    ENDIF.

    IF <fs>-herst IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-herst CHANGING lv_temp.
      <fs>-herst = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY anla FROM TABLE @lt_anla.
  ENDIF.

  pv_count = lines( lt_anla ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_anep
*&---------------------------------------------------------------------*
*& ANEP - Duran Varlık Dönemsel Değerler
*&---------------------------------------------------------------------*
FORM mask_anep CHANGING pv_count TYPE i.

  DATA: lt_anep TYPE TABLE OF anep,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_anep  = abap_true
      iv_bukrs = p_bukrs
    TABLES
      et_anep  = lt_anep.

  IF p_test = abap_false.
    MODIFY anep FROM TABLE @lt_anep.
  ENDIF.
*
  pv_count = lines( lt_anep ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_anek
*&---------------------------------------------------------------------*
*& ANEK - Duran Varlık Belge Başlıkları
*&---------------------------------------------------------------------*
FORM mask_anek CHANGING pv_count TYPE i.
  DATA: lt_anek TYPE TABLE OF anek,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_anek  = abap_true
      iv_bukrs = p_bukrs
    TABLES
      et_anek  = lt_anek.

  LOOP AT lt_anek ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-sgtxt IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-sgtxt CHANGING lv_temp.
      <fs>-sgtxt = lv_temp.
    ENDIF.
    IF <fs>-xblnr IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-xblnr CHANGING lv_temp.
      <fs>-xblnr = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY anek FROM TABLE @lt_anek.
  ENDIF.

  pv_count = lines( lt_anek ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_but000
*&---------------------------------------------------------------------*
*& BUT000 - Business Partner Genel Bilgileri
*& Maskelenen: NAME_ORG1-4, NAME_FIRST, NAME_LAST, NAME1_TEXT
*&---------------------------------------------------------------------*
FORM mask_but000 CHANGING pv_count TYPE i.
  DATA: lt_but000 TYPE TABLE OF but000,
        lv_temp   TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_but000 = abap_true
    TABLES
      et_but000 = lt_but000.


  LOOP AT lt_but000 ASSIGNING FIELD-SYMBOL(<fs>).

    IF <fs>-bu_sort1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-bu_sort1 CHANGING lv_temp.
      <fs>-bu_sort1 = lv_temp.
    ENDIF.

    IF <fs>-bu_sort2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-bu_sort2 CHANGING lv_temp.
      <fs>-bu_sort2 = lv_temp.
    ENDIF.

    IF <fs>-name_org1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_org1 CHANGING lv_temp.
      <fs>-name_org1 = lv_temp.
    ENDIF.

    IF <fs>-name_org2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_org2 CHANGING lv_temp.
      <fs>-name_org2 = lv_temp.
    ENDIF.

    IF <fs>-name_org3 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_org3 CHANGING lv_temp.
      <fs>-name_org3 = lv_temp.
    ENDIF.

    IF <fs>-name_org4 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_org4 CHANGING lv_temp.
      <fs>-name_org4 = lv_temp.
    ENDIF.

    IF <fs>-name_first IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_first CHANGING lv_temp.
      <fs>-name_first = lv_temp.
    ENDIF.
    IF <fs>-mc_name1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-mc_name1 CHANGING lv_temp.
      <fs>-mc_name1 = lv_temp.
    ENDIF.
    IF <fs>-mc_name2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-mc_name2 CHANGING lv_temp.
      <fs>-mc_name2 = lv_temp.
    ENDIF.


    IF <fs>-name_last IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_last CHANGING lv_temp.
      <fs>-name_last = lv_temp.
    ENDIF.

    IF <fs>-name1_text IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name1_text CHANGING lv_temp.
      <fs>-name1_text = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY but000 FROM TABLE @lt_but000.
  ENDIF.

  pv_count = lines( lt_but000 ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_but020
*&---------------------------------------------------------------------*
*& BUT020 - Business Partner Adres Bilgileri
*& (Adres verileri genellikle ADRC tablosunda)
*&---------------------------------------------------------------------*
FORM mask_but020 CHANGING pv_count TYPE i.

  DATA: lt_but020 TYPE TABLE OF but020.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_but020 = abap_true
    TABLES
      et_but020 = lt_but020.

  " BUT020 genellikle sadece referans içerir
  " Asıl adres verileri ADRC tablosunda maskelenmeli
  IF p_test = abap_false.
    MODIFY but020 FROM TABLE @lt_but020.
  ENDIF.

  pv_count = lines( lt_but020 ).

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_but0id
*&---------------------------------------------------------------------*
*& BUT0ID - Business Partner Kimlik Numaraları
*& Maskelenen: IDNUMBER (kısmi maskeleme)
*&---------------------------------------------------------------------*
FORM mask_but0id CHANGING pv_count TYPE i.
  DATA: lt_but0id TYPE TABLE OF but0id,
        lv_temp   TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_but0id = abap_true
    TABLES
      et_but0id = lt_but0id.

  LOOP AT lt_but0id ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-idnumber IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-idnumber 2 2 CHANGING lv_temp.
      <fs>-idnumber = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY but0id FROM TABLE @lt_but0id.
  ENDIF.

  pv_count = lines( lt_but0id ).
ENDFORM.


*&---------------------------------------------------------------------*
*& FORM mask_dfkkbptaxnum
*&---------------------------------------------------------------------*
*& DFKKBPTAXNUM - BP Vergi Numaraları (FI-CA)
*& Maskelenen: TAXNUM
*&---------------------------------------------------------------------*
FORM mask_dfkkbptaxnum CHANGING pv_count TYPE i.
  DATA: lt_dfkkbptaxnum TYPE TABLE OF dfkkbptaxnum,
        lv_temp         TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_dfkkbptaxnum = abap_true
    TABLES
      et_dfkkbptaxnum = lt_dfkkbptaxnum.

  LOOP AT lt_dfkkbptaxnum ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-taxnum IS NOT INITIAL.
      PERFORM partial_mask USING <fs>-taxnum 2 2 CHANGING lv_temp.
      <fs>-taxnum = lv_temp.
    ENDIF.
  ENDLOOP.

  IF p_test = abap_false.
    MODIFY dfkkbptaxnum FROM TABLE @lt_dfkkbptaxnum.
  ENDIF.

  pv_count = lines( lt_dfkkbptaxnum ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_TCURR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_TCURR  CHANGING pV_count.
  DATA: lt_tcurr TYPE TABLE OF tcurr.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_TCURR = abap_true
    TABLES
      et_TCURR = lt_tcurr.


  IF p_test = abap_false.
    MODIFY tcurr FROM TABLE @lt_tcurr.
  ENDIF.

  pv_count = lines( lt_tcurr ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_knkk
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_knkk  CHANGING pv_count.
  DATA: lt_knkk TYPE TABLE OF knkk,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_knkk = abap_true
    TABLES
      et_knkk = lt_knkk.

*  LOOP AT lt_knvv ASSIGNING FIELD-SYMBOL(<fs>).
**    IF <fs>-lifnr IS NOT INITIAL.
**      PERFORM scramble_text USING <fs>-lifnr CHANGING lv_temp.
**      <fs>-lifnr = lv_temp.
**    ENDIF.
*  ENDLOOP.
*
  IF p_test = abap_false.
    MODIFY knkk FROM TABLE @lt_knkk.
  ENDIF.

  pv_count = lines( lt_knkk ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_adrc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_adrc  CHANGING pv_count.
  DATA: lt_adrc TYPE TABLE OF adrc,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_adrc = abap_true
    TABLES
      et_adrc = lt_adrc.


  LOOP AT lt_adrc ASSIGNING FIELD-SYMBOL(<fs>).

    IF <fs>-title IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-title CHANGING lv_temp.
      <fs>-title = lv_temp.
    ENDIF.

    IF <fs>-name1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name1 CHANGING lv_temp.
      <fs>-name1 = lv_temp.
    ENDIF.

    IF <fs>-name2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name2 CHANGING lv_temp.
      <fs>-name2 = lv_temp.
    ENDIF.

    IF <fs>-name3 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name3 CHANGING lv_temp.
      <fs>-name3 = lv_temp.
    ENDIF.

    IF <fs>-name4 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name4 CHANGING lv_temp.
      <fs>-name4 = lv_temp.
    ENDIF.
    IF <fs>-name_text IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_text CHANGING lv_temp.
      <fs>-name_text = lv_temp.
    ENDIF.
    IF <fs>-name_co IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-name_co CHANGING lv_temp.
      <fs>-name_co = lv_temp.
    ENDIF.
    IF <fs>-city1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-city1 CHANGING lv_temp.
      <fs>-city1 = lv_temp.
    ENDIF.
    IF <fs>-city2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-city2 CHANGING lv_temp.
      <fs>-city2 = lv_temp.
    ENDIF.

    IF <fs>-sort1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-sort1 CHANGING lv_temp.
      <fs>-sort1 = lv_temp.
    ENDIF.
    IF <fs>-sort2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-sort2 CHANGING lv_temp.
      <fs>-sort2 = lv_temp.
    ENDIF.

    IF <fs>-street IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-street CHANGING lv_temp.
      <fs>-street = lv_temp.
    ENDIF.

    IF <fs>-dont_use_s IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-dont_use_s CHANGING lv_temp.
      <fs>-dont_use_s = lv_temp.
    ENDIF.

    IF <fs>-streetcode IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-streetcode CHANGING lv_temp.
      <fs>-streetcode = lv_temp.
    ENDIF.

    IF <fs>-house_num1 IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-streetcode CHANGING lv_temp.
      <fs>-house_num1 = lv_temp.
    ENDIF.

    IF <fs>-house_num2 IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-house_num2 CHANGING lv_temp.
      <fs>-house_num2 = lv_temp.
    ENDIF.

    IF <fs>-house_num3 IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-house_num3 CHANGING lv_temp.
      <fs>-house_num3 = lv_temp.
    ENDIF.

    IF <fs>-country IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-country CHANGING lv_temp.
      <fs>-country = lv_temp.
    ENDIF.

    IF <fs>-region IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-region CHANGING lv_temp.
      <fs>-region = lv_temp.
    ENDIF.

    IF <fs>-str_suppl1 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-str_suppl1 CHANGING lv_temp.
      <fs>-str_suppl1 = lv_temp.
    ENDIF.

    IF <fs>-str_suppl2 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-str_suppl2 CHANGING lv_temp.
      <fs>-str_suppl2 = lv_temp.
    ENDIF.

    IF <fs>-str_suppl3 IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-str_suppl3 CHANGING lv_temp.
      <fs>-str_suppl3 = lv_temp.
    ENDIF.

    IF <fs>-location IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-location CHANGING lv_temp.
      <fs>-location = lv_temp.
    ENDIF.

  ENDLOOP.

  IF p_test = abap_false.
    MODIFY adrc FROM TABLE @lt_adrc.
  ENDIF.

  pv_count = lines( lt_adrc ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_adr6
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_adr2  CHANGING pv_count.
  DATA: lt_adr2 TYPE TABLE OF adr2,
        lv_temp TYPE string.
*
  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_adr2 = abap_true
    TABLES
      et_adr2 = lt_adr2.

  LOOP AT lt_adr2 ASSIGNING FIELD-SYMBOL(<fs>).

    IF <fs>-tel_number IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-tel_number CHANGING lv_temp.
      <fs>-tel_number = lv_temp.
    ENDIF.

    IF <fs>-tel_extens IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-tel_extens CHANGING lv_temp.
      <fs>-tel_extens = lv_temp.
    ENDIF.

    IF <fs>-telnr_long IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-telnr_long CHANGING lv_temp.
      <fs>-telnr_long = lv_temp.
    ENDIF.

    IF <fs>-telnr_call IS NOT INITIAL.
      PERFORM scramble_number USING <fs>-telnr_call CHANGING lv_temp.
      <fs>-telnr_call = lv_temp.
    ENDIF.

  ENDLOOP.

  IF p_test = abap_false.
    MODIFY adr2 FROM TABLE @lt_adr2.
  ENDIF.

  pv_count = lines( lt_adr2 ).
ENDFORM.
FORM mask_adr6  CHANGING pv_count.
  DATA: lt_adr6 TYPE TABLE OF adr6,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_adr6 = abap_true
    TABLES
      et_adr6 = lt_adr6.


  LOOP AT lt_adr6 ASSIGNING FIELD-SYMBOL(<fs>).

    IF <fs>-smtp_addr IS NOT INITIAL.
      PERFORM scramble_text USING <fs>-smtp_addr CHANGING lv_temp.
      <fs>-smtp_addr = lv_temp.
    ENDIF.

    IF <fs>-smtp_srch IS NOT INITIAL.
      PERFORM scramble_email USING <fs>-smtp_srch CHANGING lv_temp.
      <fs>-smtp_srch = lv_temp.
    ENDIF.

  ENDLOOP.

  IF p_test = abap_false.
    MODIFY adr6 FROM TABLE @lt_adr6.
  ENDIF.

  pv_count = lines( lt_adr6 ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_UKMBP_CMS_SGM
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_UKMBP_CMS_SGM  CHANGING pv_count.

  DATA: lt_cms_sgm TYPE TABLE OF ukmbp_cms_sgm,
        lv_temp    TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_cms_Sgm = abap_true
    TABLES
      et_cms_sgm = lt_cms_sgm.

  IF p_test = abap_false.
    MODIFY ukmbp_cms_sgm FROM TABLE @lt_cms_sgm.
  ENDIF.

  pv_count = lines( lt_cms_sgm ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_UKMBP_CMS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_UKMBP_CMS  CHANGING pv_count.

  DATA: lt_cms  TYPE TABLE OF ukmbp_cms,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_cms = abap_true
    TABLES
      et_cms = lt_cms.

  IF p_test = abap_false.
    MODIFY ukmbp_cms FROM TABLE @lt_cms.
  ENDIF.

  pv_count = lines( lt_cms ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_UKM_TOTALS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_UKM_TOTALS  CHANGING pv_count.

  DATA: lt_totals TYPE TABLE OF ukm_totals,
        lv_temp   TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_totals = abap_true
    TABLES
      et_totals = lt_totals.

  IF p_test = abap_false.
    MODIFY ukm_totals FROM TABLE @lt_totals.
  ENDIF.

  pv_count = lines( lt_totals ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_UKM_ITEM
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_UKM_ITEM  CHANGING pv_count.
  DATA: lt_item TYPE TABLE OF ukm_item,
        lv_temp TYPE string.

  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
    EXPORTING
      iv_item = abap_true
    TABLES
      et_item = lt_item.

  IF p_test = abap_false.
    MODIFY ukm_item FROM TABLE @lt_item.
  ENDIF.

  pv_count = lines( lt_item ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_UKM_COMMITMENTS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_UKM_COMMITMENTS  CHANGING pv_count.
*  DATA: lt_UKM_COMMITMENTS TYPE TABLE OF ukm_commitments,
*        lv_temp            TYPE string.
*
*  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
*    EXPORTING
*      iv_UKM_COMMITMENTS = abap_true
*    TABLES
*      et_UKM_COMMITMENTS = lt_UKM_COMMITMENTS.
*
*  IF p_test = abap_false.
*    MODIFY ukm_item FROM TABLE @lt_UKM_COMMITMENTS.
*  ENDIF.
*
*  pv_count = lines( lt_UKM_COMMITMENTS ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mask_UKM_TRANSFER_VECTOR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_COUNT
*&---------------------------------------------------------------------*
FORM mask_UKM_TRANSFER_VECTOR  CHANGING pv_count.
*  DATA: lt_UKM_COMMITMENTS TYPE TABLE OF ukm_transfer_vector,
*        lv_temp            TYPE string.
**
*  CALL FUNCTION 'ZKAI_RFC' DESTINATION p_rfc
*    EXPORTING
*      iv_UKM_COMMITMENTS = abap_true
*    TABLES
*      et_UKM_COMMITMENTS = lt_UKM_COMMITMENTS.
*
*  IF p_test = abap_false.
*    MODIFY ukm_item FROM TABLE @lt_UKM_COMMITMENTS.
*  ENDIF.
*
*  pv_count = lines( lt_UKM_COMMITMENTS ).
        endform.
