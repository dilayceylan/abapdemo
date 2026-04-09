FUNCTION zai_001_fm_get_inv_inbox.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_UNAME) TYPE  SYUNAME OPTIONAL
*"     VALUE(IV_EMAIL) TYPE  AD_SMTPADR OPTIONAL
*"  EXPORTING
*"     VALUE(ET_INBOX) TYPE  ZAI_001_TT_INBOX
*"     VALUE(ET_WFAPP) TYPE  ZAI_001_TT_WFAPP
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"----------------------------------------------------------------------

  DATA : lt_response  TYPE zfi_001_tt_list
       , ltr_statu    TYPE zfi_001_tt_range_statu
       , lt_return    TYPE bapiret2_t
       , lv_msg       TYPE string
       , ls_header    TYPE zfi_001_st_head
       , lt_items     TYPE zfi_001_tt_items
       , lt_notes     TYPE zfi_001_tt_notes
       , lt_wfhistory TYPE zfi_001_tt_wfhistory
       , lt_document  TYPE zfi_001_tt_document
*       , lt_return    TYPE bapiret2_t
       , lv_comment   TYPE comment.




  IF iv_uname IS NOT INITIAL.
    sy-uname = iv_uname.

    SELECT SINGLE @abap_true
      FROM usr01
      INTO @DATA(lv_exist)
     WHERE bname EQ @iv_uname.
    IF sy-subrc NE 0.

      MESSAGE e001(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.

  ELSEIF iv_email IS NOT INITIAL AND iv_uname IS INITIAL.
    TRANSLATE iv_email TO UPPER CASE.
    SELECT SINGLE pernr
      FROM pa0105
     WHERE subty EQ '0010'
       AND begda LE @sy-datum
       AND endda GE @sy-datum
       AND upper( usrid_long ) = @iv_email
      INTO @DATA(lv_userid). "sy-uname
    sy-uname = lv_userid.
    IF sy-subrc NE 0.

      MESSAGE e001(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.
  ELSE.

    MESSAGE e000(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.

  ENDIF.

  IF  lt_return IS INITIAL.

    INSERT VALUE #( sign = 'I' option = 'EQ' low = '10' ) INTO TABLE ltr_statu.

    CALL FUNCTION 'ZFI_001_FM_GET_LIST'
      EXPORTING
        it_statu    = ltr_statu
      IMPORTING
        et_response = lt_response.

    LOOP AT lt_response INTO DATA(ls_response).

      CLEAR : ls_header
            , lt_items
            , lt_notes
            , lt_wfhistory
            , lt_document
            , lt_return.



      CALL FUNCTION 'ZFI_001_FM_GET_DETAIL_FATURA'
        EXPORTING
          iv_guid      = ls_response-eguid
        IMPORTING
          es_header    = ls_header
          et_items     = lt_items
          et_notes     = lt_notes
          et_wfhistory = lt_wfhistory
          et_document  = lt_document
          et_return    = lt_return.


      APPEND INITIAL LINE TO et_inbox ASSIGNING FIELD-SYMBOL(<ls_inbox>).
      <ls_inbox> = CORRESPONDING #( BASE ( <ls_inbox> ) ls_response ).


      LOOP AT lt_wfhistory INTO DATA(ls_wfhistory).
        APPEND INITIAL LINE TO et_wfapp ASSIGNING FIELD-SYMBOL(<ls_wfapp>).
        <ls_wfapp> = CORRESPONDING #( BASE ( <ls_wfapp> ) ls_wfhistory ).
        <ls_wfapp>-eguid = ls_response-eguid.
      ENDLOOP.

*      MOVE-CORRESPONDING lt_wfhistory TO <ls_inbox>-wfapp[].

    ENDLOOP.
*    et_inbox[] = lt_response[].
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
