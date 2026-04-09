FUNCTION ZAI_001_FM_GET_BP_CREDIT_LIMIT.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_PARTNER) TYPE  BU_PARTNER OPTIONAL
*"     VALUE(IV_CREDIT_SGMNT) TYPE  UKM_CREDIT_SGMNT OPTIONAL
*"  EXPORTING
*"     VALUE(ET_CREDITLIMIT) TYPE  UKM_T_BP_CMS_MALUSDSP_OUT
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"--------------------------------------------------------------------


  DATA : lr_data          TYPE REF TO data
       , lv_msg           TYPE string
       , ltr_partner      TYPE RANGE OF bu_partner
       , ltr_credit_sgmnt TYPE RANGE OF ukm_credit_sgmnt
       , lt_return        TYPE bapiret2_t.

  IF iv_partner IS INITIAL.

    MESSAGE e012(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.


  ELSE.
    INSERT VALUE #( sign = 'I' option = 'EQ' low = iv_partner )  INTO TABLE ltr_partner.
  ENDIF.

  IF iv_credit_sgmnt IS INITIAL.

*    MESSAGE e010(zai) INTO lv_msg.
*    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
*                                       USING syst
*                                             lv_msg.


  ELSE.
    INSERT VALUE #( sign = 'I' option = 'EQ' low = iv_credit_sgmnt )  INTO TABLE ltr_credit_sgmnt.
  ENDIF.
  FIELD-SYMBOLS <fs_data>  TYPE ANY TABLE.


  IF lt_return IS INITIAL.

    cl_salv_bs_runtime_info=>set( EXPORTING display  = abap_false metadata = abap_false data = abap_true ).

    SUBMIT ukm_malus_display
      WITH o_bupa   IN ltr_partner
      WITH  o_crsgm IN ltr_credit_sgmnt
       AND RETURN.

    TRY.
        cl_salv_bs_runtime_info=>get_data_ref( IMPORTING r_data = lr_data ).
        ASSIGN lr_data->* TO <fs_data>.

        LOOP AT <fs_data> ASSIGNING FIELD-SYMBOL(<ls_data>).
          APPEND INITIAL LINE TO et_creditlimit ASSIGNING FIELD-SYMBOL(<ls_creditlimit>).
          <ls_creditlimit> = CORRESPONDING #( BASE ( <ls_creditlimit> ) <ls_data> ).

        ENDLOOP.

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
