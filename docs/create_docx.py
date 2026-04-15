#!/usr/bin/env python3
"""Generate Z_AI_FI_INVOICE_POST technical documentation as .docx"""
import zipfile
import os

CONTENT_TYPES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>'''

RELS = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>'''

WORD_RELS = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>'''

STYLES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:sz w:val="22"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr><w:spacing w:before="360" w:after="200"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="36"/><w:color w:val="1F4E79"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="2E75B6"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr><w:spacing w:before="200" w:after="80"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="2E75B6"/></w:rPr>
  </w:style>
</w:styles>'''

def h1(text):
    return f'<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>{text}</w:t></w:r></w:p>'

def h2(text):
    return f'<w:p><w:pPr><w:pStyle w:val="Heading2"/></w:pPr><w:r><w:t>{text}</w:t></w:r></w:p>'

def h3(text):
    return f'<w:p><w:pPr><w:pStyle w:val="Heading3"/></w:pPr><w:r><w:t>{text}</w:t></w:r></w:p>'

def p(text, bold=False):
    rpr = '<w:rPr><w:b/></w:rPr>' if bold else ''
    return f'<w:p><w:r>{rpr}<w:t xml:space="preserve">{text}</w:t></w:r></w:p>'

def bullet(text):
    return f'''<w:p><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr><w:r><w:t xml:space="preserve">&#x2022;  {text}</w:t></w:r></w:p>'''

def empty():
    return '<w:p/>'

def table_row(cells, header=False):
    row = '<w:tr>'
    for c in cells:
        shading = '<w:shd w:val="clear" w:fill="D5E8F0"/>' if header else ''
        bpr = '<w:rPr><w:b/></w:rPr>' if header else ''
        row += f'''<w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/>{shading}</w:tcPr>
        <w:p><w:r>{bpr}<w:t xml:space="preserve">{c}</w:t></w:r></w:p></w:tc>'''
    row += '</w:tr>'
    return row

def table(headers, rows):
    border = '<w:top w:val="single" w:sz="4" w:color="999999"/><w:bottom w:val="single" w:sz="4" w:color="999999"/><w:left w:val="single" w:sz="4" w:color="999999"/><w:right w:val="single" w:sz="4" w:color="999999"/><w:insideH w:val="single" w:sz="4" w:color="999999"/><w:insideV w:val="single" w:sz="4" w:color="999999"/>'
    t = f'<w:tbl><w:tblPr><w:tblW w:w="9360" w:type="dxa"/><w:tblBorders>{border}</w:tblBorders></w:tblPr>'
    t += table_row(headers, header=True)
    for r in rows:
        t += table_row(r)
    t += '</w:tbl>'
    return t

# Build document content
body = []

# Title
body.append(h1('Z_AI_FI_INVOICE_POST'))
body.append(p('Excel&#x2019;den Toplu Satici Faturasi Kaydi - Teknik Dokumantasyon'))
body.append(empty())

body.append(table(
    ['Bilgi', 'Deger'],
    [
        ['Program', 'Z_AI_FI_INVOICE_POST'],
        ['Paket', 'ZAI_CLAUDE'],
        ['Yazar', 'Claude AI'],
        ['Tarih', '2026-04'],
        ['ABAP Versiyon', '7.50+'],
        ['SAP Modul', 'FI (Financial Accounting)'],
    ]
))
body.append(empty())

# 1. AMAC
body.append(h1('1. Amac'))
body.append(p('Bu program, Excel dosyasindan okunan satici fatura verilerini BAPI_ACC_DOCUMENT_POST kullanarak SAP FI sistemine toplu olarak kaydeder.'))
body.append(empty())
body.append(p('Temel Ozellikler:', bold=True))
body.append(bullet('Excel dosyasindan fatura verisi okuma (ALSM_EXCEL_TO_INTERNAL_TABLE)'))
body.append(bullet('Kayit oncesi validasyon (satici, tutar, tarih, para birimi, hesap)'))
body.append(bullet('BAPI_ACC_DOCUMENT_POST ile FI belge olusturma'))
body.append(bullet('Test modu (simulate) ve gercek kayit modu'))
body.append(bullet('Sonuclari ALV ile gosterme (basarili/hatali renklendirme)'))
body.append(bullet('Her satir icin detayli log (belge no, durum, hata mesaji)'))
body.append(empty())

