*&---------------------------------------------------------------------*
*& Report  ZCAS_R_BACKUP_RECOVER [08.03.2021-001]
*&---------------------------------------------------------------------*
REPORT zcas_r_backup_recover.

"$. Region Declarations

CONTROLS: main_tabstrip TYPE TABSTRIP.

CONSTANTS: cv_backup_clnt_dir   TYPE saepfad VALUE 'C:\Backup',
           cv_container_name    TYPE scrfname VALUE 'BCALV_BACKUP_0100_CONT1',
           cv_default_trans_dir TYPE saepfad VALUE 'DIR_TRANS'. " AL11

DATA: screen_id TYPE sy-dynnr,
      ok_code   LIKE sy-ucomm,
      save_ok   LIKE sy-ucomm,
      error     TYPE abap_bool.

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

"$. Endregion Declarations

"$. Region Main

*---------------------------------------------------------------------*
*       MAIN                                                          *
*---------------------------------------------------------------------*

PERFORM init.

CALL SCREEN 100.

*&---------------------------------------------------------------------*
*&      Form  INIT
*&---------------------------------------------------------------------*
FORM init.

  CALL 'C_SAPGPARAM'
    ID 'NAME'  FIELD p_recover_dir
    ID 'VALUE' FIELD p_recover_dir.

  CONCATENATE sy-sysid '.' sy-mandt INTO p_target_system.

  gt_dynpfields_backup = VALUE #( ( fieldname = 'P_BACKUP_CLNT_DIR' )
                                  ( fieldname = 'P_TRKORR' )
                                  ( fieldname = 'P_CHK_DEL_TR' )
                                  ( fieldname = 'P_DEVCLASS' )
                                  ( fieldname = 'P_DEVOBJECT' )
                                  ( fieldname = 'P_BACKUP_INCL_SUBS' ) ).
  gt_dynpfields_recover = VALUE #( ( fieldname = 'P_RECOVER_FILE' )
                                   ( fieldname = 'P_RECOVER_DIR' )
                                   ( fieldname = 'P_OVERWRITE_ORIG' )
                                   ( fieldname = 'P_ONLY_APPEND' ) ).

ENDFORM.                    "init

"$. Endregion Main

"$. Region Modules

