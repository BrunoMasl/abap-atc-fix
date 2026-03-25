*&---------------------------------------------------------------------*
*& Report ZFID_075
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZFID_075.

TABLES: SSCRFIELDS.
TYPE-POOLS: SLIS,ICON.

TYPES:BEGIN OF TY_DATA,
        ZNUMBER(5) TYPE C,
        BLDAT      TYPE MKPF-BLDAT,
        BUDAT      TYPE MKPF-BUDAT,
        XBLNR      TYPE MKPF-XBLNR,
        EBELN      TYPE EKPO-EBELN,
        MATNR      TYPE EKPO-MATNR,
        EBELP      TYPE EKPO-EBELP,
        MENGE      TYPE EKPO-MENGE,
        WRBTR      TYPE BSEG-WRBTR,
      END OF TY_DATA.

TYPES:BEGIN OF TY_ALV,
        ZNUMBER(5) TYPE C,
        BUKRS      TYPE EKKO-BUKRS,
        BLDAT      TYPE MKPF-BLDAT,
        BUDAT      TYPE MKPF-BUDAT,
        ZFBDT      TYPE MKPF-BLDAT,
        ZTERM      TYPE LFM1-ZTERM,
        WRBTR1     TYPE BSEG-WRBTR,
        WMWST      TYPE BSEG-WMWST,
        WAERS      TYPE EKKO-WAERS,
        MWSKZ      TYPE BSEG-MWSKZ,
        XBLNR      TYPE MKPF-XBLNR,
        BKTXT      TYPE MKPF-BKTXT,
        EBELN      TYPE BSEG-EBELN,
        MATNR      TYPE BSEG-MATNR,
        EBELP      TYPE BSEG-EBELP,
        MENGE      TYPE BSEG-MENGE,
        WRBTR      TYPE BSEG-WRBTR,
        WRBTR2     TYPE BSEG-WRBTR,
        BOX        TYPE C,
        ICON(4)    TYPE C,
        ZMSG(255)  TYPE C,
      END OF TY_ALV.

TYPES:BEGIN OF TY_HEAD,
        ZNUMBER(5) TYPE C,
        BKTXT      TYPE MKPF-BKTXT,
        WRBTR1     TYPE BSEG-WRBTR,
      END OF TY_HEAD.

FIELD-SYMBOLS: <GS_DATA> TYPE TY_DATA,
               <GS_CELL> TYPE ALSMEX_TABLINE,
               <FS>      TYPE ANY.

DATA: GV_ERROR TYPE C.
DATA: GT_DATA TYPE STANDARD TABLE OF TY_DATA,
      GT_ALV  TYPE STANDARD TABLE OF TY_ALV,
      GS_DATA TYPE TY_DATA,
      GS_ALV  TYPE TY_ALV,
      GT_CELL LIKE TABLE OF ALSMEX_TABLINE.
DATA: GT_FIELDCAT TYPE LVC_T_FCAT,
      GS_FIELDCAT TYPE LVC_S_FCAT,
      GS_LAYOUT   TYPE LVC_S_LAYO,
      G_REPID     LIKE SY-REPID VALUE SY-REPID.

CONSTANTS : C_FILE TYPE STRING VALUE 'C:\',
            C_TAB  TYPE ABAP_CHAR1 VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB.

SELECTION-SCREEN BEGIN OF BLOCK FRAM01 WITH FRAME TITLE TEXT-S01.
PARAMETERS : P_FILE LIKE RLGRAP-FILENAME. " OBLIGATORY .
SELECTION-SCREEN END OF BLOCK FRAM01.
SELECTION-SCREEN FUNCTION KEY 1.

INITIALIZATION.
  SSCRFIELDS-FUNCTXT_01 = TEXT-F01.    "定义按钮
*&---------------------------------------------------------------------*
*&    选择屏幕搜索帮助屏幕                                                   *
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_FILE. "fn+f4
  PERFORM FRM_FILE_F4.

AT SELECTION-SCREEN ON BLOCK FRAM01.
  IF SY-UCOMM = 'FC01'.   "下载模板
    PERFORM FRM_DOWNLOAD_TMP.
  ENDIF.
