# SAP ABAP Geliştirme Kuralları — Claude Code İçin

> Bu dosya Claude Code'a verildiğinde, AI'ın ürettiği tüm ABAP kodunun bu kurallara uymasını sağlar.
> Versiyon: 1.0 | Paket: ZAI_CLAUDE | Tarih: 2026-04

---

## 1. GENEL PRENSİPLER

- **Clean ABAP** prensiplerine uy. Referans: [SAP/styleguides](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md)
- Tüm kodlar **ATC (ABAP Test Cockpit)** kontrolünden geçebilir olmalı. ATC hata verecek yapılardan kaçın.
- Object-Oriented yaklaşımı tercih et. **PERFORM / FORM kullanma**, local class veya global class kullan.
- Modern ABAP syntax kullan: `NEW`, `VALUE`, `CORRESPONDING`, `CONV`, `COND`, `SWITCH`, inline declaration (`DATA(...)`).
- Tüm text'ler **çevrilebilir (translatable)** olmalı: text symbol, message class veya OTR kullan. Hardcoded string kullanma.
- Her method **tek bir iş** yapmalı (Single Responsibility Principle).
- Method uzunluğu maksimum **~80 satır**. Daha uzunsa parçala.

---

## 2. İSİMLENDİRME KURALLARI (NAMING CONVENTION)

### 2.1 Geliştirme Objeleri

| Obje Tipi         | Prefix   | Örnek                        |
|--------------------|----------|------------------------------|
| Paket              | `Z`      | `ZAI_CLAUDE`                 |
| Program (SE38)     | `Z_`     | `Z_AI_FI_CUSTOMER_REPORT`    |
| Include (TOP)      | `Z_..._TOP` | `Z_AI_FI_CUST_RPT_TOP`   |
| Include (SEL)      | `Z_..._SEL` | `Z_AI_FI_CUST_RPT_SEL`   |
| Include (F01)      | `Z_..._F01` | `Z_AI_FI_CUST_RPT_F01`   |
| Class (Global)     | `ZCL_`   | `ZCL_AI_CLAUDE`              |
| Interface          | `ZIF_`   | `ZIF_AI_CLAUDE_SERVICE`      |
| Function Group     | `Z_`     | `Z_AI_CLAUDE_FG`             |
| Function Module    | `Z_`     | `Z_AI_GET_EMPLOYEE_DATA`     |
| Message Class      | `Z_`     | `ZAI_CLAUDE_MSG`             |
| Table Type         | `ZTT_`   | `ZTT_AI_EMPLOYEE_LIST`       |
| Structure          | `ZST_`   | `ZST_AI_EMPLOYEE_DATA`       |
| Data Element       | `ZDE_`   | `ZDE_AI_RESPONSE_CODE`       |
| Domain             | `ZDO_`   | `ZDO_AI_STATUS`              |
| Database Table     | `ZT_`    | `ZT_AI_LOG`                  |

### 2.2 Değişken İsimlendirme (Hungarian Notation — Klasik Yaklaşım)

> Not: Clean ABAP prefix'siz yaklaşımı önerir, ancak birçok müşteri hâlâ Hungarian notation kullanır.
> **Bu projede Hungarian Notation kullanılacaktır** çünkü ATC naming convention kontrolü bunu bekler.

| Kapsam / Tip       | Prefix   | Örnek                          |
|---------------------|----------|--------------------------------|
| Local variable      | `lv_`    | `lv_pernr`                     |
| Local structure     | `ls_`    | `ls_employee`                  |
| Local internal table| `lt_`    | `lt_employees`                 |
| Local object ref    | `lo_`    | `lo_alv_grid`                  |
| Global variable     | `gv_`    | `gv_uname`                     |
| Global structure    | `gs_`    | `gs_header`                    |
| Global int. table   | `gt_`    | `gt_output`                    |
| Global object ref   | `go_`    | `go_container`                 |
| Field symbol        | `<ls_>` / `<lt_>` | `<ls_employee>`      |
| Parameter (import)  | `iv_`    | `iv_pernr`                     |
| Parameter (export)  | `ev_`    | `ev_status`                    |
| Parameter (changing)| `cv_`    | `cv_counter`                   |
| Returning           | `rv_`    | `rv_result`                    |
| Importing table     | `it_`    | `it_pernr_list`                |
| Exporting table     | `et_`    | `et_employee_list`             |
| Constant            | `lc_` / `gc_` | `gc_status_success`      |
| Type (local)        | `ty_`    | `ty_s_employee`                |
| Type (table)        | `ty_t_`  | `ty_t_employees`               |
| Selection screen P  | `p_`     | `p_pernr`                      |
| Selection screen SO | `s_`     | `s_bukrs`                      |
| Class attribute     | `mv_`, `ms_`, `mt_`, `mo_` | `mt_data`    |
| Static attribute    | `sv_`    | `sv_instance`                  |