MODULE on_value_request_trkorr INPUT.

  DATA: lt_results TYPE STANDARD TABLE OF ddshretval WITH DEFAULT KEY.

  SELECT FROM e070
    FIELDS *
    WHERE trstatus EQ @sctsc_state_changeable
      AND as4user  EQ @sy-uname
      AND strkorr  EQ @space
    INTO TABLE @DATA(lt_help_values).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      ddic_structure = 'E070'
      retfield       = 'TRKORR'
      dynpprog       = sy-repid
      dynpnr         = sy-dynnr
      window_title   = 'Transport Request'
      value_org      = 'S'
    TABLES
      value_tab      = lt_help_values
      return_tab     = lt_results
    EXCEPTIONS
      OTHERS         = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Build of Search Help-Pop Up failed.' TYPE 'E' DISPLAY LIKE 'I'.
  ENDIF.

  DATA(lt_dynpfields) = VALUE dynpread_tabtype( ( fieldname = 'P_TRKORR'
                                                  fieldvalue = VALUE #( lt_results[ 1 ]-fieldval OPTIONAL ) ) ).

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname               = sy-repid
      dynumb               = sy-dynnr
    TABLES
      dynpfields           = lt_dynpfields
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      undefind_error       = 7
      OTHERS               = 8.

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE PBO OUTPUT                                             *
*---------------------------------------------------------------------*
MODULE pbo_0100 OUTPUT.

  DATA: ls_fieldcat TYPE lvc_s_fcat.

  SET PF-STATUS 'MAIN100'.

  IF gr_container IS INITIAL.

    CREATE OBJECT gr_container
      EXPORTING
        container_name = cv_container_name.

    CREATE OBJECT gr_grid
      EXPORTING
        i_parent = gr_container.

    gs_layout-edit = abap_false.
    gs_layout-no_toolbar = abap_true.
    gs_layout-sel_mode = 'A'.

    REFRESH: gt_fieldcat.
    CLEAR: ls_fieldcat.

    " Spaltenbreite optimieren
    ls_fieldcat-fieldname  = 'OBJECT'.
    ls_fieldcat-outputlen = '7'.
    APPEND ls_fieldcat TO gt_fieldcat.

    " Spalten ausblenden
    ls_fieldcat-fieldname  = 'PGMID'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'KORRNUM'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'SRCSYSTEM'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'SRCDEP'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'GENFLAG'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'EDTFLAG'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'CPROJECT'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'MASTERLANG'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'VERSID'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'PAKNOCHECK'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'OBJSTABLTY'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'COMPONENT'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'CRELEASE'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'DELFLAG'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'TRANSLTTXT'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'CREATED_ON'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'CHECK_DATE'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.
    ls_fieldcat-fieldname  = 'CHECK_CFG'.
    ls_fieldcat-no_out = 'X'.
    APPEND ls_fieldcat TO gt_fieldcat.

    PERFORM show_table.

  ENDIF.

  CASE main_tabstrip-activetab.
    WHEN 'BACKUP_TAB'.
      screen_id = '101'.

    WHEN 'RECOVER_TAB'.
      screen_id = '102'.

    WHEN OTHERS.
      screen_id = '101'.

  ENDCASE.

ENDMODULE.                    "pbo_0100 OUTPUT
*---------------------------------------------------------------------*
*       MODULE PAI INPUT                                              *
*---------------------------------------------------------------------*
MODULE pai_0100 INPUT.

  error = abap_false.
  save_ok = ok_code.
  CLEAR ok_code.

  PERFORM read_values.

  CASE save_ok.
    WHEN 'BACKUP_TAB' OR 'RECOVER_TAB'.
      main_tabstrip-activetab = save_ok.

    WHEN 'EXEC'.
      CASE main_tabstrip-activetab.
        WHEN 'BACKUP_TAB'.
          PERFORM backup_execute.

        WHEN 'RECOVER_TAB'.
          PERFORM recover_execute.

      ENDCASE.

    WHEN 'BACKUP_CHS_PATH'.
      PERFORM backup_chs_des.

    WHEN 'BACKUP_ADD_PKG'.
      PERFORM backup_add_devobjects.

    WHEN 'BACKUP_ADD_OBJ'.
      PERFORM backup_add_devobject.

    WHEN 'BACKUP_DEL_SEL_ROWS'.
      PERFORM backup_del_devobjects
        USING abap_true.

    WHEN 'BACKUP_DEL_ALL_ROWS'.
      PERFORM backup_del_devobjects
        USING abap_false.

    WHEN 'RECOVER_CHS_SRC'.
      PERFORM recover_chs_src.

    WHEN 'RECOVER_CHS_DES'.
      PERFORM recover_chs_des.

  ENDCASE.

ENDMODULE.                    "pai_0100 INPUT
*---------------------------------------------------------------------*
*       MODULE PAI INPUT                                              *
*---------------------------------------------------------------------*
MODULE exit.

  save_ok = ok_code.
  CLEAR ok_code.

  LEAVE PROGRAM.

ENDMODULE.                    "exit

"$. Endregion Modules

"$. Region Backup

*&---------------------------------------------------------------------*
*&      Form  GET_FOLDERNAME_DIALOG
*&---------------------------------------------------------------------*
FORM backup_chs_des.

  DATA: lv_initial_dir  TYPE string VALUE 'C:\',
        lv_selected_dir TYPE string.

  CALL METHOD cl_gui_frontend_services=>directory_browse
    EXPORTING
      initial_folder       = lv_initial_dir
    CHANGING
      selected_folder      = lv_selected_dir
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.

  IF lv_selected_dir IS INITIAL.

    lv_selected_dir = lv_initial_dir.

  ENDIF.

  p_backup_clnt_dir = lv_selected_dir.

ENDFORM.                    "backup_chs_des

*&---------------------------------------------------------------------*
*&      Form  BACKUP_ADD_DEVOBJECTS
*&---------------------------------------------------------------------*
FORM backup_add_devobjects.

  DATA: ls_package TYPE tdevc.

  WHILE error EQ abap_false.

    CASE sy-index.
      WHEN 1.
        PERFORM backup_check_package CHANGING ls_package.

      WHEN 2.
        PERFORM backup_add_packages USING ls_package.

      WHEN 3.
        PERFORM backup_add_devobject.

      WHEN 4.
        PERFORM show_table.

      WHEN 5.
        EXIT.

    ENDCASE.

  ENDWHILE.

ENDFORM.                    "backup_add_devobjects
*&---------------------------------------------------------------------*
*&      Form  backup_check_package
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM backup_check_package CHANGING ls_package TYPE tdevc.

  TRY.
      IF p_devclass CO ' _0'.
        error = abap_true.
        MESSAGE 'Bitte erst den Namen eines Entwicklungsobjekts eingeben.' TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      SELECT SINGLE FROM tdevc
        FIELDS *
        WHERE devclass EQ @p_devclass
        INTO @ls_package.

      IF ls_package IS INITIAL.
        error = abap_true.
        MESSAGE 'Das Entwicklungspaket ist in diesem System nicht vorhanden.' TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF ls_package-as4user EQ 'SAP'.
        error = abap_true.
        MESSAGE 'Das Entwicklungspaket gehört SAP und darf daher nicht gesichert werden.' TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF ls_package-devclass CP '$*'.
        error = abap_true.
        MESSAGE 'Temporäre Entwicklungspakete können nicht gesichert werden.' TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

    CATCH cx_root.
      error = abap_true.
      MESSAGE 'Die Dynpro-Felder konnten nicht ausgelesen werden!' TYPE 'I' DISPLAY LIKE 'E'.
      RETURN.

  ENDTRY.

ENDFORM.                    "backup_check_package
*&---------------------------------------------------------------------*
*&      Form  backup_add_packages
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM backup_add_packages USING ls_package TYPE tdevc.

  DATA: lt_new_package     TYPE STANDARD TABLE OF tdevc,
        lt_new_package_tmp TYPE STANDARD TABLE OF tdevc,
        lt_new_package_sub TYPE STANDARD TABLE OF tdevc.

  " Bereits hinzugefügte Pakete
  DATA: ls_r_package TYPE rsdsselopt,
        lt_r_package TYPE rseloption.

  " Neu hinzuzufügende Pakete
  DATA: lt_r_new_package TYPE rseloption.

  FIELD-SYMBOLS: <ls_outtab>      TYPE tadir,
                 <ls_new_package> TYPE tdevc.

* Logik:
* 1) Paket bereits vorhanden?
*	   - Ja: Nicht hinzufügen
*	   - Nein: Hinzufügen
* 2) Sub-Pakete auslesen
* 3) Schritte 1-2 wiederholen, bis keine Sub-Pakete mehr

  ls_r_package-sign = 'I'.
  ls_r_package-option = 'EQ'.

  APPEND ls_r_package TO lt_r_package.

  " Bereits hinzugefügte Pakete auslesen
  LOOP AT gt_outtab ASSIGNING <ls_outtab>
    WHERE object EQ 'DEVC'.

    ls_r_package-sign = 'I'.
    ls_r_package-option = 'EQ'.
    ls_r_package-low = <ls_outtab>-obj_name.

    APPEND ls_r_package TO lt_r_package.

  ENDLOOP.

  APPEND ls_package TO lt_new_package.

  WHILE lt_new_package IS NOT INITIAL.

    CLEAR: lt_r_new_package, lt_new_package_tmp.

    LOOP AT lt_new_package ASSIGNING <ls_new_package>.

      CLEAR: lt_new_package_sub.

      " Paket zur Tabelle hinzufügen, wenn noch nicht vorhanden
      READ TABLE lt_r_package TRANSPORTING NO FIELDS
        WITH KEY low = <ls_new_package>-devclass.

      IF sy-subrc <> 0.

        ls_r_package-sign = 'I'.
        ls_r_package-option = 'EQ'.
        ls_r_package-low = <ls_new_package>-devclass.

        APPEND ls_r_package TO lt_r_package.
        APPEND ls_r_package TO lt_r_new_package.

        " Paket für das Aufnehmen in die Tabelle vormerken
        APPEND <ls_new_package> TO gt_package.

      ENDIF.

      " Unterpakete berücksichtigen? (J/N)
      IF p_backup_incl_subs EQ abap_true.

        " Untergeordnete Pakete selektieren
        SELECT FROM tdevc
          FIELDS *
          WHERE parentcl EQ @<ls_new_package>-devclass
            AND as4user  NE 'SAP'
          INTO TABLE @lt_new_package_sub.

        APPEND LINES OF lt_new_package_sub TO lt_new_package_tmp.

      ENDIF.

    ENDLOOP.

    lt_new_package[] = lt_new_package_tmp[].

  ENDWHILE.