*&---------------------------------------------------------------------*
*&    开始选择屏幕                                                     *
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  "上载EXCEL数据
  IF P_FILE IS INITIAL.
    "请输入导入文件路径&EXCEL文件名
    MESSAGE '请输入导入文件路径&EXCEL文件名' TYPE 'E'.
  ELSE.
    PERFORM FRM_READ_EXCEL.
    IF GT_ALV IS NOT INITIAL.
      PERFORM FRM_DISPLAY.
    ELSE.
      MESSAGE '模板中无数据！' TYPE 'E'.
    ENDIF.

  ENDIF.

FORM FRM_DOWNLOAD_TMP .

  DATA: LV_OBJID TYPE W3OBJID,
        LT_MESS  TYPE TABLE OF BAPIRET2.
  "SMW0上传的模板名
  LV_OBJID = 'ZFID075'.

  "调用EXCEL下载函数
  CALL FUNCTION 'ZFM_DOWNLOAD_EXCEL'
    EXPORTING
      IV_OBJID  = LV_OBJID
    TABLES
      ET_RETURN = LT_MESS[].

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FRM_FILE_F4
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FRM_FILE_F4 .
  DATA:
    LV_RC        TYPE I,
    LT_FILETABLE TYPE FILETABLE.
  FIELD-SYMBOLS:
  <L_FILETABLE> LIKE LINE OF LT_FILETABLE.

  "选择文件路径
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
    EXPORTING
*     WINDOW_TITLE            =
*     DEFAULT_EXTENSION       =
*     DEFAULT_FILENAME        =
      FILE_FILTER             = CL_GUI_FRONTEND_SERVICES=>FILETYPE_EXCEL
*     WITH_ENCODING           =
      INITIAL_DIRECTORY       = C_FILE
*     MULTISELECTION          =
    CHANGING
      FILE_TABLE              = LT_FILETABLE
      RC                      = LV_RC
*     USER_ACTION             =
*     FILE_ENCODING           =
    EXCEPTIONS
      FILE_OPEN_DIALOG_FAILED = 1
      CNTL_ERROR              = 2
      ERROR_NO_GUI            = 3
      NOT_SUPPORTED_BY_GUI    = 4
      OTHERS                  = 5.
  IF SY-SUBRC = 0 AND LV_RC = 1.
    READ TABLE LT_FILETABLE ASSIGNING <L_FILETABLE> INDEX LV_RC.
    CHECK SY-SUBRC = 0.
    P_FILE = <L_FILETABLE>-FILENAME.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FRM_READ_EXCEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FRM_READ_EXCEL.
  DATA:LT_HEAD_BKTXT  TYPE TABLE OF TY_HEAD,
       LT_HEAD        TYPE TABLE OF TY_HEAD,
       LT_CHECK_MATNR TYPE TABLE OF TY_HEAD,
       LS_HEAD_BKTXT  TYPE TY_HEAD,
       LS_HEAD        TYPE TY_HEAD,
       LS_CHECK_MATNR TYPE TY_HEAD,
       LV_BKTXT       TYPE BSEG-SGTXT,
       LV_WMWST       TYPE BSEG-WMWST VALUE '0.06',
       LV_ZNUMBER(5)  TYPE C.
*根据位置获取字段信息
  DATA:LD_DESCR_REF TYPE REF TO CL_ABAP_STRUCTDESCR.
  FIELD-SYMBOLS:<FS_DESCRIB> TYPE ABAP_COMPDESCR.

  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      FILENAME                = P_FILE
      I_BEGIN_COL             = 1
      I_BEGIN_ROW             = 3
      I_END_COL               = 9     "暂时固定写死，后续有调整在改 列col  行row
      I_END_ROW               = 9999
    TABLES
      INTERN                  = GT_CELL
    EXCEPTIONS
      INCONSISTENT_PARAMETERS = 1
      UPLOAD_OLE              = 2
      OTHERS                  = 3.
  IF SY-SUBRC <> 0.
    "EXCEL导入错误或文件路径错误
    MESSAGE 'EXCEL导入错误或文件路径错误' TYPE 'E'.
  ENDIF.

  CLEAR: GS_DATA,GT_DATA.
  LOOP AT GT_CELL ASSIGNING <GS_CELL>.