### 2.3 Method İsimlendirme

- Fiil ile başla: `get_`, `set_`, `create_`, `delete_`, `check_`, `validate_`, `process_`, `build_`, `handle_`
- Boolean dönen method: `is_`, `has_`, `can_` ile başla
- Örnekler: `get_employee_data`, `is_valid_pernr`, `build_alv_fieldcatalog`

### 2.4 Genel Kurallar

- İngilizce isimlendirme kullan (SAP standartı)
- Underscore ile ayır (`snake_case`): `get_employee_data` ✅ | `getEmployeeData` ❌
- Kısaltma kullanmaktan kaçın: `lv_organizational_unit` ✅ | `lv_org` ❌ (uzunluk sınırına takılırsan kısalt)
- Magic number kullanma, constant tanımla: `gc_status_success VALUE 'S'` ✅ | `'S'` ❌

---

## 3. ATC UYUMLULUK KURALLARI

ATC'ye takılmamak için şu kurallara kesinlikle uy:

### 3.1 Performans

- **SELECT içinde SELECT yapma** (nested select). FOR ALL ENTRIES veya JOIN kullan.
- **LOOP içinde SELECT yapma.** Önce toplu veri çek, sonra READ TABLE ile oku.
- `SELECT *` kullanma, sadece gerekli alanları listele.
- Internal table okumalarında `SORTED` veya `HASHED` table kullan, ya da `BINARY SEARCH` ile `READ TABLE`.
- `MODIFY` yerine `FIELD-SYMBOL` ile doğrudan değiştir.
- `MOVE-CORRESPONDING` yerine explicit field assignment veya `CORRESPONDING #( )` kullan.
- `APPEND` + `SORT` + `DELETE ADJACENT DUPLICATES` yerine `COLLECT` veya `INSERT INTO TABLE` (hashed).

### 3.2 Güvenlik & Yetki

- HR verileri için **yetki kontrolü** yap: `AUTHORITY-CHECK OBJECT 'P_ORGIN'` veya `HR_CHECK_AUTHORITY_INFTY`.
- Hassas veri loglamada dikkatli ol.

### 3.3 Kod Kalitesi

- **Kullanılmayan değişken** tanımlama (ATC uyarı verir).
- **Boş CATCH** bloğu bırakma, en azından log yaz.
- `SY-SUBRC` kontrolünü her DB operasyonundan sonra yap.
- `IS INITIAL` / `IS NOT INITIAL` kontrollerini kullan.
- `DESCRIBE TABLE ... LINES` yerine `lines( )` fonksiyonunu kullan.
- String birleştirmede `CONCATENATE` yerine `|...|` string template kullan.
- `CONDENSE NO-GAPS` yerine `condense( val = lv_str del = ' ' )` kullan.

### 3.4 Obsolete Statement'lardan Kaçın

ATC bu kullanımları yakalar ve hata verir:

| Kullanma ❌              | Yerine Kullan ✅                          |
|--------------------------|-------------------------------------------|
| `FORM / PERFORM`         | `METHOD` (local class veya global class)  |
| `MOVE x TO y`            | `y = x`                                   |
| `IF x IS INITIAL` + `ELSE` | `COND #( )` veya `SWITCH #( )`         |
| `CALL METHOD obj->meth`  | `obj->meth( )`                            |
| `CREATE OBJECT`          | `NEW #( )`                                |
| `READ TABLE ... INTO`    | `READ TABLE ... ASSIGNING`                |
| `HEADER LINE` table      | Standard table + work area                |
| `RANGES`                 | `TYPE RANGE OF`                           |
| `LIKE`                   | `TYPE`                                    |
| `COMPUTE`                | Doğrudan `=` ile                          |
| `WRITE TO`               | `|{ lv_var }|` string template            |