ENDFORM.                    "backup_add_packages
*&---------------------------------------------------------------------*
*&      Form  backup_add_devobj
*&---------------------------------------------------------------------*
FORM backup_add_devobject.

  DATA: lv_msg_txt          TYPE c LENGTH 300,
        lv_no_outtab_before TYPE i,
        lv_no_outtab_added  TYPE string.

  lv_no_outtab_before = lines( gt_outtab ).

  IF p_devobject CN ' _0'.

    PERFORM backup_add_devobject_by_obj.

  ELSEIF p_devclass CN ' _0'.

    PERFORM backup_add_devobject_by_pck.

  ELSE.

    MESSAGE 'Bitte geben Sie entweder einen Paketnamen oder ein Entwicklungsobjekt an.' TYPE 'S'.
    RETURN.

  ENDIF.

  lv_no_outtab_added = lines( gt_outtab ) - lv_no_outtab_before.

  CONCATENATE lv_no_outtab_added 'Entwicklungsobjekte wurden hinzugefügt.'
    INTO lv_msg_txt SEPARATED BY space.
  MESSAGE lv_msg_txt TYPE 'S'.

  IF p_devobject CN ' _0'.
    PERFORM show_table.
  ENDIF.

ENDFORM.                    "backup_add_devobj
*&---------------------------------------------------------------------*
*&      Form  backup_add_devobject_by_obj
*&---------------------------------------------------------------------*
FORM backup_add_devobject_by_obj.

  DATA: ls_devobj TYPE tadir.

  IF line_exists( gt_outtab[ obj_name = p_devobject ] ).
    MESSAGE 'Entwicklungsobjekt nicht hinzugefügt, da bereits vorhanden.' TYPE 'S'.
    RETURN.
  ENDIF.

  SELECT SINGLE FROM tadir
    FIELDS *
    WHERE obj_name EQ @p_devobject
    INTO @ls_devobj.

  IF ls_devobj-devclass CP '$*'.
    MESSAGE 'Temporäre Entwicklungsobjekte können nicht gesichert werden.' TYPE 'S'.
    RETURN.
  ELSEIF ls_devobj-author EQ 'SAP'.
    MESSAGE 'Das Entwicklungsobjekt gehört SAP und darf daher nicht gesichert werden.' TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  APPEND ls_devobj TO gt_outtab.

ENDFORM. " backup_add_devobject_by_obj
*&---------------------------------------------------------------------*
*&      Form  backup_add_devobject_by_pck
*&---------------------------------------------------------------------*
FORM backup_add_devobject_by_pck.

  DATA: lt_devobj        TYPE TABLE OF tadir.

  DATA: ls_r_package TYPE rsdsselopt,
        lt_r_package TYPE rseloption.

  FIELD-SYMBOLS: <ls_package>       TYPE tdevc,
                 <ls_devobj>        TYPE tadir,
                 <ls_package_tadir> TYPE tadir.

  " Pakete wurden ihrer Hierarchie entsprechend hinzugefügt
  LOOP AT gt_package ASSIGNING <ls_package>.

    ls_r_package-sign = 'I'.
    ls_r_package-option = 'EQ'.
    ls_r_package-low = <ls_package>-devclass.

    APPEND ls_r_package TO lt_r_package.

  ENDLOOP.

  " Damit nicht immer wieder alle Entwicklungsobjekte selektiert
  " werden, sondern nur die der neu hinzugefügten Pakete
  CLEAR: gt_package.

  IF lt_r_package IS INITIAL.
    MESSAGE 'Keine Entwicklungsobjekte hinzugefügt, da bereits vorhanden oder nicht selektierbar.' TYPE 'S'.
    RETURN.
  ENDIF.

  SELECT FROM tadir
    FIELDS *
    WHERE devclass IN @lt_r_package
      AND author   NE 'SAP'
    INTO TABLE @lt_devobj.

  SORT lt_devobj BY obj_name ASCENDING.

  LOOP AT lt_devobj ASSIGNING <ls_package_tadir> WHERE object EQ 'DEVC'.

    APPEND <ls_package_tadir> TO gt_outtab.

    LOOP AT lt_devobj ASSIGNING <ls_devobj> WHERE object   NE 'DEVC'
                                              AND devclass EQ <ls_package_tadir>-devclass.
      APPEND <ls_devobj> TO gt_outtab.
    ENDLOOP.

  ENDLOOP.

ENDFORM. " backup_add_devobj_by_pck
*&---------------------------------------------------------------------*
*&      Form  BACKUP_DEL_DEVOBJECTS
*&---------------------------------------------------------------------*
FORM backup_del_devobjects USING selected TYPE abap_bool.

  DATA: lv_msg_txt           TYPE c LENGTH 300,
        lv_no_outtab_before  TYPE i,
        lv_no_outtab_removed TYPE string.

  DATA: lt_row_no TYPE lvc_t_roid.

  DATA: ls_del_outtab TYPE tadir.

  DATA: lr_s_del_devobj TYPE rsdsselopt,
        lr_t_del_devobj TYPE rseloption.

  FIELD-SYMBOLS: <ls_row_no> TYPE lvc_s_roid.

  lv_no_outtab_before = lines( gt_outtab ).

  CASE selected.
    WHEN abap_true.
      CALL METHOD gr_grid->get_selected_rows
        IMPORTING
          et_row_no = lt_row_no.

      LOOP AT lt_row_no ASSIGNING <ls_row_no>.

        READ TABLE gt_outtab INTO ls_del_outtab INDEX <ls_row_no>-row_id.

        lr_s_del_devobj-sign = 'I'.
        lr_s_del_devobj-option = 'EQ'.
        lr_s_del_devobj-low = ls_del_outtab-obj_name.

        APPEND lr_s_del_devobj TO lr_t_del_devobj.

      ENDLOOP.

      IF lr_t_del_devobj IS NOT INITIAL.

        DELETE gt_outtab WHERE obj_name IN lr_t_del_devobj.

      ENDIF.

    WHEN abap_false.
      CLEAR: gt_outtab.

  ENDCASE.

  lv_no_outtab_removed = lv_no_outtab_before - lines( gt_outtab ).

  CONCATENATE lv_no_outtab_removed 'Entwicklungsobjekte wurden entfernt.'
    INTO lv_msg_txt SEPARATED BY space.
  MESSAGE lv_msg_txt TYPE 'S'.

  PERFORM show_table.

ENDFORM.                    "backup_del_devobjects

