FUNCTION zai_001_fm_get_employee_list.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_DATE) TYPE  BEGDA OPTIONAL
*"  EXPORTING
*"     VALUE(ET_DATA) TYPE  ZAI_001_TT_EMPLOYEE
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"----------------------------------------------------------------------

  DATA lv_msg    TYPE string.
  DATA lt_return TYPE bapiret2_t.
  DATA lv_date   TYPE sy-datum.

* Tarih parametresi bos ise bugunun tarihini kullan
  IF iv_date IS INITIAL.
    lv_date = sy-datum.
  ELSE.
    lv_date = iv_date.
  ENDIF.

  IF lt_return IS INITIAL.

*   Adim 1: Verilen tarihte aktif personelleri PA0001'den al
    SELECT DISTINCT a~pernr
      FROM pa0001 AS a
     WHERE a~begda <= @lv_date
       AND a~endda >= @lv_date
      INTO TABLE @DATA(lt_active_pernr).

    IF lt_active_pernr IS INITIAL.

      MESSAGE e013(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.

  ENDIF.

  IF lt_return IS INITIAL.

*   PERNR range olustur
    DATA ltr_pernr TYPE RANGE OF pernr_d.
    LOOP AT lt_active_pernr INTO DATA(ls_active).
      INSERT VALUE #( sign = 'I' option = 'EQ' low = ls_active-pernr )
        INTO TABLE ltr_pernr.
    ENDLOOP.

*   Adim 2: Ad ve soyad bilgilerini PA0002'den al
    SELECT pernr, vorna AS firstname, nachn AS lastname
      FROM pa0002
     WHERE pernr IN @ltr_pernr
       AND begda <= @lv_date
       AND endda >= @lv_date
      INTO TABLE @DATA(lt_pa0002).

*   Adim 3: E-posta adreslerini PA0105 subtype 0010'dan al
    SELECT pernr, usrid_long AS email
      FROM pa0105
     WHERE pernr IN @ltr_pernr
       AND subty  = '0010'
       AND begda <= @lv_date
       AND endda >= @lv_date
      INTO TABLE @DATA(lt_pa0105).

*   Adim 4: Ise giris tarihini PA0001 MIN(BEGDA) ile hesapla
    SELECT pernr, MIN( begda ) AS hire_date
      FROM pa0001
     WHERE pernr IN @ltr_pernr
     GROUP BY pernr
      INTO TABLE @DATA(lt_hire_date).

*   Adim 5: Cikis tablosunu olustur
    LOOP AT lt_pa0002 INTO DATA(ls_pa0002).
      APPEND INITIAL LINE TO et_data ASSIGNING FIELD-SYMBOL(<ls_emp>).
      <ls_emp>-pernr     = ls_pa0002-pernr.
      <ls_emp>-firstname = ls_pa0002-firstname.
      <ls_emp>-lastname  = ls_pa0002-lastname.

*     E-posta
      READ TABLE lt_pa0105 INTO DATA(ls_pa0105)
        WITH KEY pernr = ls_pa0002-pernr.
      IF sy-subrc = 0.
        <ls_emp>-email = ls_pa0105-email.
      ENDIF.

*     Calisma gunu hesapla (takvim gunu)
      READ TABLE lt_hire_date INTO DATA(ls_hire)
        WITH KEY pernr = ls_pa0002-pernr.
      IF sy-subrc = 0.
        <ls_emp>-working_days = lv_date - ls_hire-hire_date.
      ENDIF.

    ENDLOOP.

    IF et_data IS INITIAL.

      MESSAGE e013(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.

  ENDIF.

* Standart return pattern
  LOOP AT lt_return TRANSPORTING NO FIELDS WHERE type CA 'EAX'.
    EXIT.
  ENDLOOP.
  IF sy-subrc EQ 0.

    et_return-code    = '1'.
    et_return-message = VALUE #( lt_return[ type = 'E' ]-message OPTIONAL ).

  ELSE.

    et_return-code    = '0'.
    et_return-message = VALUE #( lt_return[ type = 'S' ]-message OPTIONAL ).

  ENDIF.


ENDFUNCTION.