*    TRANSLATE <GS_CELL>-VALUE TO UPPER CASE.
*    CONDENSE  <GS_CELL>-VALUE NO-GAPS.

    ASSIGN COMPONENT <GS_CELL>-COL OF STRUCTURE GS_DATA TO <FS>.         "动态方法将值传到相应的内表
    IF <FS> IS ASSIGNED.
      <FS> = <GS_CELL>-VALUE.
    ENDIF.

    LD_DESCR_REF ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( GS_DATA ).
    READ TABLE LD_DESCR_REF->COMPONENTS ASSIGNING <FS_DESCRIB> INDEX <GS_CELL>-COL.
    AT END OF ROW.
      CONDENSE  GS_DATA-ZNUMBER NO-GAPS.
      APPEND GS_DATA TO GT_DATA.
      CLEAR GS_DATA.
    ENDAT.
  ENDLOOP.

  SORT GT_DATA BY ZNUMBER.
  IF GT_DATA IS NOT INITIAL.
    SELECT
      C~EBELN,
      B~KNUMV,
      B~LIFNR,
      A~ZTERM,
      A~WAERS
      FROM LFM1 AS A
      INNER JOIN KONV AS B ON B~LIFNR = A~LIFNR
      INNER JOIN EKKO AS C ON C~KNUMV = B~KNUMV
      FOR ALL ENTRIES IN @GT_DATA
      WHERE C~EBELN = @GT_DATA-EBELN
        AND B~KSCHL = 'ZFRB'
        AND A~EKORG = '5100'
      INTO TABLE @DATA(LT_LFM1).
    SORT LT_LFM1 BY EBELN.

    IF LT_LFM1 IS NOT INITIAL.
      SELECT
        ZTERM,
        ZDART
        FROM T052
        FOR ALL ENTRIES IN @LT_LFM1
        WHERE ZTERM = @LT_LFM1-ZTERM
        INTO TABLE @DATA(LT_T052).
    ENDIF.

    SELECT EBELN,EBELP,MATNR
      FROM EKPO
      FOR ALL ENTRIES IN @GT_DATA
      WHERE EBELN = @GT_DATA-EBELN
        AND EBELP = @GT_DATA-EBELP
      INTO TABLE @DATA(LT_EKPO).
    SORT LT_EKPO BY EBELN EBELP.

    DATA(LT_DATA_BKTXT)  = GT_DATA.
    SORT LT_DATA_BKTXT BY ZNUMBER EBELN.
    DELETE ADJACENT DUPLICATES FROM LT_DATA_BKTXT COMPARING ZNUMBER EBELN.

    LOOP AT LT_DATA_BKTXT INTO DATA(LS_DATA_BKTXT).
      CLEAR:LS_HEAD_BKTXT,LV_ZNUMBER.

      LV_BKTXT = LV_BKTXT && ',' && LS_DATA_BKTXT-EBELN  .
      LV_ZNUMBER = LS_DATA_BKTXT-ZNUMBER.

      AT END OF ZNUMBER.
        SHIFT LV_BKTXT BY 1 PLACES LEFT.
        LS_HEAD_BKTXT-ZNUMBER = LV_ZNUMBER.
        LS_HEAD_BKTXT-BKTXT = LV_BKTXT.
        APPEND LS_HEAD_BKTXT TO LT_HEAD_BKTXT.
        CLEAR:LV_ZNUMBER,LV_BKTXT,LS_HEAD_BKTXT.
      ENDAT.
    ENDLOOP.

    SORT LT_HEAD_BKTXT BY ZNUMBER.
    CLEAR GS_DATA.
    LOOP AT GT_DATA INTO GS_DATA.
      CLEAR:LS_HEAD,LS_HEAD_BKTXT,LS_CHECK_MATNR.

      READ TABLE LT_HEAD_BKTXT INTO LS_HEAD_BKTXT WITH KEY ZNUMBER = GS_DATA-ZNUMBER BINARY SEARCH.
      IF SY-SUBRC = 0.
        LS_HEAD-BKTXT = LS_HEAD_BKTXT-BKTXT.
      ENDIF.

      LS_HEAD-ZNUMBER = GS_DATA-ZNUMBER.
      LS_HEAD-WRBTR1 = GS_DATA-WRBTR.
      COLLECT LS_HEAD INTO LT_HEAD.

      READ TABLE LT_EKPO INTO DATA(LS_EKPO) WITH KEY EBELN = GS_DATA-EBELN EBELP = GS_DATA-EBELP BINARY SEARCH.
      IF SY-SUBRC = 0.
        GS_DATA-MATNR = |{ GS_DATA-MATNR ALPHA = OUT }|.
        LS_EKPO-MATNR = |{ LS_EKPO-MATNR ALPHA = OUT }|.
        IF GS_DATA-MATNR <> LS_EKPO-MATNR.
          LS_CHECK_MATNR-ZNUMBER = GS_DATA-ZNUMBER.
          APPEND LS_CHECK_MATNR TO LT_CHECK_MATNR.
        ENDIF.
      ENDIF.

      CLEAR:GS_DATA,LS_HEAD,LS_CHECK_MATNR.
    ENDLOOP.

    SORT LT_CHECK_MATNR BY ZNUMBER.
    DELETE ADJACENT DUPLICATES FROM LT_CHECK_MATNR COMPARING ZNUMBER.

    SORT LT_HEAD BY ZNUMBER.
    CLEAR:GS_DATA.
    LOOP AT GT_DATA INTO GS_DATA .
      CLEAR:GS_ALV,LS_CHECK_MATNR.
      GS_ALV-ZNUMBER  = GS_DATA-ZNUMBER.
      GS_ALV-BUKRS    = '5193'  .
      GS_ALV-BLDAT    = GS_DATA-BLDAT  .
      GS_ALV-BUDAT    = GS_DATA-BUDAT  .
      GS_ALV-XBLNR    = GS_DATA-XBLNR  .
      GS_ALV-EBELN    = GS_DATA-EBELN  .