FORM read_values.

  CASE main_tabstrip-activetab.
    WHEN 'BACKUP_TAB'.
      DATA(lv_dynnr) = '0101'.
      DATA(lt_dynpfields) = gt_dynpfields_backup.

    WHEN 'RECOVER_TAB'.
      lv_dynnr = '0102'.
      lt_dynpfields = gt_dynpfields_recover.

  ENDCASE.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname               = sy-repid
      dynumb               = lv_dynnr
    TABLES
      dynpfields           = lt_dynpfields
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.

  IF sy-subrc = 0.

    LOOP AT lt_dynpfields ASSIGNING FIELD-SYMBOL(<ls_dynpfield>).

      ASSIGN (<ls_dynpfield>-fieldname) TO FIELD-SYMBOL(<lv_parameter>).
      CHECK <lv_parameter> IS ASSIGNED.

      <lv_parameter> = <ls_dynpfield>-fieldvalue.

      UNASSIGN: <lv_parameter>.

    ENDLOOP.

    IF p_backup_clnt_dir CO ' _0'.
      p_backup_clnt_dir = cv_backup_clnt_dir.
    ENDIF.

    IF p_recover_dir CO ' _0'.
      CALL 'C_SAPGPARAM'
        ID 'NAME'  FIELD cv_default_trans_dir
        ID 'VALUE' FIELD p_recover_dir.
    ENDIF.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BACKUP_EXECUTE
*&---------------------------------------------------------------------*
FORM backup_execute.

  DATA: lv_srvr_file TYPE saepfad,
        lv_clnt_file TYPE saepfad.

  PERFORM backup_check_input.

  WHILE error EQ abap_false.

    CASE sy-index.
      WHEN 1.
        PERFORM create_tr.

      WHEN 2.
        PERFORM read_tr.

      WHEN 3.
        PERFORM append_devobjs_to_tr.

      WHEN 4.
        PERFORM release_tr.

      WHEN 5.
        PERFORM remove_tr_from_queue.

      WHEN 6.
        PERFORM backup_download_files
          USING lv_srvr_file
                lv_clnt_file.

      WHEN 7.
        MESSAGE |Backup wurde erfolgreich erstellt.| TYPE 'S'.
        EXIT.

    ENDCASE.

  ENDWHILE.

  IF gs_request-h-trkorr CN ' _0'.

    CALL FUNCTION 'DEQUEUE_E_TRKORR'
      EXPORTING
        trkorr = gs_request-h-trkorr.

  ENDIF.

ENDFORM.                    "backup_execute

*&---------------------------------------------------------------------*
*&      Form  BACKUP_CHECK_INPUT
*&---------------------------------------------------------------------*
FORM backup_check_input.

  " Eingabe prüfen
  IF p_backup_clnt_dir IS INITIAL.

    error = abap_true.
    MESSAGE |Bitte geben Sie den lokalen Speicherort der Sicherungsdateien an.| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.

  ELSEIF gt_outtab IS INITIAL
     AND p_trkorr IS INITIAL.

    error = abap_true.
    MESSAGE |Bitte definieren Sie einen Transport oder zu sichernde Entwicklungsobjekte.| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.

  ELSEIF p_backup_clnt_dir EQ 'C:\'.

    DATA(lv_answer) = VALUE numc1( ).

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = |Speicherort geeignet?|
        text_question         = |C:\\ ist ggf. aufgrund unzureichender Berechtigungen auf dem Betriebssystem| &&
                                | kein geeigneter Speicherort. Möchten Sie dennoch fortfahren?|
        display_cancel_button = abap_false
      IMPORTING
        answer                = lv_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.

    IF   sy-subrc <> 0
      OR lv_answer = 2.
      p_backup_clnt_dir = cv_backup_clnt_dir.
      error = abap_true.
      RETURN.
    ENDIF.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BACKUP_DOWNLOAD_FILES
*&---------------------------------------------------------------------*
FORM backup_download_files USING lv_srvr_file TYPE saepfad
                                 lv_clnt_file TYPE saepfad.

  DATA: lv_index  TYPE i,
        lv_length TYPE i,
        lv_prefix TYPE c LENGTH 1.

  DATA: lv_clnt_file_sep TYPE c LENGTH 1,
        lv_srvr_file_sep TYPE c LENGTH 1,
        lv_clnt_file_len TYPE i,
        lv_srvr_file_len TYPE i.

  DATA: lv_ta_name         TYPE saepfad,
        lv_sub_dir         TYPE saepfad,
        lv_backup_srvr_dir TYPE saepfad VALUE cv_default_trans_dir.

  lv_length = strlen( gs_request-h-trkorr ).
  gs_request-h-trkorr = gs_request-h-trkorr+4(lv_length).
  CONCATENATE gs_request-h-trkorr '.' sy-sysid INTO lv_ta_name. " 123456.T70

  CALL 'C_SAPGPARAM' ID 'NAME'  FIELD lv_backup_srvr_dir
                     ID 'VALUE' FIELD lv_backup_srvr_dir.

  lv_clnt_file_sep = p_backup_clnt_dir+2(1).
  lv_srvr_file_sep = lv_backup_srvr_dir(1).

  lv_clnt_file_len = strlen( p_backup_clnt_dir ) - 1.
  lv_srvr_file_len = strlen( lv_backup_srvr_dir ) - 1.

  IF p_backup_clnt_dir+lv_clnt_file_len(1) NE lv_clnt_file_sep.
    CONCATENATE p_backup_clnt_dir lv_clnt_file_sep INTO p_backup_clnt_dir. " C:\Backup\
  ENDIF.

  IF lv_backup_srvr_dir+lv_srvr_file_len(1) NE lv_srvr_file_sep.
    CONCATENATE lv_backup_srvr_dir lv_srvr_file_sep INTO lv_backup_srvr_dir. " /usr/sap/trans/
  ENDIF.

  DO 2 TIMES.

    lv_index = sy-index.

    CLEAR: lv_srvr_file, lv_clnt_file.

    CASE lv_index.
      WHEN 1.
        lv_prefix = 'K'.
        lv_sub_dir = 'cofiles'.

      WHEN 2.
        lv_prefix = 'R'.
        lv_sub_dir = 'data'.

    ENDCASE.

    CONCATENATE lv_backup_srvr_dir lv_sub_dir lv_srvr_file_sep lv_prefix lv_ta_name INTO lv_srvr_file. " /usr/trans/cofiles/K123456.T70
    CONCATENATE p_backup_clnt_dir lv_prefix lv_ta_name INTO lv_clnt_file.                        " C:\Backup\K123456.T70

    CALL FUNCTION 'ARCHIVFILE_SERVER_TO_CLIENT'
      EXPORTING
        path       = lv_srvr_file
        targetpath = lv_clnt_file
      EXCEPTIONS
        error_file = 1
        OTHERS     = 2.

    IF sy-subrc <> 0.
      error = abap_true.
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE sy-msgty.
      RETURN.
    ENDIF.

  ENDDO.

