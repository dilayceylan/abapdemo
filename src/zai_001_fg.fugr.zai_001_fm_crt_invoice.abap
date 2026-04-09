FUNCTION zai_001_fm_crt_invoice.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST) TYPE  ZAI_001_ST_INVOICE OPTIONAL
*"  EXPORTING
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"----------------------------------------------------------------------

  DATA : ls_head   TYPE zfi_001_t_head
       , lt_wfapp  TYPE TABLE OF zfi_001_t_wfapp
       , lv_msg    TYPE string
       , lt_return TYPE bapiret2_t
       , ls_header    TYPE zfi_001_st_head
       , lt_items     TYPE zfi_001_tt_items
       , lt_notes     TYPE zfi_001_tt_notes
       , lt_wfhistory TYPE zfi_001_tt_wfhistory
       , lt_document  TYPE zfi_001_tt_document
*       , lt_return    TYPE bapiret2_t
       , lv_comment   TYPE comment.
*       , lv_msg       TYPE string.


  IF request-eguid IS NOT INITIAL.

    SELECT SINGLE z1~*
      FROM /isistr/ef001 AS z1
     INNER JOIN lfa1    AS t1 ON t1~stcd2 EQ z1~stcfr
      INTO @DATA(ls_ef001)
     WHERE direct IN ('1','2')
       AND eguid  EQ @request-eguid.

    IF sy-subrc NE 0.
      SELECT SINGLE @abap_true
        FROM zfi_001_t_head
       WHERE eguid      EQ @request-eguid
         AND belge_turu EQ '2'
        INTO @DATA(lv_exist).
    ENDIF.


    IF sy-subrc EQ 0.

    ELSE.

      MESSAGE e005(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.



  ELSEIF request-xblnr IS NOT INITIAL AND request-lifnr IS NOT INITIAL.

    SELECT SINGLE z1~*
      FROM /isistr/ef001 AS z1
     INNER JOIN lfa1    AS t1 ON t1~stcd2 EQ z1~stcfr
      INTO @ls_ef001
     WHERE direct EQ '2'
       AND xblnr  EQ @request-xblnr
       AND lifnr  EQ @request-lifnr.
    IF sy-subrc EQ 0 .

    ELSE.
      MESSAGE e006(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.
  ENDIF.

  IF request-approver_userid IS NOT INITIAL AND request-approver_mail IS INITIAL.

    MESSAGE e009(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.


*  ENDIF.

  ELSEIF request-approver_mail IS NOT INITIAL AND request-approver_userid IS INITIAL.
    TRANSLATE request-approver_mail TO UPPER CASE.
    SELECT SINGLE pernr
      FROM pa0105
     WHERE subty EQ '0010'
       AND begda LE @sy-datum
       AND endda GE @sy-datum
       AND upper( usrid_long ) = @request-approver_mail
      INTO @DATA(lv_userid). "sy-uname
*    sy-uname = lv_userid.
    request-approver_userid = lv_userid.
    IF sy-subrc NE 0.

      MESSAGE e009(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.

  ENDIF.

  IF request-add_mail IS NOT INITIAL AND request-add_userid IS INITIAL.
    CLEAR lv_userid.
    TRANSLATE request-add_mail TO UPPER CASE.
    SELECT SINGLE pernr
      FROM pa0105
     WHERE subty EQ '0010'
       AND begda LE @sy-datum
       AND endda GE @sy-datum
       AND upper( usrid_long ) = @request-add_mail
      INTO @lv_userid. "sy-uname
    request-add_userid = lv_userid.
    IF sy-subrc NE 0.

      MESSAGE e001(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.

  ELSEIF request-add_mail IS INITIAL AND request-add_userid IS NOT INITIAL.

    MESSAGE e004(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.

  ENDIF.



  IF lt_return IS INITIAL.

    CALL FUNCTION 'ZFI_001_FM_GET_DETAIL_FATURA'
      EXPORTING
        iv_guid      = request-eguid
      IMPORTING
        es_header    = ls_header
        et_items     = lt_items
        et_notes     = lt_notes
        et_wfhistory = lt_wfhistory
        et_document  = lt_document
        et_return    = lt_return.

    DATA(ls_wfhistory) = VALUE #( lt_wfhistory[ decision = 10 ] OPTIONAL ).

    IF ls_header IS INITIAL.
      CLEAR ls_head.
      ls_head-eguid       = ls_ef001-eguid.
      ls_head-bukrs       = ls_ef001-bukrs.
      ls_head-wrbtr       = ls_ef001-wrbtr - ls_ef001-wmwst.
      ls_head-waers       = ls_ef001-waers.
      ls_head-bldat       = ls_ef001-bldat.
      ls_head-lifnr       = ls_ef001-konto.
      ls_head-xblnr       = ls_ef001-xblnr.
      ls_head-frstid      = request-frstid.
      ls_head-crt_name    = request-add_userid.
      ls_head-crt_date    = sy-datum.
      ls_head-crt_time    = sy-uzeit.

      MODIFY zfi_001_t_head FROM ls_head.
    ENDIF.

    SELECT *
      FROM zfi_001_t_wfapp
      INTO TABLE @DATA(lt_wfapp_db)
     WHERE eguid EQ @ls_ef001-eguid.


    CLEAR lt_wfapp.
    APPEND INITIAL LINE TO lt_wfapp ASSIGNING FIELD-SYMBOL(<ls_wfapp>).
    <ls_wfapp>-bukrs      = request-bukrs.
    <ls_wfapp>-eguid      = request-eguid.
    <ls_wfapp>-seqnr      = lines( lt_wfapp_db ) + 1.
    <ls_wfapp>-otype      = 'US'.
    <ls_wfapp>-objid      = request-approver_userid.
    <ls_wfapp>-decision   = COND #( WHEN ls_wfhistory IS NOT INITIAL THEN ' ' ELSE  '10' ).
    <ls_wfapp>-add_userid = request-add_userid.
    <ls_wfapp>-add_date   = sy-datum.
    <ls_wfapp>-add_time   = sy-uzeit.


    IF sy-subrc EQ 0 .

      MODIFY zfi_001_t_wfapp FROM TABLE lt_wfapp.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.


      MESSAGE s007(zai) INTO lv_msg.
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

ENDFUNCTION.