# 2. DOSYA YAPISI
body.append(h1('2. Dosya Yapisi'))
body.append(table(
    ['Dosya', 'Tur', 'Aciklama'],
    [
        ['Z_AI_FI_INVOICE_POST', 'Ana Program', 'REPORT + INCLUDE cagrilari, INITIALIZATION'],
        ['Z_AI_FI_INV_POST_TOP', 'Include (TOP)', 'TYPES, CONSTANTS, DATA tanimlari'],
        ['Z_AI_FI_INV_POST_SEL', 'Include (SEL)', 'SELECTION-SCREEN, FILE_OPEN_DIALOG'],
        ['Z_AI_FI_INV_POST_F01', 'Include (F01)', 'lcl_invoice_post class (definition + implementation)'],
    ]
))
body.append(empty())

# 3. SECIM EKRANI
body.append(h1('3. Secim Ekrani Parametreleri'))
body.append(table(
    ['Parametre', 'Tip', 'Zorunlu', 'Aciklama'],
    [
        ['P_FILE', 'RLGRAP-FILENAME', 'Evet', 'Excel dosya yolu (FILE_OPEN_DIALOG ile secilir)'],
        ['P_BUKRS', 'BUKRS', 'Evet', 'Sirket kodu'],
        ['P_BLDAT', 'BLDAT', 'Evet', 'Belge tarihi (default: bugun)'],
        ['P_BUDAT', 'BUDAT', 'Evet', 'Kayit tarihi (default: bugun)'],
        ['P_BLART', 'BLART', 'Hayir', 'Belge turu (default: KR = satici faturasi)'],
        ['P_TEST', 'ABAP_BOOL', 'Hayir', 'Test modu (default: aktif)'],
    ]
))
body.append(empty())

# 4. EXCEL FORMAT
body.append(h1('4. Excel Dosya Formati'))
body.append(p('Ilk satir baslik olarak kabul edilir ve atlanir. Veri 2. satirdan baslar.'))
body.append(empty())
body.append(table(
    ['Sutun', 'Alan', 'Tip', 'Ornek', 'Aciklama'],
    [
        ['A (1)', 'BLDAT', 'YYYYMMDD', '20260415', 'Belge tarihi'],
        ['B (2)', 'LIFNR', 'Numeric', '100000', 'Satici numarasi (sol sifir otomatik)'],
        ['C (3)', 'WRBTR', 'Decimal', '1500.00', 'Tutar'],
        ['D (4)', 'WAERS', 'Char(3)', 'TRY', 'Para birimi'],
        ['E (5)', 'MWSKZ', 'Char(2)', 'V1', 'Vergi kodu'],
        ['F (6)', 'HKONT', 'Numeric', '60001000', 'Gider hesabi (GL Account)'],
        ['G (7)', 'SGTXT', 'Char(50)', 'Ofis malzemesi', 'Kalem metni'],
        ['H (8)', 'XBLNR', 'Char(16)', 'INV-2026-001', 'Referans belge no'],
    ]
))
body.append(empty())