ENDFORM.                    "backup_download_files

"$. Endregion Backup

"$. Region Recovery

*&---------------------------------------------------------------------*
*&      Form  RECOVER_EXECUTE
*&---------------------------------------------------------------------*
FORM recover_execute.

  DATA: ls_request TYPE trwbo_request.

  DATA: lv_clnt_k_file TYPE saepfad,
        lv_clnt_r_file TYPE saepfad,
        lv_clnt_dir    TYPE saepfad,
        lv_trkorr      TYPE trkorr.

  PERFORM recover_check_input.

  WHILE error EQ abap_false.

    CASE sy-index.
      WHEN 1.
        PERFORM recover_extract_ta
          CHANGING lv_clnt_k_file
                   lv_clnt_r_file
                   lv_clnt_dir
                   lv_trkorr.

      WHEN 2.
        PERFORM recover_upload_files
          USING lv_clnt_k_file
                lv_clnt_r_file
                lv_clnt_dir.

      WHEN 3.
        PERFORM append_ta_to_queue
          USING lv_trkorr.

      WHEN 4.
        PERFORM import_ta_request
          USING lv_trkorr.

      WHEN 5.
        PERFORM change_original_system
          USING    lv_trkorr
          CHANGING ls_request.

      WHEN 6.
        PERFORM generate_object_list
          USING ls_request.

      WHEN 7.
        MESSAGE |Wiederherstellung wurde erfolgreich durchgeführt.| TYPE 'S'.
        EXIT.

    ENDCASE.

  ENDWHILE.

ENDFORM.                    "recover_execute

*&---------------------------------------------------------------------*
*&      Form  RECOVER_CHECK_INPUT
*&---------------------------------------------------------------------*
FORM recover_check_input.

  " Eingabe prüfen
  IF    p_recover_file NP '+:\*.*'  " Bsp.: C:\R123456.IP3
    AND p_recover_file NP '+:/*.*'. " Bsp.: C:/R123456.IP3

    error = abap_true.
    MESSAGE |Bitte geben Sie den lokalen Speicherort der Wiederherstellungsdatei an.| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.

  ELSEIF p_recover_dir CO ' _0'
      OR p_recover_dir NA '\/'.

    error = abap_true.
    MESSAGE |Bitte geben Sie den internen Pfad zum Wiederherstellungsordner an.| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  RECOVER_GET_FILE
*&---------------------------------------------------------------------*
FORM recover_chs_src.

  DATA: lv_initial_folder TYPE string VALUE 'C:\',
        lt_selected_file  TYPE filetable,
        lv_return_code    TYPE i,
        ls_selected_file  TYPE file_table.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      initial_directory       = lv_initial_folder
      multiselection          = abap_false
    CHANGING
      file_table              = lt_selected_file
      rc                      = lv_return_code
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  READ TABLE lt_selected_file INTO ls_selected_file INDEX 1.

  IF sy-subrc <> 0
    OR lv_return_code <> 1
    OR lt_selected_file IS INITIAL.

    CLEAR: p_recover_file.

  ELSE.

    p_recover_file = ls_selected_file-filename.

  ENDIF.

ENDFORM.                    "recover_get_file
*&---------------------------------------------------------------------*
*&      Form  recover_chs_des
*&---------------------------------------------------------------------*
FORM recover_chs_des.

  DATA: lv_sap_dir TYPE saepfad.

  CALL 'C_SAPGPARAM'
    ID 'NAME'  FIELD cv_default_trans_dir
    ID 'VALUE' FIELD lv_sap_dir.

  CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
    EXPORTING
      directory        = lv_sap_dir
    IMPORTING
      serverfile       = p_recover_dir
    EXCEPTIONS
      canceled_by_user = 1
      OTHERS           = 2.

  IF   sy-subrc <> 0
    OR p_recover_dir CO ' _0'.

    p_recover_dir = lv_sap_dir.

  ENDIF.

ENDFORM.                    "recover_get_file
*&---------------------------------------------------------------------*
*&      Form  RECOVER_EXTRACT_TA
*&---------------------------------------------------------------------*
FORM recover_extract_ta CHANGING lv_clnt_k_file TYPE saepfad
                                 lv_clnt_r_file TYPE saepfad
                                 lv_clnt_dir    TYPE saepfad
                                 lv_trkorr      TYPE trkorr.

  DATA: lv_lines   TYPE i,
        lv_length  TYPE i,
        lv_ta_part TYPE saepfad.

  DATA: lv_clnt_dir_sep TYPE c LENGTH 1.

  DATA: lt_part TYPE TABLE OF saepfad.

  lv_clnt_dir_sep = p_recover_file+2(1).

  SPLIT p_recover_file AT lv_clnt_dir_sep INTO TABLE lt_part.    " C: und R123456.IP3
  DESCRIBE TABLE lt_part LINES lv_lines.             " 2
  READ TABLE lt_part INTO lv_ta_part INDEX lv_lines. " R123456.IP3
  lv_ta_part = lv_ta_part+1.                         " 123456.IP3

  lv_length = strlen( lv_ta_part ) - 3.
  CONCATENATE lv_ta_part+lv_length(4) 'K' lv_ta_part(lv_length) INTO lv_trkorr. " IP3K123456.
  lv_length = strlen( lv_trkorr ) - 1.                                          " 10
  lv_trkorr = lv_trkorr(lv_length).                                             " IP3K123456

  CONCATENATE: 'K' lv_ta_part INTO lv_clnt_k_file, " K123456.IP3
               'R' lv_ta_part INTO lv_clnt_r_file. " R123456.IP3

  DO lv_lines - 1 TIMES.

    READ TABLE lt_part INTO lv_ta_part INDEX sy-index.
    CONCATENATE lv_clnt_dir lv_ta_part lv_clnt_dir_sep INTO lv_clnt_dir. " C:\

  ENDDO.

