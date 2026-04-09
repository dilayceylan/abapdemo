FUNCTION zai_001_fm_get_sales_order.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BEGDA) TYPE  BEGDA OPTIONAL
*"     VALUE(IV_ENDDA) TYPE  ENDDA OPTIONAL
*"  EXPORTING
*"     VALUE(ET_SALESORDER) TYPE  ZAI_001_TT_SALES_ORDER
*"     VALUE(ET_RETURN) TYPE  ZAI_001_ST_RETURN
*"----------------------------------------------------------------------

  DATA : ltr_date  TYPE RANGE OF sy-datum

       , lt_return TYPE bapiret2_t
       , lr_data   TYPE REF TO data
       , lv_msg    TYPE string.


  FIELD-SYMBOLS <fs_data>  TYPE ANY TABLE.

  IF iv_begda IS NOT INITIAL AND iv_endda IS INITIAL.
    INSERT VALUE #( sign = 'I' option = 'EQ' low = iv_begda ) INTO TABLE ltr_date.
  ELSEIF iv_endda IS NOT INITIAL.
    INSERT VALUE #( sign = 'I' option = 'BT' low = iv_begda high = iv_endda ) INTO TABLE ltr_date.
  ELSE.

    MESSAGE e002(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.

  ENDIF.


  IF ( iv_endda - iv_begda ) > 365.

    MESSAGE e003(zai) INTO lv_msg.
    PERFORM add_syst_mess_to_bapiret2 TABLES lt_return
                                       USING syst
                                             lv_msg.

  ENDIF.

  IF lt_return IS INITIAL.

    cl_salv_bs_runtime_info=>set( EXPORTING display  = abap_false metadata = abap_false data = abap_true ).

    SUBMIT zsd037r
      WITH erdat   IN ltr_date
       AND RETURN.


    TRY.
        cl_salv_bs_runtime_info=>get_data_ref( IMPORTING r_data = lr_data ).
        ASSIGN lr_data->* TO <fs_data>.


        LOOP AT <fs_data> ASSIGNING FIELD-SYMBOL(<ls_data>).
          APPEND INITIAL LINE TO et_salesorder ASSIGNING FIELD-SYMBOL(<ls_salesorder>).
          <ls_salesorder> = CORRESPONDING #( BASE ( <ls_salesorder> ) <ls_data> ).

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
