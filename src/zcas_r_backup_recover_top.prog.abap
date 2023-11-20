*&---------------------------------------------------------------------*
*& Include zcas_r_backup_recover_top
*&---------------------------------------------------------------------*
CONTROLS: main_tabstrip TYPE TABSTRIP.

CONSTANTS: cv_backup_clnt_dir   TYPE saepfad VALUE 'C:\Backup',
           cv_container_name    TYPE scrfname VALUE 'BCALV_BACKUP_0100_CONT1',
           cv_default_trans_dir TYPE saepfad VALUE 'DIR_TRANS'. " AL11

DATA: screen_id TYPE sy-dynnr,
      ok_code   LIKE sy-ucomm,
      save_ok   LIKE sy-ucomm,
      error     TYPE abap_bool.

DATA: gv_msg TYPE string.

DATA: gr_grid      TYPE REF TO cl_gui_alv_grid,
      gr_container TYPE REF TO cl_gui_custom_container,
      gs_layout    TYPE lvc_s_layo,
      gt_fieldcat  TYPE lvc_t_fcat.

DATA: gs_request      TYPE trwbo_request,
      gt_sub_requests TYPE trwbo_request_headers,
      gt_outtab       TYPE TABLE OF tadir,
      gt_package      TYPE TABLE OF tdevc. " dient nur als Schablone für Form-Parameter

DATA: gt_dynpfields_backup  TYPE dynpread_tabtype,
      gt_dynpfields_recover TYPE dynpread_tabtype.

" Backup-Parameter
DATA: p_backup_clnt_dir  TYPE saepfad VALUE cv_backup_clnt_dir,
      p_backup_incl_subs TYPE abap_bool,
      p_trkorr           TYPE e070-trkorr,
      p_chk_del_tr       TYPE abap_bool VALUE abap_true,
      p_devclass         TYPE tadir-devclass,
      p_devobject        TYPE tadir-obj_name.

" Recover-Parameter
DATA: p_recover_file   TYPE saepfad,
      p_recover_dir    TYPE saepfad VALUE cv_default_trans_dir,
      p_target_system  TYPE c LENGTH 7,
      p_overwrite_orig TYPE abap_bool,
      p_only_append    TYPE abap_bool.