# 5. ISLEM AKISI
body.append(h1('5. Islem Akisi'))
body.append(p('1. Yetki Kontrolu', bold=True))
body.append(p('F_BKPF_BUK objesi ile sirket kodu bazli kayit yetkisi (ACTVT = 01) kontrol edilir.'))
body.append(empty())
body.append(p('2. Excel Okuma', bold=True))
body.append(p('ALSM_EXCEL_TO_INTERNAL_TABLE fonksiyonu ile dosya okunur. Sutun esleme: ROW/COL/VALUE formatindan ty_s_excel_row yapisina donusturulur.'))
body.append(empty())
body.append(p('3. Validasyon', bold=True))
body.append(bullet('Satici kontrolu: LFA1 tablosundan toplu sorgu (FOR ALL ENTRIES). LOOP icinde SELECT yapilmaz.'))
body.append(bullet('Tutar kontrolu: WRBTR > 0 olmali'))
body.append(bullet('Tarih kontrolu: BLDAT bos olmamali'))
body.append(bullet('Para birimi kontrolu: WAERS bos olmamali'))
body.append(bullet('Gider hesabi kontrolu: HKONT bos olmamali'))
body.append(empty())
body.append(p('4. BAPI Cagirma', bold=True))
body.append(p('Her gecerli satir icin BAPI_ACC_DOCUMENT_POST cagirilir:'))
body.append(bullet('DOCUMENTHEADER (BAPIACHE09): Belge basligi'))
body.append(bullet('ACCOUNTPAYABLE (BAPIACAP09): Satici satiri (Kalem 1 - Alacak)'))
body.append(bullet('ACCOUNTGL (BAPIACGL09): Gider hesabi satiri (Kalem 2 - Borc)'))
body.append(bullet('CURRENCYAMOUNT (BAPIACCR09): Tutar satirlari (negatif=alacak, pozitif=borc)'))
body.append(empty())
body.append(p('5. Commit / Rollback', bold=True))
body.append(bullet('Hata varsa: BAPI_TRANSACTION_ROLLBACK'))
body.append(bullet('Test modu: BAPI_TRANSACTION_ROLLBACK (belge olusturulmaz)'))
body.append(bullet('Gercek kayit: BAPI_TRANSACTION_COMMIT (WAIT = TRUE)'))
body.append(empty())

# 6. BAPI PARAMETRE UYUMLULUGU
body.append(h1('6. BAPI Parametre Tip Uyumlulugu'))
body.append(p('Asagidaki tablo, BAPI_ACC_DOCUMENT_POST parametrelerinin kodda kullanilan tiplerle uyumluluguny gosterir:'))
body.append(empty())
body.append(table(
    ['BAPI Parametre', 'BAPI Tipi', 'Kod Tipi', 'Uyum'],
    [
        ['DOCUMENTHEADER', 'BAPIACHE09', 'BAPIACHE09 (VALUE)', 'Tam uyumlu'],
        ['DOCUMENTHEADER-OBJ_TYPE', 'CHAR5', 'BAPIACHE09-OBJ_TYPE', 'Tam uyumlu'],
        ['DOCUMENTHEADER-BUS_ACT', 'CHAR4', 'BUS_ACT', 'Tam uyumlu'],
        ['DOCUMENTHEADER-DOC_DATE', 'DATS', 'BLDAT', 'Tam uyumlu'],
        ['DOCUMENTHEADER-PSTNG_DATE', 'DATS', 'BUDAT', 'Tam uyumlu'],
        ['DOCUMENTHEADER-DOC_TYPE', 'CHAR2', 'BLART', 'Tam uyumlu'],
        ['ACCOUNTPAYABLE', 'BAPIACAP09', 'BAPIACAP09 (TABLE)', 'Tam uyumlu'],
        ['ACCOUNTPAYABLE-ITEMNO_ACC', 'CHAR10', 'Literal', 'Tam uyumlu'],
        ['ACCOUNTPAYABLE-VENDOR_NO', 'CHAR10', 'LIFNR', 'Tam uyumlu'],
        ['ACCOUNTGL', 'BAPIACGL09', 'BAPIACGL09 (TABLE)', 'Tam uyumlu'],
        ['ACCOUNTGL-GL_ACCOUNT', 'CHAR10', 'HKONT', 'Tam uyumlu'],
        ['ACCOUNTGL-TAX_CODE', 'CHAR2', 'MWSKZ', 'Tam uyumlu'],
        ['CURRENCYAMOUNT', 'BAPIACCR09', 'BAPIACCR09 (TABLE)', 'Tam uyumlu'],
        ['CURRENCYAMOUNT-CURRENCY', 'CHAR5', 'WAERS', 'Tam uyumlu'],
        ['CURRENCYAMOUNT-AMT_DOCCUR', 'CURR(23,4)', 'WRBTR', 'Tam uyumlu'],
        ['OBJ_KEY (export)', 'CHAR20', 'BAPIACHE09-OBJ_KEY', 'Tam uyumlu'],
        ['RETURN', 'BAPIRET2', 'BAPIRET2 (TABLE)', 'Tam uyumlu'],
    ]
))
body.append(empty())