---

## 4. HR MODÜLÜ ÖZEL KURALLARI

### 4.1 Infotype Erişimi

- **Doğrudan PA tablolarına SELECT yapabilirsin** ama tarih filtresi MUTLAKA olmalı:
  ```abap
  SELECT pernr, orgeh, stell, begda, endda
    FROM pa0001
    INTO TABLE @lt_pa0001
    WHERE pernr IN @s_pernr
      AND begda <= @p_date
      AND endda >= @p_date.
  ```
- Alternatif olarak `HR_READ_INFOTYPE` FM kullanılabilir (tek PERNR için):
  ```abap
  CALL FUNCTION 'HR_READ_INFOTYPE'
    EXPORTING
      pernr     = lv_pernr
      infty     = '0001'
      begda     = lv_date
      endda     = lv_date
    IMPORTING
      subrc     = lv_subrc
    TABLES
      infty_tab = lt_p0001.
  ```

### 4.2 Sık Kullanılan HR Tabloları

| Infotype | Tablo   | Açıklama                        | Önemli Alanlar                     |
|----------|---------|---------------------------------|------------------------------------|
| 0001     | PA0001  | Organizasyonel Atama            | PERNR, BUKRS, WERKS, BTRTL, ORGEH, STELL, PLANS |
| 0002     | PA0002  | Kişisel Bilgiler                | PERNR, VORNA, NACHN, GBDAT, NATIO |
| 0006     | PA0006  | Adres Bilgileri                 | PERNR, ANSSA, STRAS, ORT01, PSTLZ |
| 0008     | PA0008  | Temel Ücret                     | PERNR, TRFAR, TRFGB, TRFGR, TRFST |
| 0105     | PA0105  | İletişim / Email                | PERNR, USRID_LONG (subty=0010)     |
| —        | HRP1000 | OM Obje Tanımları (Text)        | PLVAR, OTYPE, OBJID, STEXT        |
| —        | T527X   | Stell (Job) Text Tablosu        | STELL, STLTX                       |
| —        | T528T   | Pozisyon Text                   | PLANS, PLSTX                       |

### 4.3 Organizasyon Text'leri Okuma

ORGEH ve STELL gibi alanların text'lerini almak için:

```abap
" Organizasyon Birimi Text — HRP1000 üzerinden
SELECT SINGLE stext
  FROM hrp1000
  INTO @lv_orgeh_text
  WHERE plvar = '01'
    AND otype = 'O'
    AND objid = @lv_orgeh
    AND langu = @sy-langu
    AND begda <= @lv_date
    AND endda >= @lv_date.

" Pozisyon (Stell/Job) Text — T527X üzerinden
SELECT SINGLE stltx
  FROM t527x
  INTO @lv_stell_text
  WHERE stell = @lv_stell
    AND sprsl = @sy-langu.
```

### 4.4 HR Yetki Kontrolleri

HR verilerine erişirken yetki kontrolü zorunlu:

```abap
AUTHORITY-CHECK OBJECT 'P_ORGIN'
  ID 'INFTY' FIELD '0001'
  ID 'SUBTY' FIELD space
  ID 'AUTHC' FIELD 'R'
  ID 'PERSA' FIELD lv_werks
  ID 'PERSG' FIELD lv_persg
  ID 'PERSK' FIELD lv_persk
  ID 'VDSK1' FIELD space.

IF sy-subrc <> 0.
  " Yetki hatası — kullanıcıyı bilgilendir
  MESSAGE e001(zai_claude_msg) WITH lv_pernr.
ENDIF.
```

---

## 5. OData / ICF SERVİS KURALLARI

### 5.1 Handler Class Yapısı

- Her servis için bir **handler class** oluştur.
- `IF_HTTP_EXTENSION~HANDLE_REQUEST` implement et (ICF için) veya SAP Gateway entity/method override et (OData için).
- Request ve Response için ayrı **type** tanımla.
- JSON serialize/deserialize için `/UI2/CL_JSON` kullan.