*      GS_ALV-MATNR    = GS_DATA-MATNR  .
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING
          INPUT  = GS_DATA-MATNR
        IMPORTING
          OUTPUT = GS_ALV-MATNR.

      GS_ALV-EBELP    = GS_DATA-EBELP  .
      GS_ALV-MENGE    = GS_DATA-MENGE  .
      GS_ALV-WRBTR    = GS_DATA-WRBTR  .
      GS_ALV-MWSKZ    = 'J4'  .

      READ TABLE LT_LFM1 INTO DATA(LS_LFM1) WITH KEY EBELN = GS_DATA-EBELN BINARY SEARCH.
      IF SY-SUBRC = 0.
        GS_ALV-ZTERM = LS_LFM1-ZTERM.
        GS_ALV-WAERS = LS_LFM1-WAERS.
        READ TABLE LT_T052 INTO DATA(LS_T052) WITH KEY ZTERM = LS_LFM1-ZTERM BINARY SEARCH.
        IF SY-SUBRC = 0.
          IF LS_T052-ZDART = 'D'.
            GS_ALV-ZFBDT = GS_DATA-BUDAT  .
          ELSEIF LS_T052-ZDART = 'B'.
            GS_ALV-ZFBDT = GS_DATA-BLDAT  .
          ELSE.
            GS_ALV-ZFBDT = SY-DATUM  .
          ENDIF.
        ENDIF.
      ENDIF.

      READ TABLE LT_HEAD INTO LS_HEAD WITH KEY ZNUMBER = GS_DATA-ZNUMBER BINARY SEARCH.
      IF SY-SUBRC = 0.
        GS_ALV-WMWST = LS_HEAD-WRBTR1 * LV_WMWST.
        GS_ALV-WRBTR1 = LS_HEAD-WRBTR1 + GS_ALV-WMWST.
        GS_ALV-WRBTR2 = LS_HEAD-WRBTR1 + GS_ALV-WMWST.
        GS_ALV-BKTXT = LS_HEAD-BKTXT.
      ENDIF.

      READ TABLE LT_CHECK_MATNR INTO LS_CHECK_MATNR WITH KEY ZNUMBER = GS_DATA-ZNUMBER BINARY SEARCH.
      IF SY-SUBRC = 0.
        GS_ALV-ICON = ICON_RED_LIGHT.
        GS_ALV-ZMSG = '物料号错误，烦请检查上传数据'.
      ENDIF.

      APPEND GS_ALV TO GT_ALV.
      CLEAR: GS_ALV,LS_CHECK_MATNR.
    ENDLOOP.

  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FRM_DISPLAY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FRM_DISPLAY .
  PERFORM FRM_LAYOUT.
  PERFORM FRM_FIELDCAT.
  PERFORM FRM_DISPLAY_ALV.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_LAYOUT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_LAYOUT .
  GS_LAYOUT-ZEBRA = 'X'.   "斑马线
  GS_LAYOUT-CWIDTH_OPT = 'X' .    " 自动调整ALVL列宽 = 'X'.
  GS_LAYOUT-BOX_FNAME = 'BOX'.    " 选择框.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_FIELDCAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_FIELDCAT .
  CLEAR:GS_FIELDCAT.
  DEFINE L_FIELDCAT.
    gs_fieldcat-fieldname = &1.
    gs_fieldcat-coltext   = &2.
    gs_fieldcat-key       = &3.
    gs_fieldcat-ref_table = &4.
    gs_fieldcat-ref_field = &5.
    APPEND gs_fieldcat TO gt_fieldcat.
  END-OF-DEFINITION.
  L_FIELDCAT 'ICON   ' TEXT-018 'X'   '    '  '       ' .
  L_FIELDCAT 'ZMSG   ' TEXT-019 'X'   '    '  '       ' .
  L_FIELDCAT 'ZNUMBER' TEXT-001 'X'   '    '  '       ' .
  L_FIELDCAT 'BUKRS  ' TEXT-002 'X'   'EKKO'  'BUKRS  ' .
  L_FIELDCAT 'BLDAT  ' TEXT-003 'X'   'MKPF'  'BLDAT  ' .
  L_FIELDCAT 'BUDAT  ' TEXT-004 'X'   'MKPF'  'BUDAT  ' .
  L_FIELDCAT 'ZFBDT  ' TEXT-005 'X'   'MKPF'  'BLDAT  ' .
  L_FIELDCAT 'ZTERM  ' TEXT-006 'X'   'LFM1'  'ZTERM  ' .
  L_FIELDCAT 'WRBTR1 ' TEXT-007 'X'   'BSEG'  'WRBTR  ' .
  L_FIELDCAT 'WMWST  ' TEXT-008 'X'   'BSEG'  'WMWST  ' .
  L_FIELDCAT 'WAERS  ' TEXT-009 'X'   'EKKO'  'WAERS  ' .
  L_FIELDCAT 'MWSKZ  ' TEXT-010 'X'   'BSEG'  'MWSKZ  ' .
  L_FIELDCAT 'XBLNR  ' TEXT-011 'X'   'MKPF'  'XBLNR  ' .
  L_FIELDCAT 'BKTXT  ' TEXT-012 'X'   'MKPF'  'BKTXT  ' .
  L_FIELDCAT 'EBELN  ' TEXT-013 'X'   'BSEG'  'EBELN  ' .
  L_FIELDCAT 'MATNR  ' TEXT-014 'X'   'BSEG'  'MATNR  ' .
  L_FIELDCAT 'EBELP  ' TEXT-015 'X'   'BSEG'  'EBELP  ' .
  L_FIELDCAT 'MENGE  ' TEXT-016 'X'   'BSEG'  'MENGE  ' .
  L_FIELDCAT 'WRBTR  ' TEXT-017 'X'   'BSEG'  'WRBTR  ' .


ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_DISPLAY_ALV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FRM_DISPLAY_ALV .
  G_REPID = SY-REPID.
