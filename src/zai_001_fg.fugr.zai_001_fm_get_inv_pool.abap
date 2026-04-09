FUNCTION zai_001_fm_get_inv_pool.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BEGDA) TYPE  BEGDA OPTIONAL
*"     VALUE(IV_ENDDA) TYPE  ENDDA OPTIONAL
*"  EXPORTING
*"     VALUE(ET_INVOICE) TYPE  ZAI_001_TT_INVOICE_POOL
*"     VALUE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
  DATA ltr_bldat TYPE RANGE OF bldat.

  IF iv_begda IS NOT INITIAL AND iv_endda IS INITIAL.
    INSERT VALUE #( sign = 'I' option = 'EQ' low = iv_begda ) INTO TABLE ltr_bldat.
  ELSEIF iv_begda IS NOT INITIAL AND iv_endda IS NOT INITIAL.
    INSERT VALUE #( sign = 'I' option = 'BT' low = iv_begda  high = iv_endda ) INTO TABLE ltr_bldat.
  ENDIF.


  WITH

  +invoice AS (
    SELECT z1~eguid
         , z1~xblnr
         , z1~lifnr
         , concat_with_space( z3~name1, z3~name2,1 ) AS name1
         , z2~seqnr
         , z2~objid
         , p1~ename

    FROM zfi_001_t_head        AS z1
   INNER JOIN zfi_001_t_wfapp  AS z2  ON z1~eguid EQ z2~eguid
    LEFT JOIN lfa1             AS z3  ON z3~lifnr EQ z1~lifnr
    LEFT JOIN pa0001           AS p1  ON p1~pernr EQ z2~objid
                                     AND p1~begda LE @sy-datum
                                     AND p1~endda GE @sy-datum
    )

  SELECT DISTINCT
          z1~eguid
*       , z1~direct
*       , z1~statu
*       , z1~stcfr
*       , z1~stcto
*       , z1~koart
*       , z1~konto
*       , z1~bukrs
*       , z1~awtyp
*       , z1~awkey
       , z1~xblnr
*       , z1~profileid
*       , z1~invoicetypecode
*       , z1~docnum
       , z1~bldat
*       , z1~ptdat
*       , z1~ptzet
*       , z1~wmwst
*       , z1~wrbtr
*       , z1~waers
*       , z1~bstkd
*       , z1~hierarchy_code
*       , z1~upnam
       , z3~lifnr
       , concat_with_space( z3~name1, z3~name2,1 ) AS name1
*       , +invoice~seqnr
       , +invoice~objid
       , +invoice~ename

    FROM  /isistr/ef001         AS z1
    LEFT JOIN lfa1              AS z3  ON z3~stcd2       EQ z1~stcfr
    LEFT JOIN +invoice                 ON +invoice~lifnr EQ z3~lifnr

   WHERE 1 = 1
*         AND z1~eguid  EQ '1AF31A1B-7FB3-4D84-8E90-39D47478ACEA'
*         and z1~eguid  IN @so_guid
     AND z1~direct EQ '2'
*         AND z1~stcfr  IN @so_stcfr
*         AND z1~bukrs  IN @so_bukrs
*         AND z1~statu  IN @so_statu
     AND z1~eguid  NOT IN ( SELECT eguid FROM zfi_001_t_eihide )
     AND z1~eguid  NOT IN ( SELECT eguid FROM zfi_001_t_head )
     AND z1~xblnr  NOT IN ( SELECT efaturano FROM zfi_002_t_items )
     AND z1~stcfr  NE '5700026709'
     AND z1~bldat  IN @ltr_bldat
   ORDER BY z1~eguid, z1~xblnr
    INTO TABLE @DATA(lt_data).


  et_invoice =  VALUE #( FOR ls_data IN lt_data ( eguid           = ls_data-eguid
                                                  xblnr           = ls_data-xblnr
                                                  bldat           = ls_data-bldat
                                                  lifnr           = ls_data-lifnr
                                                  lifnr_t         = ls_data-name1
                                                  approved_userid = ls_data-objid
                                                  approved_name   = ls_data-ename   ) ).


ENDFUNCTION.