### 5.2 Response Yapısı Standardı

Tüm servisler aşağıdaki response yapısını dönsün:

```abap
TYPES: BEGIN OF ty_s_response,
         code    TYPE char1,         " 'S' = Success, 'E' = Error
         message TYPE string,        " Açıklama mesajı
         data    TYPE REF TO data,   " Dinamik veri (varsa)
       END OF ty_s_response.
```

Veya spesifik bir yapı:

```abap
TYPES: BEGIN OF ty_s_employee_response,
         code           TYPE char1,
         message        TYPE string,
         pernr          TYPE persno,
         first_name     TYPE pad_vorna,
         last_name      TYPE pad_nachn,
         orgeh          TYPE orgeh,
         orgeh_text     TYPE stext,
         stell          TYPE stell,
         stell_text     TYPE stltx,
       END OF ty_s_employee_response.
```

### 5.3 Error Handling

- Her serviste **TRY...CATCH** bloğu kullan.
- Exception'ları yakala ve anlamlı mesajla dön.
- HTTP status code'ları doğru kullan (200, 400, 404, 500).

---

## 6. ALV RAPOR KURALLARI

### 6.1 Program Yapısı (Include Mimarisi)

```
Z_AI_FI_CUSTOMER_REPORT        → Ana program (REPORT + INCLUDE'lar)
  ├── Z_AI_FI_CUST_RPT_TOP     → TYPE tanımları, DATA declarations, CONSTANTS
  ├── Z_AI_FI_CUST_RPT_SEL     → SELECTION-SCREEN tanımları
  └── Z_AI_FI_CUST_RPT_F01     → Local Class tanımları ve implementasyonları
```

### 6.2 Ana Program Şablonu

```abap
REPORT z_ai_fi_customer_report.

INCLUDE z_ai_fi_cust_rpt_top.   " Tip ve veri tanımları
INCLUDE z_ai_fi_cust_rpt_sel.   " Selection screen
INCLUDE z_ai_fi_cust_rpt_f01.   " Local class ve iş mantığı

INITIALIZATION.
  " Varsayılan değer atamaları

START-OF-SELECTION.
  lcl_report=>run( ).
```

### 6.3 TOP Include Şablonu

```abap
*&---------------------------------------------------------------------*
*& Include Z_AI_FI_CUST_RPT_TOP
*&---------------------------------------------------------------------*

" Type tanımları
TYPES: BEGIN OF ty_s_output,
         bukrs   TYPE bukrs,
         kunnr   TYPE kunnr,
         name1   TYPE name1_gp,
         ort01   TYPE ort01,
         land1   TYPE land1,
         " ...diğer alanlar
       END OF ty_s_output,
       ty_t_output TYPE STANDARD TABLE OF ty_s_output WITH EMPTY KEY.

" Global veriler
DATA: gt_output TYPE ty_t_output.
```

### 6.4 SEL Include Şablonu

```abap
*&---------------------------------------------------------------------*
*& Include Z_AI_FI_CUST_RPT_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_bukrs FOR gv_bukrs,
                  s_kunnr FOR gv_kunnr.
  PARAMETERS:     p_stida TYPE sy-datum DEFAULT sy-datum.
SELECTION-SCREEN END OF BLOCK b01.
```

### 6.5 F01 Include — Local Class ile ALV

```abap
*&---------------------------------------------------------------------*
*& Include Z_AI_FI_CUST_RPT_F01
*&---------------------------------------------------------------------*

CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      run,
      get_data,
      display_alv.

  PRIVATE SECTION.
    CLASS-DATA:
      mt_output TYPE ty_t_output.
ENDCLASS.

CLASS lcl_report IMPLEMENTATION.

  METHOD run.
    get_data( ).
    IF mt_output IS NOT INITIAL.
      display_alv( ).
    ELSE.
      MESSAGE s002(zai_claude_msg) DISPLAY LIKE 'W'.
      " "Veri bulunamadı" mesajı
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    SELECT bukrs, kunnr, name1, ort01, land1
      FROM kna1
      INNER JOIN ...
      INTO TABLE @mt_output
      WHERE bukrs IN @s_bukrs
        AND kunnr IN @s_kunnr.
  ENDMETHOD.

  METHOD display_alv.
    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = DATA(lo_alv)
          CHANGING  t_table      = mt_output ).

        " Sütun başlıkları
        DATA(lo_columns) = lo_alv->get_columns( ).
        lo_columns->set_optimize( abap_true ).

        " Fonksiyonlar
        lo_alv->get_functions( )->set_all( abap_true ).

        " Layout
        DATA(lo_display) = lo_alv->get_display_settings( ).
        lo_display->set_striped_pattern( abap_true ).
        lo_display->set_list_header( 'Müşteri Listesi'(t01) ).

        lo_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lx_msg).
        MESSAGE lx_msg TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
```

