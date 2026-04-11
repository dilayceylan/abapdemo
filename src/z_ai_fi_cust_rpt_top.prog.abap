*&---------------------------------------------------------------------*
*& Include:   Z_AI_FI_CUST_RPT_TOP
*& Açıklama:  Tip tanımları, veri tanımları, sabitler
*& Yazar:     Claude AI
*& Tarih:     2026-04
*& Paket:     ZAI_CLAUDE
*&---------------------------------------------------------------------*

" Constants
CONSTANTS: gc_status_success TYPE char1 VALUE 'S',
           gc_status_error   TYPE char1 VALUE 'E',
           gc_structure_name TYPE dd02l-tabname VALUE 'ZST_AI_CUSTOMER'.

" Output structure for ALV
TYPES: BEGIN OF ty_s_output,
         bukrs      TYPE bukrs,
         butxt      TYPE butxt,
         kunnr      TYPE kunnr,
         name1      TYPE name1_gp,
         ort01      TYPE ort01,
         pstlz      TYPE pstlz,
         land1      TYPE land1,
         stras      TYPE stras_gp,
         telf1      TYPE telf1,
         erdat      TYPE erdat,
         cellcolor  TYPE lvc_t_scol,
       END OF ty_s_output,
       ty_t_output TYPE STANDARD TABLE OF ty_s_output WITH EMPTY KEY.

" Global data
DATA: gt_output    TYPE ty_t_output,
      go_container TYPE REF TO cl_gui_custom_container,
      go_alv_grid  TYPE REF TO cl_gui_alv_grid.

" Helper variables for selection screen field references
DATA: gv_bukrs TYPE bukrs,
      gv_kunnr TYPE kunnr.