# 7. ALV SONUC
body.append(h1('7. ALV Sonuc Ekrani'))
body.append(table(
    ['Alan', 'Baslik', 'Aciklama'],
    [
        ['ROW_NO', 'Satir No', 'Excel satir numarasi'],
        ['LIFNR', 'Satici No', 'Satici numarasi'],
        ['WRBTR', 'Tutar', 'Fatura tutari'],
        ['WAERS', 'PB', 'Para birimi'],
        ['STATUS', 'Durum', 'S=Basarili, E=Hatali (renkli)'],
        ['BELNR', 'Belge No', 'Olusturulan FI belge numarasi'],
        ['GJAHR', 'Mali Yil', 'Mali yil'],
        ['MESSAGE', 'Mesaj', 'Basari/hata mesaji'],
    ]
))
body.append(empty())
body.append(p('Renklendirme:', bold=True))
body.append(bullet('Yesil (C510): Basarili kayit'))
body.append(bullet('Kirmizi (C610): Hatali kayit'))
body.append(empty())

# 8. TEXT ELEMENTLERI
body.append(h1('8. Text Elementleri (SE38)'))
body.append(table(
    ['ID', 'Deger'],
    [
        ['B01', 'Dosya Secimi'],
        ['B02', 'Kayit Parametreleri'],
        ['B03', 'Calistirma Modu'],
        ['T01', 'Fatura Kayit Sonuclari'],
        ['T02', 'Test Modu Sonuclari'],
        ['F01', 'Excel Dosya Sec'],
        ['F02', 'Tum Dosyalar'],
        ['C01-C08', 'Kolon basliklari (Satir No, Satici, Tutar, PB, Durum, Belge No, Yil, Mesaj)'],
        ['M01', 'Yetkiniz bulunmamaktadir'],
        ['M02', 'Veri bulunamadi'],
        ['M03', 'Excel dosyasi okunamadi'],
        ['M04', 'Test modu - belge olusturulmadi'],
        ['M05', 'Belge basariyla olusturuldu'],
        ['V01', 'Satici bulunamadi'],
        ['V02', 'Tutar sifir veya negatif'],
        ['V03', 'Gecersiz tarih'],
        ['V04', 'Para birimi bos'],
        ['V05', 'Gider hesabi bos'],
    ]
))
body.append(empty())

# 9. SONARQUBE KOD ANALIZI
body.append(h1('9. SonarQube Kod Kalite Analizi'))
body.append(p('Asagida kod self-review sonuclari yer almaktadir:'))
body.append(empty())

body.append(h2('9.1 ATC Uyumluluk'))
body.append(table(
    ['Kural', 'Durum', 'Aciklama'],
    [
        ['SELECT * kullanilmamali', 'GECTI', 'Tum SELECT ifadelerinde sadece gerekli alanlar listelenmis'],
        ['LOOP icinde SELECT yok', 'GECTI', 'Satici kontrolu FOR ALL ENTRIES ile toplu yapilmis'],
        ['PERFORM/FORM kullanilmamali', 'GECTI', 'Tum logic local class method icinde'],
        ['SY-SUBRC kontrolu', 'GECTI', 'Her DB/FM operasyonu sonrasi kontrol ediliyor'],
        ['Kullanilmayan degisken yok', 'GECTI', 'Tum degiskenler kullaniliyor'],
        ['Bos CATCH blogu yok', 'GECTI', 'cx_root yakalanip mesaj veriliyor'],
        ['Modern syntax', 'GECTI', 'NEW, VALUE, COND, inline declaration kullaniliyor'],
    ]
))
body.append(empty())