ENDFORM.                    "recover_extract_ta
*&---------------------------------------------------------------------*
*&      Form  RECOVER_UPLOAD_FILES
*&---------------------------------------------------------------------*
FORM recover_upload_files USING lv_clnt_k_file TYPE saepfad
                                lv_clnt_r_file TYPE saepfad
                                lv_clnt_dir    TYPE saepfad.

  DATA: lv_srvr_dir_sep TYPE c LENGTH 1,
        lv_srvr_dir_len TYPE i.

  DATA: lv_index     TYPE i,
        lv_srvr_dir  TYPE saepfad,
        lv_clnt_file TYPE saepfad,
        lv_srvr_file TYPE saepfad.

  lv_srvr_dir_sep = p_recover_dir(1).
  lv_srvr_dir_len = strlen( p_recover_dir ) - 1.

  IF p_recover_dir+lv_srvr_dir_len(1) NE lv_srvr_dir_sep.

    CONCATENATE p_recover_dir lv_srvr_dir_sep INTO p_recover_dir. " /usr/sap/trans/

  ENDIF.

  DO 2 TIMES.

    CLEAR: lv_clnt_file,
           lv_srvr_dir,
           lv_srvr_file.

    lv_index = sy-index.

    CASE lv_index.
      WHEN 1.
        lv_clnt_file = lv_clnt_k_file.

        CONCATENATE p_recover_dir 'cofiles' lv_srvr_dir_sep INTO lv_srvr_dir.

        CONCATENATE lv_clnt_dir lv_clnt_k_file INTO lv_clnt_file.
        CONCATENATE lv_srvr_dir lv_clnt_k_file INTO lv_srvr_file.

      WHEN 2.
        lv_clnt_file = lv_clnt_r_file.

        CONCATENATE p_recover_dir 'data' lv_srvr_dir_sep INTO lv_srvr_dir.

        CONCATENATE lv_clnt_dir lv_clnt_r_file INTO lv_clnt_file.
        CONCATENATE lv_srvr_dir lv_clnt_r_file INTO lv_srvr_file.

    ENDCASE.

    " Prüfen, ob Datei bereits auf Server vorhanden
    OPEN DATASET lv_srvr_file FOR INPUT IN BINARY MODE.

    IF sy-subrc <> 0.

      " Nicht vorhanden: Datei hochladen
      CALL FUNCTION 'ARCHIVFILE_CLIENT_TO_SERVER'
        EXPORTING
          path       = lv_clnt_file
          targetpath = lv_srvr_file
        EXCEPTIONS
          error_file = 1
          OTHERS     = 2.

      IF sy-subrc <> 0.

        error = abap_true.
        MESSAGE |Die Datei-Übertragung ist fehlgeschlagen!| TYPE 'I' DISPLAY LIKE 'E'.
        RETURN.

      ENDIF.

    ENDIF.

  ENDDO.

ENDFORM.                    "recover_upload_files

*&---------------------------------------------------------------------*
*&      Form  change_original_system
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LV_TRKORR  text
*      <--LS_REQUEST text
*----------------------------------------------------------------------*
FORM change_original_system USING    lv_trkorr  TYPE trkorr
                            CHANGING ls_request TYPE trwbo_request.

  DATA: lv_srcsystem TYPE srcsystem.

  DATA: lt_r_objname TYPE RANGE OF trobj_name,
        ls_r_objname LIKE LINE OF  lt_r_objname.

  FIELD-SYMBOLS: <ls_object> TYPE trwbo_s_e071.

  CHECK p_only_append EQ abap_false.

  ls_request-h-trkorr = lv_trkorr.

  CALL FUNCTION 'TR_READ_REQUEST'
    EXPORTING
      iv_read_e070       = 'X'
      iv_read_e07t       = 'X'
      iv_read_e070c      = 'X'
      iv_read_e070m      = 'X'
      iv_read_objs_keys  = 'X'
      iv_read_attributes = 'X'
    CHANGING
      cs_request         = ls_request
    EXCEPTIONS
      OTHERS             = 1.

  IF sy-subrc <> 0.
    error = abap_true.
    MESSAGE |TA { lv_trkorr } konnte nicht ausgelesen werden.| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT ls_request-objects ASSIGNING <ls_object> WHERE pgmid NE 'CORR'.

    ls_r_objname-sign   = 'I'.
    ls_r_objname-option = 'EQ'.
    ls_r_objname-low    = <ls_object>-obj_name.
    APPEND ls_r_objname TO lt_r_objname.

  ENDLOOP.

  SELECT FROM tadir
    FIELDS object, obj_name, pgmid
    WHERE obj_name   IN @lt_r_objname
      AND (    masterlang NE @sy-langu
            OR srcsystem  NE @sy-sysid )
    INTO TABLE @DATA(lt_tadir).

  CHECK lt_tadir IS NOT INITIAL.

  lv_srcsystem = sy-sysid.

  " Über importierte Entwicklungsobjekte laufen und SRCSYSTEM und MASTERLANG ändern
  LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

    CALL FUNCTION 'TRINT_TADIR_MODIFY'
      EXPORTING
        masterlang           = sy-langu
        object               = <ls_tadir>-object
        obj_name             = <ls_tadir>-obj_name
        pgmid                = <ls_tadir>-pgmid
        srcsystem            = lv_srcsystem
        change_masterlang    = abap_true
        exists               = abap_true
      EXCEPTIONS
        object_exists_global = 1
        object_exists_local  = 2
        object_has_no_tadir  = 3
        OTHERS               = 4.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

  ENDLOOP.

ENDFORM.                    "change_original_system

*&---------------------------------------------------------------------*
*&      Form  generate_object_list
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LS_REQUEST text
*----------------------------------------------------------------------*
FORM generate_object_list USING ls_request TYPE trwbo_request.

  DATA: lv_syntax_error TYPE seu_bool,
        lv_tree_name    TYPE eu_t_name.

  FIELD-SYMBOLS: <ls_object> TYPE trwbo_s_e071.

  CHECK p_only_append EQ abap_false.

  LOOP AT ls_request-objects ASSIGNING <ls_object> WHERE object EQ 'DEVC'.

    CONCATENATE 'EU_' <ls_object>-obj_name INTO lv_tree_name.

    " Actualize the tree in the database.
    " Package Names always begin with 'EU_'.
    CALL FUNCTION 'WB_TREE_ACTUALIZE'
      EXPORTING
        tree_name              = lv_tree_name
        without_crossreference = abap_true
        with_tcode_index       = abap_true
      IMPORTING
        syntax_error           = lv_syntax_error.

    IF lv_syntax_error IS NOT INITIAL.
      CONTINUE.
    ENDIF.

  ENDLOOP.