*&---ALV 显示函数
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      I_CALLBACK_PROGRAM       = G_REPID
      I_CALLBACK_PF_STATUS_SET = 'FRM_PF_STATUS'
      I_CALLBACK_USER_COMMAND  = 'FRM_USER_COMMAND'
      IS_LAYOUT_LVC            = GS_LAYOUT
      IT_FIELDCAT_LVC          = GT_FIELDCAT
      I_DEFAULT                = 'X'
      I_SAVE                   = 'A'
    TABLES
      T_OUTTAB                 = GT_ALV
    EXCEPTIONS
      PROGRAM_ERROR            = 1
      OTHERS                   = 2.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SET_PF_STATUS
*&---------------------------------------------------------------------*
*       设置ALV状态栏
*----------------------------------------------------------------------*
*      -->RT_EXTAB   text
*----------------------------------------------------------------------*
FORM FRM_PF_STATUS USING RT_EXTAB TYPE SLIS_T_EXTAB.
  SET PF-STATUS 'ZSTAND_1000'.
ENDFORM. "F_SET_STATUS

*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND
*&---------------------------------------------------------------------*
*       自定义按钮响应事件
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM FRM_USER_COMMAND USING R_UCOMM LIKE SY-UCOMM
      RS_SELFIELD TYPE SLIS_SELFIELD.
  DATA: GV_GRID TYPE REF TO CL_GUI_ALV_GRID.

  CASE R_UCOMM.                                       "  ALV界面按钮功能
    WHEN 'POST'.
      PERFORM FRM_CALL_BAPI.
  ENDCASE.
  "刷新
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      E_GRID = GV_GRID.
  CALL METHOD GV_GRID->CHECK_CHANGED_DATA.
  RS_SELFIELD-REFRESH = 'X'.    " 实时刷新ALV界面