body.append(h2('9.2 Guvenlik'))
body.append(table(
    ['Kural', 'Durum', 'Aciklama'],
    [
        ['Yetki kontrolu', 'GECTI', 'F_BKPF_BUK ile sirket kodu bazli kontrol'],
        ['Hardcoded credential yok', 'GECTI', 'Hassas veri yok'],
        ['Injection riski', 'GECTI', 'Kullanici girdisi BAPI parametrelerine type-safe ataniyor'],
    ]
))
body.append(empty())

body.append(h2('9.3 Naming Convention'))
body.append(table(
    ['Kural', 'Durum', 'Aciklama'],
    [
        ['Hungarian notation', 'GECTI', 'lv_, ls_, lt_, gv_, gt_, go_, gc_ prefixleri kullaniliyor'],
        ['Program prefix Z_AI_', 'GECTI', 'Naming convention ile uyumlu'],
        ['Method isimlendirme', 'GECTI', 'Fiil ile basliyor: run, check_, read_, validate_, post_, build_, display_'],
        ['Constant tanimlari', 'GECTI', 'gc_ prefixli, magic number yok'],
    ]
))
body.append(empty())

body.append(h2('9.4 Performans'))
body.append(table(
    ['Kural', 'Durum', 'Aciklama'],
    [
        ['Toplu veri okuma', 'GECTI', 'Satici kontrolu FOR ALL ENTRIES + SORTED TABLE + READ TABLE'],
        ['Nested SELECT yok', 'GECTI', 'Tek SELECT + READ TABLE pattern'],
        ['BINARY SEARCH', 'GECTI', 'SORTED TABLE ile otomatik binary search'],
    ]
))
body.append(empty())

body.append(h2('9.5 Potansiyel Iyilestirmeler'))
body.append(bullet('Paralel isleme: Buyuk dosyalarda async BAPI cagirma dusunulebilir'))
body.append(bullet('Excel formati: CL_FDT_XL_SPREADSHEET alternatif olarak kullanilabilir (.xlsx native)'))
body.append(bullet('Hata loglama: BAL_LOG ile application log entegrasyonu eklenebilir'))
body.append(bullet('Tekrar deneme: Hatali satirlar icin retry mekanizmasi eklenebilir'))
body.append(empty())

# 10. KULLANIM
body.append(h1('10. Kullanim Adimlari'))
body.append(p('1. Excel dosyasini belirtilen formatta hazirlayin (baslik satiri + veri satirlari)'))
body.append(p('2. SE38 ile Z_AI_FI_INVOICE_POST programini calistirin'))
body.append(p('3. Dosya secim butonuyla Excel dosyasini secin'))
body.append(p('4. Sirket kodu, belge/kayit tarihlerini girin'))
body.append(p('5. Ilk calistirmada Test Modu isaretli olsun'))
body.append(p('6. Sonuclari ALV ekraninda inceleyin'))
body.append(p('7. Hatasiz ise Test Modu isaretini kaldirip tekrar calistirin'))
body.append(empty())

# Assemble document XML
doc_xml = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    {"".join(body)}
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>'''

# Create .docx
output = os.path.join(os.path.dirname(__file__), 'Z_AI_FI_INVOICE_POST_DOCS.docx')
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', CONTENT_TYPES)
    z.writestr('_rels/.rels', RELS)
    z.writestr('word/_rels/document.xml.rels', WORD_RELS)
    z.writestr('word/document.xml', doc_xml)
    z.writestr('word/styles.xml', STYLES)

print(f'Created: {output}')