ENDFORM.                    "generate_object_list

"$. Endregion Recovery

"$. Region General Functions

*&---------------------------------------------------------------------*
*&      Form  SHOW_TABLE
*&---------------------------------------------------------------------*
FORM show_table.

  CALL METHOD gr_grid->set_table_for_first_display
    EXPORTING
      i_structure_name = 'TADIR'
      is_layout        = gs_layout
    CHANGING
      it_outtab        = gt_outtab
      it_fieldcatalog  = gt_fieldcat.

ENDFORM.                    "show_table

*&---------------------------------------------------------------------*
*&      Form  CREATE_TA_REQUEST
*&---------------------------------------------------------------------*
FORM create_tr.

  DATA: lv_request_type LIKE e070-trfunction,
        lv_as4text      TYPE e07t-as4text,
        lv_target       TYPE e070-tarsystem,
        ls_new_tr       TYPE trwbo_request_header.

  CHECK p_trkorr IS INITIAL.

  lv_request_type = 'T'. " Transport of Copies
  lv_as4text = |{ sy-sysid }: Backup { sy-datum } { sy-uzeit }|.
  lv_target = sy-sysid.

  CALL FUNCTION 'TR_INSERT_REQUEST_WITH_TASKS'
    EXPORTING
      iv_type            = lv_request_type
      iv_text            = lv_as4text
      iv_target          = lv_target
      iv_with_badi_check = abap_true
    IMPORTING
      es_request_header  = ls_new_tr
    EXCEPTIONS
      insert_failed      = 1
      enqueue_failed     = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    error = abap_true.
    MESSAGE |Fehler beim Anlegen eines TAs.| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  MOVE-CORRESPONDING ls_new_tr TO gs_request-h.

ENDFORM.                    "create_ta_request
*&---------------------------------------------------------------------*
*&      Form  APPEND_TO_TA_REQUEST
*&---------------------------------------------------------------------*
FORM append_devobjs_to_tr.

  DATA: ls_e071 TYPE trwbo_s_e071,
        lt_e071 TYPE trwbo_t_e071.

  FIELD-SYMBOLS: <ls_outtab> TYPE tadir.

  CHECK p_trkorr IS INITIAL.

  CALL FUNCTION 'ENQUEUE_E_TRKORR'
    EXPORTING
      trkorr         = gs_request-h-trkorr
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2.

  IF sy-subrc <> 0.
    error = abap_true.
    MESSAGE |Fehler beim Sperren des TAs { gs_request-h-trkorr }.| &&
            |Bitte in der SE01 -> { sy-uname } den TA manuell löschen!| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_outtab ASSIGNING <ls_outtab>.

    ls_e071-pgmid = <ls_outtab>-pgmid.
    ls_e071-object = <ls_outtab>-object.
    ls_e071-obj_name = <ls_outtab>-obj_name.

    APPEND ls_e071 TO lt_e071.

  ENDLOOP.

  CALL FUNCTION 'TRINT_APPEND_TO_COMM_ARRAYS'
    EXPORTING
      wi_error_table     = abap_true
      wi_trkorr          = gs_request-h-trkorr
      iv_append_at_order = abap_true
    TABLES
      wt_e071            = lt_e071
    EXCEPTIONS
      OTHERS             = 1.

  IF sy-subrc <> 0.

    error = abap_true.
    MESSAGE |Fehler beim Hinzufügen der Objekte zum TA { gs_request-h-trkorr }.| &&
            |Bitte in der SE01 -> { sy-uname } den TA manuell löschen!| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.

  ELSE.

    COMMIT WORK AND WAIT.

  ENDIF.

ENDFORM.                    "append_to_ta_request

FORM read_tr.

  DATA(lt_requests) = VALUE trwbo_requests( ).
  CALL FUNCTION 'TR_READ_REQUEST_WITH_TASKS'
    EXPORTING
      iv_trkorr          = p_trkorr
    IMPORTING
      et_requests        = lt_requests
      et_request_headers = gt_sub_requests
    EXCEPTIONS
      invalid_input      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    error = abap_true.
    MESSAGE |Fehler beim Lesen des TAs { p_trkorr } (sy-subrc = { sy-subrc }).| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  gs_request = VALUE #( lt_requests[ h-trkorr = p_trkorr ] OPTIONAL ).
  DELETE gt_sub_requests WHERE trkorr EQ gs_request-h-trkorr.

  IF gs_request-h-strkorr IS NOT INITIAL.
    error = abap_true.
    MESSAGE |Untergeordnete TAs werden nicht unterstützt! Der TA { gs_request-h-trkorr } | &&
            |ist dem TA { gs_request-h-strkorr } untergeordnet.| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  RELEASE_TA_REQUEST
