CREATE OR REPLACE PACKAGE BODY LOG_AUDITORIA.PKG_UTIL IS

   FUNCTION F_SPLIT(P_TEXT IN VARCHAR2) RETURN T_SPLITED_STR
    PIPELINED IS
    LIST R_SPLITED_STR;
  BEGIN

    FOR i in (
       WITH CTE AS (SELECT P_TEXT temp FROM DUAL)
       SELECT ROWNUM AS ID, TRIM(REGEXP_SUBSTR(temp, '[^,^\.]+', 1, level)) AS TEXT
       FROM CTE
       CONNECT BY level <= REGEXP_COUNT(temp, '[^,^\.]+')
      ) loop
        LIST.ID   := i.ID;
        LIST.TEXT := i.TEXT;
        pipe row(LIST);
    end loop;

    return;
  
  exception
    when no_data_needed then
      return;
  END F_SPLIT;
  
  FUNCTION F_SPLIT_DISTINCT(P_TEXT IN VARCHAR2) RETURN T_SPLITED_STR
    PIPELINED IS
    LIST R_SPLITED_STR;
  BEGIN

    FOR i in (
            
      WITH CTE AS(
           SELECT ID,TEXT FROM TABLE(LOG_AUDITORIA.PKG_UTIL.F_SPLIT(P_TEXT))
      )
      SELECT ROWNUM AS ID,TEXT 
      FROM CTE C
      WHERE ID=(SELECT MIN(ID) FROM CTE CT WHERE C.TEXT=CT.TEXT)
      
    ) loop
        LIST.ID   := i.ID;
        LIST.TEXT := i.TEXT;
        pipe row(LIST);
    end loop;
   
    return;
  
  exception
    when no_data_needed then
      return;
  END F_SPLIT_DISTINCT;
  
  FUNCTION F_XML_BEAUTIFY(P_XML IN XMLTYPE) RETURN clob IS
    text clob;
  BEGIN

     SELECT XMLSERIALIZE(DOCUMENT P_XML AS CLOB INDENT SIZE = 2)
     into text
     FROM DUAL;
   
    return text;
  
  exception
    when others then
      return null;
  END;
  
 
        
END PKG_UTIL;
