FUNCTION zai_001_fm_get_cus_statement.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_KUNNR) TYPE  KUNNR
*"     VALUE(IV_BUKRS) TYPE  BUKRS
*"     VALUE(IV_BEGDA) TYPE  BEGDA
*"     VALUE(IV_ENDDA) TYPE  ENDDA
*"     VALUE(IV_REVERSED) TYPE  FINS_XREVERSED
*"  EXPORTING
*"     VALUE(ET_DATA) TYPE  ZAI_001_TT_STATEMENT
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"----------------------------------------------------------------------

  FIELD-SYMBOLS <fs_datatab>        TYPE ANY TABLE.
  FIELD-SYMBOLS <fs_datalin>        TYPE any.


  DATA lr_data         TYPE REF TO data.
  DATA lv_msg          TYPE string.
  DATA lt_return       TYPE bapiret2_t.
  DATA ltr_kunnr       TYPE RANGE OF kunnr.
  DATA ltr_bukrs       TYPE RANGE OF bukrs.
  DATA ltr_budat       TYPE RANGE OF budat.
  DATA ls_items        TYPE rfposxext.

  IF "iv_kunnr IS INITIAL OR
     iv_bukrs IS INITIAL OR
     iv_begda IS INITIAL OR
     iv_endda IS INITIAL .

    MESSAGE e010(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.

  ENDIF.


  IF iv_bukrs IS NOT INITIAL.
    SELECT SINGLE @abap_true
      FROM t001
      INTO @DATA(lv_exist)
     WHERE bukrs EQ @iv_bukrs.
    IF sy-subrc NE 0.
      MESSAGE e014(zai) INTO lv_msg WITH iv_bukrs.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.
    ENDIF.

  ENDIF.

  IF iv_kunnr IS NOT INITIAL.
    SELECT SINGLE @abap_true
      FROM knb1
      INTO @lv_exist
     WHERE kunnr EQ @iv_kunnr
       AND bukrs EQ @iv_bukrs.
    IF sy-subrc NE 0.
      MESSAGE e016(zai) INTO lv_msg WITH iv_kunnr.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.
    ENDIF.

  ENDIF.


  IF iv_endda < iv_begda .

    MESSAGE e011(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.

  ENDIF.


  IF lt_return IS INITIAL.

    cl_salv_bs_runtime_info=>set( EXPORTING display  = abap_false metadata = abap_false data = abap_true ).


    ltr_bukrs = VALUE #(
                          LET s = 'I'
                              o = 'EQ'
                          IN sign   = s
                             option = o
                             ( low = iv_bukrs ) ).

    IF iv_kunnr IS NOT INITIAL.
      ltr_kunnr = VALUE #(
                            LET s = 'I'
                                o = 'EQ'
                            IN sign   = s
                               option = o
                               ( low = iv_kunnr ) ).
    ENDIF.


    INSERT VALUE #( sign = 'I' option = 'BT' low = iv_begda high = iv_endda ) INTO TABLE ltr_budat.

    EXPORT p1 = abap_true TO MEMORY ID 'ZFI_KOLAY_MUTABAKAT'.
    sy-tcode = 'FBL5N'.
    SUBMIT rfitemar
      WITH dd_kunnr   IN ltr_kunnr
      WITH dd_bukrs   IN ltr_bukrs
      WITH x_aisel    EQ abap_true  " tüm kalemler
      WITH so_budat   IN ltr_budat
      WITH x_norm     EQ abap_true          "
      WITH x_shbv     EQ abap_false
      WITH x_merk     EQ abap_false
      WITH x_park     EQ abap_false
      WITH x_apar     EQ abap_false
      WITH x_stop     EQ abap_true
       AND RETURN.

    TRY.

        cl_salv_bs_runtime_info=>get_data_ref( IMPORTING r_data = lr_data ).
        ASSIGN lr_data->* TO <fs_datatab>.
        IF <fs_datatab> IS ASSIGNED.

          DATA(lv_where) = 'U_STBLG IS INITIAL'.

          LOOP AT <fs_datatab> ASSIGNING <fs_datalin> WHERE (lv_where).

            ls_items = CORRESPONDING #( BASE ( ls_items ) <fs_datalin> ).

            IF iv_reversed EQ abap_false.
              CLEAR lv_exist.
              SELECT SINGLE @abap_true
                FROM bkpf
                INTO @lv_exist
               WHERE bukrs EQ @ls_items-bukrs
                 AND belnr EQ @ls_items-belnr
                 AND gjahr EQ @ls_items-gjahr
                 AND stblg NE @space.
              IF sy-subrc EQ 0.
                CONTINUE.
              ENDIF.
            ENDIF.

            APPEND INITIAL LINE TO et_data ASSIGNING FIELD-SYMBOL(<ls_data>).
            <ls_data> = CORRESPONDING #( BASE ( <ls_data> ) ls_items ).
            <ls_data>-waers    = ls_items-waers.
            <ls_data>-waers_up = ls_items-hwaer.

            "H  Alacak
            "S  Borç
            IF ls_items-shkzg EQ 'H'.

              <ls_data>-alacak    = ls_items-wrshb .
              <ls_data>-alacak_up = ls_items-dmshb .
            ELSE.

              <ls_data>-borc      = ls_items-wrshb .
              <ls_data>-borc_up   = ls_items-dmshb .

            ENDIF.

            <ls_data>-tutar    = <ls_data>-borc + <ls_data>-alacak.
            <ls_data>-tutar_up = <ls_data>-borc_up + <ls_data>-alacak_up.


          ENDLOOP.
        ELSE .

          MESSAGE e013(zai) INTO lv_msg.
          PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                             USING syst
                                                   lv_msg.


        ENDIF.

      CATCH cx_salv_bs_sc_runtime_info.

        RAISE unable_retrieve_alv_data.

    ENDTRY.

    cl_salv_bs_runtime_info=>clear_all( ).
  ENDIF.

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