*&---------------------------------------------------------------------*
FORM release_tr.

  CHECK gs_request-h-trstatus NE sctsc_state_released.

  DATA(lt_requests) = VALUE trwbo_request_headers( ( CORRESPONDING #( gs_request-h ) ) ).
  APPEND LINES OF gt_sub_requests TO lt_requests.

  SORT lt_requests BY strkorr DESCENDING.

  LOOP AT lt_requests ASSIGNING FIELD-SYMBOL(<ls_request>).

    CHECK <ls_request>-trstatus NE sctsc_state_released.

    TRY.
        CALL FUNCTION 'TR_RELEASE_REQUEST'
          EXPORTING
            iv_trkorr                  = <ls_request>-trkorr
            iv_dialog                  = abap_false
            iv_success_message         = abap_false
            iv_without_locking         = abap_true " wasn't available in earlier releases!
          EXCEPTIONS
            cts_initialization_failure = 1
            enqueue_failed             = 2
            no_authorization           = 3
            invalid_request            = 4
            request_already_released   = 5
            repeat_too_early           = 6
            error_in_export_methods    = 7
            object_check_error         = 8
            docu_missing               = 9
            db_access_error            = 10
            action_aborted_by_user     = 11
            export_failed              = 12
            OTHERS                     = 13.

      CATCH cx_root.
        CALL FUNCTION 'TR_RELEASE_REQUEST'
          EXPORTING
            iv_trkorr                  = <ls_request>-trkorr
            iv_dialog                  = abap_false
            iv_success_message         = abap_false
          EXCEPTIONS
            cts_initialization_failure = 1
            enqueue_failed             = 2
            no_authorization           = 3
            invalid_request            = 4
            request_already_released   = 5
            repeat_too_early           = 6
            error_in_export_methods    = 7
            object_check_error         = 8
            docu_missing               = 9
            db_access_error            = 10
            action_aborted_by_user     = 11
            export_failed              = 12
            OTHERS                     = 13.

    ENDTRY.

    IF sy-subrc <> 0.
      error = abap_true.
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE sy-msgty.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDFORM.                    "release_ta_request
*&---------------------------------------------------------------------*
*&      Form  REMOVE_TA_FROM_QUEUE
*&---------------------------------------------------------------------*
FORM remove_tr_from_queue.

  DATA: lv_command LIKE stpa-command.

  DATA: lv_counter       TYPE i VALUE 0,
        lv_current_retry TYPE i VALUE 0,
        lv_max_retry     TYPE i VALUE 60,
        lv_interval      TYPE i VALUE 5.

  CHECK p_chk_del_tr EQ abap_true.

  WHILE lv_counter = 0
    AND lv_current_retry <= lv_max_retry.

    ADD 1 TO lv_current_retry.

    IF lv_current_retry > 1.
      WAIT UP TO lv_interval SECONDS.
    ENDIF.

    CALL FUNCTION 'TMS_MGR_GREP_TRANSPORT_QUEUE'
      EXPORTING
        iv_system                = gs_request-h-tarsystem
        iv_request               = gs_request-h-trkorr
        iv_refresh_queue         = abap_true
        iv_without_cache         = abap_true
        iv_completed_requests    = abap_true
        iv_pending_requests      = abap_true
        iv_refused_requests      = abap_true
      IMPORTING
        ev_counter               = lv_counter
      EXCEPTIONS
        read_config_failed       = 1
        read_import_queue_failed = 2
        OTHERS                   = 3.

    " Transport has been released already, thus we
    " don't need to delete it from the import queue
    IF gs_request-h-trstatus EQ sctsc_state_released.
      EXIT.
    ENDIF.

  ENDWHILE.

  IF    lv_counter = 0
    AND gs_request-h-trstatus NE sctsc_state_released.
    error = abap_true.
    MESSAGE |Fehler beim Auslesen des TAs { gs_request-h-trkorr } aus der Import-Queue: | &&
            |Bitte in der STMS -> { gs_request-h-tarsystem } den TA manuell löschen!| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CHECK lv_counter > 0.

  lv_command = 'DELFROMBUFFER'.

  " Die Hinweismeldung am Ende dieses FuBas ist
  " irreführend. Eigentlich wurde der TA gelöscht.
  CALL FUNCTION 'TMS_MGR_MAINTAIN_TR_QUEUE'
    EXPORTING
      iv_command                 = lv_command
      iv_system                  = gs_request-h-tarsystem
      iv_request                 = gs_request-h-trkorr
      iv_monitor                 = abap_true
    EXCEPTIONS
      read_config_failed         = 1
      table_of_requests_is_empty = 2
      OTHERS                     = 3.

  IF sy-subrc <> 0.
    error = abap_true.
    MESSAGE |Fehler beim Löschen des TAs { gs_request-h-trkorr } aus der Import-Queue: | &&
            |Bitte in der STMS -> { gs_request-h-tarsystem } den TA manuell löschen!| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

ENDFORM.                    "remove_ta_from_queue
*&---------------------------------------------------------------------*
*&      Form  APPEND_TA_TO_QUEUE
*&---------------------------------------------------------------------*
FORM append_ta_to_queue USING lv_trkorr TYPE trkorr.

  DATA: lv_system TYPE tmssysnam,
        lv_domain TYPE tmsdomnam.

  lv_system = sy-sysid.
*  CONCATENATE 'DOMAIN_' sy-sysid INTO lv_domain. " Wurde im ID3 nicht benötigt; hat dort sogar zu einem
*                                                 " Fehler geführt, da die Domain nicht gefunden wurde.

  CALL FUNCTION 'TMS_MGR_FORWARD_TR_REQUEST'
    EXPORTING
      iv_request      = lv_trkorr
      iv_target       = lv_system
      iv_tardom       = lv_domain
      iv_source       = lv_system
      iv_srcdom       = lv_domain
      iv_monitor      = abap_true
      iv_import_again = abap_true
    EXCEPTIONS
      OTHERS          = 99.

  IF sy-subrc <> 0.

    error = abap_true.
    MESSAGE |Der TA { lv_trkorr } konnte nicht zu der Import-Queue hinzugefügt werden: | &&
            |Bitte in der SE01 manuell löschen!| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.

  ENDIF.

ENDFORM.                    "append_ta_to_queue
*&---------------------------------------------------------------------*
*&      Form  IMPORT_TA_REQUEST
*&---------------------------------------------------------------------*
FORM import_ta_request USING lv_trkorr TYPE trkorr.

  DATA: lv_system    TYPE tmssysnam,
        ls_exception TYPE stmscalert.

  CHECK p_only_append EQ abap_false.

  lv_system = sy-sysid.

  CALL FUNCTION 'TMS_MGR_IMPORT_TR_REQUEST'
    EXPORTING
      iv_system                  = lv_system
      iv_request                 = lv_trkorr
      iv_client                  = sy-mandt
      iv_import_again            = abap_true        " Nochmals importieren, falls bereits versucht
      iv_ignore_cvers            = abap_true        " Nicht passende Komponentenversionen ignorieren
      iv_ignore_originality      = p_overwrite_orig " Originale werden überschrieben
    IMPORTING
      es_exception               = ls_exception
    EXCEPTIONS
      read_config_failed         = 1
      table_of_requests_is_empty = 2
      OTHERS                     = 3.

  IF   sy-subrc <> 0
    OR ls_exception-severity CA 'EA'.

    error = abap_true.
    MESSAGE |Der TA { lv_trkorr } konnte nicht importiert werden: | &&
            |Bitte in der STMS -> { lv_system } manuell importieren oder löschen!| TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.

  ELSEIF ls_exception-msgty CA 'EA'.

    error = abap_true.
    MESSAGE |Der TA { lv_trkorr } konnte erfolgreich importiert werden, jedoch sind bei der | &&
            |Aktivierung/Generierung der Entwicklungsobjekte Fehler aufgetreten, die manuell| &&
            |behoben werden müssen - siehe Details in der STMS -> { lv_system }.| TYPE 'I' DISPLAY LIKE 'W'.
    RETURN.

  ENDIF.

ENDFORM.                    "import_ta_request

"$. Endregion General Functions

*--------------------------------------------------------------------*