ENDFORM. "USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  FRM_CALL_BAPI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM FRM_CALL_BAPI .
  DATA: LS_HEADERDATA       LIKE BAPI_INCINV_CREATE_HEADER,
        LT_ITEMDATA         LIKE TABLE OF BAPI_INCINV_CREATE_ITEM,
        LS_ITEMDATA         LIKE BAPI_INCINV_CREATE_ITEM,
        LT_ITEMTAXDATA      LIKE TABLE OF BAPI_INCINV_CREATE_TAX,
        LS_ITEMTAXDATA      LIKE BAPI_INCINV_CREATE_TAX,
        LT_RETURN           LIKE TABLE OF BAPIRET2,
        LS_RETURN           LIKE BAPIRET2,
        LV_INVOICEDOCNUMBER LIKE BAPI_INCINV_FLD-INV_DOC_NO,
        LV_FISCALYEAR       LIKE BAPI_INCINV_FLD-FISC_YEAR.

  DATA: LV_AMOUNT TYPE BAPI_RMWWR,
        LV_TAX    TYPE BAPI_RMWWR,
        LV_ITEM   TYPE N LENGTH 6,
        LV_POSNR  TYPE POSNR_VA,
        LV_TYPE   TYPE C,
        LV_MSG    TYPE BAPIRET2-MESSAGE.
  DATA: GR_ZFIR076_LIFNR TYPE LFB1-LIFNR.

  DATA(LT_ALV)     = GT_ALV.
  DELETE LT_ALV WHERE BOX IS INITIAL .
  DELETE LT_ALV WHERE ICON IS NOT INITIAL .
  SORT LT_ALV BY ZNUMBER.

  IF LT_ALV IS NOT INITIAL.
    SELECT
      C~EBELN,
      B~KNUMV,
      A~LIFNR,
      A~BUKRS,
      A~AKONT
      FROM LFB1 AS A
      INNER JOIN KONV AS B ON B~LIFNR = A~LIFNR
      INNER JOIN EKKO AS C ON C~KNUMV = B~KNUMV
      FOR ALL ENTRIES IN @LT_ALV
      WHERE C~EBELN = @LT_ALV-EBELN
        AND B~KSCHL = 'ZFRB'
        AND A~BUKRS = @LT_ALV-BUKRS
      INTO TABLE @DATA(LT_LFB1).
    SORT LT_LFB1 BY EBELN BUKRS.

    SELECT MATNR,MEINS
      FROM MARA
      FOR ALL ENTRIES IN @LT_ALV
          WHERE MATNR = @LT_ALV-MATNR
      INTO TABLE @DATA(LT_MEINS).
    SORT LT_MEINS BY MATNR.

    LOOP AT LT_ALV INTO DATA(LS_ALV) GROUP BY ( KEY1 = LS_ALV-ZNUMBER ) .
      CLEAR:LV_ITEM,LV_TYPE,LV_MSG,LT_ITEMDATA.

      LOOP AT GROUP LS_ALV INTO DATA(LS_ITEM).
        CLEAR: LS_ITEMDATA.
        LV_ITEM = LV_ITEM + 1.
        LS_ITEMDATA-INVOICE_DOC_ITEM = LV_ITEM.
