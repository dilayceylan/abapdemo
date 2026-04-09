FUNCTION zai_001_fm_crt_complete_wi.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_APPROVE) TYPE  ZAI_001_ST_COMPLETE_WI
*"  EXPORTING
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"----------------------------------------------------------------------

  DATA : ls_header    TYPE zfi_001_st_head
       , lt_items     TYPE zfi_001_tt_items
       , lt_notes     TYPE zfi_001_tt_notes
       , lt_wfhistory TYPE zfi_001_tt_wfhistory
       , lt_document  TYPE zfi_001_tt_document
       , lt_return    TYPE bapiret2_t
       , lv_comment   TYPE comment
       , lv_msg       TYPE string.




  CALL FUNCTION 'ZFI_001_FM_GET_DETAIL_FATURA'
    EXPORTING
      iv_guid      = is_approve-eguid
    IMPORTING
      es_header    = ls_header
      et_items     = lt_items
      et_notes     = lt_notes
      et_wfhistory = lt_wfhistory
      et_document  = lt_document
      et_return    = lt_return.

  IF ls_header IS INITIAL.

    MESSAGE e005(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.
  ENDIF.


  IF is_approve-approver_userid IS NOT INITIAL.
    sy-uname = is_approve-approver_userid.

    SELECT SINGLE @abap_true
      FROM usr01
      INTO @DATA(lv_exist)
     WHERE bname EQ @is_approve-approver_userid.
    IF sy-subrc NE 0.

      MESSAGE e001(zai) INTO lv_msg.
      PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                         USING syst
                                               lv_msg.

    ENDIF.

  ELSEIF is_approve-approver_mail IS NOT INITIAL AND is_approve-approver_userid IS INITIAL.
    TRANSLATE is_approve-approver_mail TO UPPER CASE.
    SELECT SINGLE pernr
      FROM pa0105
     WHERE subty EQ '0010'
       AND begda LE @sy-datum
       AND endda GE @sy-datum
       AND upper( usrid_long ) = @is_approve-approver_mail
      INTO @DATA(lv_userid). "sy-uname
    sy-uname = lv_userid.
    is_approve-approver_userid = lv_userid.
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


  DATA(ls_wfhistory) = VALUE #( lt_wfhistory[ decision = 10 ] OPTIONAL ).
  IF sy-uname NE ls_wfhistory-objid.

    MESSAGE e008(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.

  ENDIF.

  IF lt_return IS INITIAL.
    sy-uname = is_approve-approver_userid.
    CALL FUNCTION 'ZFI_001_FM_CRT_FATURA'
      EXPORTING
        is_header     = ls_header
        it_items      = lt_items
        it_notes      = lt_notes
        it_wfhistory  = lt_wfhistory
        iv_process    = CONV char3( is_approve-wi_result )
        iv_wf_comment = is_approve-comment "lv_comment
      IMPORTING
        et_return     = lt_return.
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
