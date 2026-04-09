*----------------------------------------------------------------------*
***INCLUDE LZAI_001_FGF01.
*----------------------------------------------------------------------*
FORM add_syst_mess_to_bapiret2 TABLES ct_messages TYPE bapiret2_t
                                USING is_syst     TYPE syst
                                      iv_message.

  DATA : ls_messages TYPE bapiret2.

  ls_messages-id         = is_syst-msgid.
  ls_messages-number     = is_syst-msgno.
  ls_messages-type       = is_syst-msgty.
  ls_messages-message_v1 = is_syst-msgv1.
  ls_messages-message_v2 = is_syst-msgv2.
  ls_messages-message_v3 = is_syst-msgv3.
  ls_messages-message_v4 = is_syst-msgv4.

  IF iv_message IS NOT INITIAL.
    ls_messages-message    = iv_message.
  ELSE.
    CONCATENATE is_syst-msgv1 is_syst-msgv2
                is_syst-msgv3 is_syst-msgv4
           INTO ls_messages-message
      SEPARATED BY space.
  ENDIF.

  APPEND ls_messages TO ct_messages[].
ENDFORM.