*        LS_ITEMDATA-ITEM_TEXT        = LS_ITEM-BKTXT.
        LS_ITEMDATA-PO_NUMBER        = LS_ITEM-EBELN.
        LS_ITEMDATA-PO_ITEM          = LS_ITEM-EBELP.
        LS_ITEMDATA-ITEM_AMOUNT      = LS_ITEM-WRBTR.
        LS_ITEMDATA-QUANTITY         = LS_ITEM-MENGE.
        READ TABLE LT_MEINS INTO DATA(LS_MEINS) WITH KEY MATNR = LS_ITEM-MATNR BINARY SEARCH.
        IF SY-SUBRC = 0.
          LS_ITEMDATA-PO_UNIT          = LS_MEINS-MEINS.
        ENDIF.
        LS_ITEMDATA-TAX_CODE         = LS_ITEM-MWSKZ.
        LS_ITEMDATA-COND_TYPE        = 'ZFRB'.
        LS_ITEMDATA-COND_ST_NO       = ' '.
        LS_ITEMDATA-COND_COUNT       = ' '.

*        LS_ITEMDATA-PO_PR_UOM         = LS_ALV-MWSKZ.
        APPEND LS_ITEMDATA TO LT_ITEMDATA.
      ENDLOOP.

      CLEAR: LS_HEADERDATA.
      LS_HEADERDATA-INVOICE_IND        = 'X'.
      LS_HEADERDATA-CALC_TAX_IND       = 'X'.
      LS_HEADERDATA-DOC_TYPE           = 'RE'.
      LS_HEADERDATA-REF_DOC_NO         = LS_ALV-XBLNR.
      LS_HEADERDATA-GROSS_AMOUNT       = LS_ALV-WRBTR1.
      LS_HEADERDATA-DOC_DATE           = LS_ALV-BLDAT.
      LS_HEADERDATA-PSTNG_DATE         = LS_ALV-BUDAT.
      LS_HEADERDATA-BLINE_DATE         = LS_ALV-ZFBDT.
      LS_HEADERDATA-HEADER_TXT         = LS_ALV-BKTXT.
      LS_HEADERDATA-COMP_CODE          = LS_ALV-BUKRS.
      LS_HEADERDATA-CURRENCY           = LS_ALV-WAERS.
      LS_HEADERDATA-PMNTTRMS           = LS_ALV-ZTERM.

      READ TABLE LT_LFB1 INTO DATA(LS_LFB1) WITH KEY EBELN = LS_ALV-EBELN BUKRS = LS_ALV-BUKRS BINARY SEARCH.
      IF SY-SUBRC = 0.
        LS_HEADERDATA-DIFF_INV           = LS_LFB1-LIFNR.
*      LS_HEADERDATA-PYMT_METH           = LS_ALV-ZTERM.
        CLEAR: GR_ZFIR076_LIFNR.
        GR_ZFIR076_LIFNR = LS_LFB1-LIFNR.
        EXPORT GR_ZFIR076_LIFNR TO MEMORY ID 'ZFIR076_LIFNR'.
      ENDIF.

      REFRESH:LT_RETURN.
      CLEAR:LS_RETURN,LV_INVOICEDOCNUMBER.
      CALL FUNCTION 'BAPI_INCOMINGINVOICE_CREATE'
        EXPORTING
          HEADERDATA       = LS_HEADERDATA
        IMPORTING
          INVOICEDOCNUMBER = LV_INVOICEDOCNUMBER
        TABLES
          ITEMDATA         = LT_ITEMDATA
          TAXDATA          = LT_ITEMTAXDATA
          RETURN           = LT_RETURN.

      IF LV_INVOICEDOCNUMBER IS NOT INITIAL.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            WAIT = 'X'.
        LV_TYPE = 'S'.
        LV_MSG  = '创建成功:' && LV_INVOICEDOCNUMBER.

      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        LV_TYPE = 'E'.
        LOOP AT LT_RETURN INTO LS_RETURN WHERE TYPE = 'E' OR TYPE = 'A'.
          LV_MSG  = LS_RETURN-MESSAGE && LV_MSG.
        ENDLOOP.
      ENDIF.
      FREE MEMORY ID 'ZFIR076_LIFNR'.

      LOOP AT GT_ALV INTO GS_ALV WHERE ZNUMBER = LS_ALV-ZNUMBER.
        IF LV_TYPE = 'S'.
          GS_ALV-ICON = ICON_GREEN_LIGHT.
        ELSEIF LV_TYPE = 'E'.
          GS_ALV-ICON = ICON_RED_LIGHT.
        ENDIF.
        GS_ALV-ZMSG = LV_MSG.
        MODIFY GT_ALV FROM GS_ALV.
      ENDLOOP.
    ENDLOOP.

  ENDIF.
ENDFORM.