### 6.6 ALV Kuralları Özet

- **CL_SALV_TABLE** kullan (basit raporlar için), CL_GUI_ALV_GRID kullan (etkileşimli raporlar için).
- PERFORM ile ALV kurma, **local class method** ile kur.
- Fieldcatalog'u otomatik al, sonra özelleştir.
- Striped pattern, optimize column width aktif et.
- Header text için text symbol kullan (çevrilebilir).

---

## 7. EXCEPTION HANDLING

```abap
TRY.
    " İş mantığı
  CATCH cx_sy_open_sql_db INTO DATA(lx_db).
    " DB hatası
    lv_message = lx_db->get_text( ).
  CATCH cx_root INTO DATA(lx_root).
    " Genel hata
    lv_message = lx_root->get_text( ).
ENDTRY.
```

- Boş CATCH bloğu bırakma.
- Spesifik exception class'ını yakala, `cx_root` son çare olsun.
- Hata mesajını kullanıcıya döndür veya logla (BAL_LOG veya application log).

---

## 8. YORUM VE DOKÜMANTASYON

### 8.1 Dosya Başlığı (Her Include / Program)

```abap
*&---------------------------------------------------------------------*
*& Report/Include: Z_AI_FI_CUSTOMER_REPORT
*& Açıklama:       FI müşteri bilgileri ALV raporu
*& Yazar:          [Geliştirici]
*& Tarih:          [Tarih]
*& Paket:          ZAI_CLAUDE
*& TR:             [Transport numarası]
*&---------------------------------------------------------------------*
```

### 8.2 Method Yorumları

```abap
  " Verilen PERNR ve tarih için personel organizasyon bilgilerini döndürür.
  " @parameter iv_pernr | Personel numarası
  " @parameter iv_date  | Geçerlilik tarihi
  " @return rs_employee | Personel bilgi yapısı
  METHOD get_employee_data.
```

### 8.3 Satır İçi Yorum

- Karmaşık iş mantığını açıkla.
- Açık olan kodlara yorum yazma (`" Değişkeni ata` gibi gereksiz yorum).
- Yorum İngilizce olmalı.

---

## 9. GÜVENLİK & TRANSPORT

- Tüm objeler **ZAI_CLAUDE** paketi altında olmalı.
- `$TMP` paketinde test edilebilir, ama sunum için transport paketine al.
- Yetki objeleri: HR verileri için `P_ORGIN`, FI verileri için `F_BKPF_BUK` vb. kontrol et.
- Hassas verileri (maaş, kimlik no) loglama veya ekranda gereksiz gösterme.

---

## 10. ÖZET KONTROL LİSTESİ

Kod commit etmeden önce kontrol et:

- [ ] ATC çalıştırıldı, hata yok
- [ ] Naming convention'a uygun
- [ ] PERFORM / FORM kullanılmadı
- [ ] SELECT * kullanılmadı
- [ ] LOOP içinde SELECT yok
- [ ] Kullanılmayan değişken yok
- [ ] SY-SUBRC her DB operation sonrası kontrol ediliyor
- [ ] TRY-CATCH blokları var
- [ ] Yetki kontrolü yapılıyor
- [ ] Text'ler çevrilebilir (text symbol / message class)
- [ ] Method'lar kısa ve tek amaçlı
- [ ] Dosya başlığı ve method yorumları var
- [ ] HR tarih filtresi kullanılıyor (BEGDA/ENDDA)
- [ ] Modern syntax kullanılıyor (inline, string template vb.)
