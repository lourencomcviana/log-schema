CREATE OR REPLACE PACKAGE LOG_AUDITORIA.PKG_UTIL IS
  ------------------------------------DECLARA??ES DE TIPO ------------------------------------------------
  TYPE R_SPLITED_STR IS RECORD(
    ID    NUMBER(10),
    TEXT  VARCHAR2(4000)
  );
  ------------------------------------DECLARA??ES DE TIPO TABELA---------------------------------
  TYPE T_SPLITED_STR IS TABLE OF R_SPLITED_STR;

  ------------------------------------DECLARA??ES DE FUN??ES-------------------------------------
  FUNCTION F_SPLIT(P_TEXT IN VARCHAR2) RETURN T_SPLITED_STR
    PIPELINED;
  FUNCTION F_SPLIT_DISTINCT(P_TEXT IN VARCHAR2) RETURN T_SPLITED_STR
    PIPELINED;
    
    
 FUNCTION F_XML_BEAUTIFY(P_XML IN XMLTYPE) RETURN clob;

END PKG_UTIL;
