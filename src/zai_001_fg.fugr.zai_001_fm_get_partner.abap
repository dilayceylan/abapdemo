FUNCTION zai_001_fm_get_partner.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_PARTNER) TYPE  BU_PARTNER OPTIONAL
*"     VALUE(IV_NAME) TYPE  BU_NAMEOR1 OPTIONAL
*"  EXPORTING
*"     VALUE(ET_DATA) TYPE  ZAI_001_TT_PARTNER
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"----------------------------------------------------------------------

  DATA lv_msg          TYPE string.
  DATA lt_return       TYPE bapiret2_t.
  DATA ltr_partner     TYPE RANGE OF bu_partner.
  DATA ltr_name        TYPE RANGE OF bu_nameor1.

*  IF iv_partner IS INITIAL AND iv_name IS INITIAL.
*
*    MESSAGE e012(zai) INTO lv_msg.
*    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
*                                       USING syst
*                                             lv_msg.
*
*  ENDIF.

  IF lt_return IS INITIAL.

    IF iv_partner IS NOT INITIAL.
      ltr_partner = VALUE #(
                            LET s = 'I'
                                o = 'EQ'
                            IN sign   = s
                               option = o
                               ( low  = iv_partner ) ).
    ENDIF.

    IF iv_name IS NOT INITIAL.
      TRANSLATE iv_name TO UPPER CASE.
      TRANSLATE iv_name USING 'İIÖOÜUŞSÇCĞGıI'.
      TRANSLATE iv_name USING ' *'.
      ltr_name  = VALUE #(
                            LET s = 'I'
                                o = 'CP'
                            IN sign   = s
                               option = o
                               ( low  =  iv_name && '*' ) ).
    ENDIF.


    SELECT t1~partner
         , t1~name_org1 AS name
         , t2~taxnum
      FROM but000            AS t1
      LEFT JOIN dfkkbptaxnum AS t2   ON t1~partner EQ t2~partner
                                    AND t2~taxtype EQ 'TR2'

    WHERE t1~partner            IN @ltr_partner
      AND t1~bu_group           IN ('YDGD','YDGI','YIGD','YIGI')
      AND upper( replace( replace( replace( replace( replace( replace( name_org1,'Ç', 'C' ),'İ','I' ),'Ö','O' ),'Ü','U' ),'Ş','S' ), 'Ğ','G' ) ) IN  @ltr_name
      AND xblck                 EQ @space
     INTO TABLE @et_data.

    IF et_data IS INITIAL.

      MESSAGE e013(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.

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

*



ENDFUNCTION.
