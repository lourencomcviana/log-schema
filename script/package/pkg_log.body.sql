create or replace PACKAGE BODY log_audit.PKG_LOG IS
 --FORMAT adotado para o timestamp da pk do log
C_DATA_LOG_FORMAT  VARCHAR2(100) := 'YYYY-MM-DD"T"hh24:mi:ss.ff6';
G_PRIORITY_DB NUMBER;

PROCEDURE P_SET
  AS 
  T_PRIORITY_DB NUMBER; 
BEGIN
  
  select min(PRIORITY_LEVEL)
  INTO G_PRIORITY_DB
  from log_audit.t_PRIORITY
  WHERE UPPER(sys_context('userenv','service_name'))=database
    or UPPER(sys_context('userenv','instance_name'))=database
    or REGEXP_LIKE (UPPER(sys_context('userenv','instance_name')),UPPER('^'||database)||'\d*$','i')
  ;

  --testando prioridade
  --  G_PRIORITY_DB:=1;

  if(G_PRIORITY_DB is null) then
     

      INSERT INTO LOG_AUDIT.t_PRIORITY(PRIORITY_LEVEL,DATABASE,description)
      select nvl(max(PRIORITY_LEVEL),0)+1 ,UPPER(sys_context('userenv','instance_name')),'auto-inserted'
      from  LOG_AUDIT.t_PRIORITY;
    
      select max(PRIORITY_LEVEL)
      into T_PRIORITY_DB
      from  LOG_AUDIT.t_PRIORITY;

      G_PRIORITY_DB:=T_PRIORITY_DB;
      commit;
  end if;
  

   
  
END;

function is_number(p_string in varchar2) return int is
  v_new_num number;
begin
  v_new_num := to_number(p_string, '99999999999999999999990.00');

  return 1;
exception
  when value_error then
    return 0;
end is_number;

function is_number(p_xml in xmltype, p_path in varchar2) return int is
  v_xmltemp xmltype := p_xml.extract(p_path);
begin

  if (v_xmltemp is not null) then
    return is_number(v_xmltemp.getstringval);
  else
    return 0;
  end if;
exception
  when value_error then
    return 0;
end is_number;

FUNCTION fnc_extract_ignore(LOG_REFERENCE xmltype) return NUMBER IS
BEGIN
  IF (LOG_REFERENCE is not null and LOG_REFERENCE.EXTRACT('/log/@ignore') IS NOT NULL) THEN
    RETURN LOG_REFERENCE.EXTRACT('/log/@ignore').getnumberval();
  else
    return 0;
  END IF;
END fnc_extract_ignore;

FUNCTION fnc_extract_seq(LOG_REFERENCE xmltype) return NUMBER IS
BEGIN
  IF (LOG_REFERENCE is not null and LOG_REFERENCE.EXTRACT('/log/@seq') IS NOT NULL) THEN
    RETURN LOG_REFERENCE.EXTRACT('/log/@seq').getnumberval();
  END IF;

  RETURN seq_increment.nextval ;
END fnc_extract_seq;

FUNCTION fnc_extract_update(LOG_REFERENCE xmltype) return NUMBER IS
BEGIN
  IF (LOG_REFERENCE is not null and LOG_REFERENCE.EXTRACT('/log/@update') IS NOT NULL) THEN
    RETURN LOG_REFERENCE.EXTRACT('/log/@update').getnumberval();
  END IF;

  RETURN 0;
END fnc_extract_update;

FUNCTION fnc_extract_data(LOG_REFERENCE xmltype) return timestamp IS
BEGIN
  IF (LOG_REFERENCE is not null and LOG_REFERENCE.EXTRACT('/log/@data') IS NOT NULL) THEN
    RETURN to_timestamp_tz(LOG_REFERENCE.EXTRACT('/log/@data').getstringval(), C_DATA_LOG_FORMAT);
    --com timezone
    --RETURN to_timestamp_tz(LOG_REFERENCE.EXTRACT('/log/@data').getstringval,'YYYY-MM-DD"T"hh24:mi:ss.fftzh:tzm');
  END IF;

  RETURN systimestamp;
END fnc_extract_data;

FUNCTION fnc_generate_time_key(prefix varchar2, precision_size number, maxsize number) return varchar2 IS
  T_key   varchar2(20);
  T_saida varchar2(200);
  t_size  number;
BEGIN

  if (maxsize < 15) then
    t_size := 15;
  else
    t_size := maxsize;
  end if;

  select case precision_size
           when 1 then
            to_char(systimestamp, 'ff')
           when 2 then
            to_char(systimestamp, 'ffss')
           when 3 then
            to_char(systimestamp, 'ffssmi')
           when 4 then
            to_char(systimestamp, 'ffssmihh')
           else
            to_char(systimestamp, 'ffssmihh') || seq_increment.NEXTVAL
         end
    into T_key
    from dual;

  T_saida := substr(prefix, 1, (t_size - length(T_key))) || T_key;

  RETURN T_saida;
END fnc_generate_time_key;


FUNCTION F_TO_LOG_DATA(p_data_str in varchar2) return timestamp is
BEGIN
  return  to_timestamp_tz(p_data_str, C_DATA_LOG_FORMAT);
  exception
    when others then
      dbms_output.put_line('FORMAT: '||C_DATA_LOG_FORMAT);
      return null;
END;

--retorna dados base do log
FUNCTION F_METADATA_EXTRACT(p_xml in XMLTYPE) return t_logkey_recordtype
  pipelined is
  t_logkey r_logkey_recordtype;
BEGIN
  

  if(is_number(p_xml,'/log/@seq')=1) then
      t_logkey.seq      := p_xml.extract('/log/@seq').getnumberval;
  end if;

  if(p_xml.EXTRACT('/log/@data') is not null) then
      t_logkey.data_log := F_TO_LOG_DATA(p_xml.EXTRACT('/log/@data').getstringval());
  end if;

  if(is_number(p_xml,'/log/@ignore')=1) then
     t_logkey.ignore_this  := p_xml.extract('/log/@ignore').getnumberval;
  end if;

  pipe row(t_logkey);
  return;
END;

FUNCTION F_CONTEXT_LEAF(p_ID_CONTEXT NUMBER) return T_CONTEXT_NODEtree_recordtype
  pipelined is
  t_CONTEXTtree r_CONTEXTtree_recordtype;
BEGIN
  
  FOR c_CONTEXTtree IN (
    SELECT cr.ID_CONTEXT,cr.ID_CONTEXT_FATHER,c.CONTEXT,DEFAULT_PRIORITY_LEVEL,
         level as node_level,
         RPAD(' ', (level-1)*2, '  ') || c.CONTEXT AS tree,
         CONNECT_BY_ROOT cr.ID_CONTEXT AS root,
         LTRIM(SYS_CONNECT_BY_PATH(cr.ID_CONTEXT, '-'), '-') AS path,
         LTRIM(SYS_CONNECT_BY_PATH(C.CONTEXT, '.'), '.') AS PATH_CONTEXT,
         CONNECT_BY_ISLEAF AS leaf
    FROM LOG_AUDIT.t_CONTEXT_node c
        join LOG_AUDIT.t_CONTEXT cr on c.CONTEXT=cr.CONTEXT
    START WITH cr.ID_CONTEXT =p_ID_CONTEXT
    CONNECT BY PRIOR cr.ID_CONTEXT_FATHER =  cr.ID_CONTEXT
    ORDER SIBLINGS BY cr.ID_CONTEXT_FATHER  
  ) LOOP
    t_CONTEXTtree.ID_CONTEXT := c_CONTEXTtree.ID_CONTEXT;
    t_CONTEXTtree.ID_CONTEXT_FATHER := c_CONTEXTtree.ID_CONTEXT_FATHER;
    t_CONTEXTtree.CONTEXT := c_CONTEXTtree.CONTEXT;
    t_CONTEXTtree.DEFAULT_PRIORITY_LEVEL := c_CONTEXTtree.DEFAULT_PRIORITY_LEVEL;
    t_CONTEXTtree.node_level := c_CONTEXTtree.node_level;
    t_CONTEXTtree.TREE := c_CONTEXTtree.TREE;
    t_CONTEXTtree.ROOT := c_CONTEXTtree.ROOT;
    t_CONTEXTtree.PATH := c_CONTEXTtree.PATH;
    t_CONTEXTtree.PATH_CONTEXT := c_CONTEXTtree.PATH_CONTEXT;
    t_CONTEXTtree.LEAF := c_CONTEXTtree.LEAF;
    pipe row(t_CONTEXTtree);
  END LOOP;
  return;
END;


FUNCTION F_METADATA_BASIC(p_xml in XMLTYPE) return XMLTYPE is 
  t_saida xmltype;
BEGIN

  select  XMLQuery('
    copy $i := $p1 modify(delete node $i/log/*)
    return $i
    '
  PASSING
    p_xml AS "p1"
  RETURNING CONTENT) INTO t_saida from dual;
  
  return t_saida;
END;

FUNCTION F_XML_LAST_UPDATE(p_xml in XMLTYPE) return XMLTYPE is 
BEGIN
  return F_XML_LAST_UPDATES(0,p_xml);
end;

FUNCTION F_XML_LAST_UPDATES(p_number_updates number,p_xml in XMLTYPE) return XMLTYPE is 
  newXml xmltype;
BEGIN

  newXml:= LOG_AUDIT.pkg_log.F_METADATA_BASIC(p_xml);
  for x in(
  SELECT updates
  FROM 
    XMLTable('for $i in /log/update[position() >= last()-$qtd] return $i'
    PASSING p_xml, 
    p_number_updates as "qtd"
    COLUMNS 
      updates   xmltype  PATH '/update'
  ))
  loop
   
     select  XMLQuery('
        copy $i := $p1 modify(
          (: expressao par ainserir e modificar dados basicos do log e das atualizacoes sobre o mesmo :)
          insert node $p2
                  as last into $i/log
        )
        return $i
        '
        PASSING
           newXml AS "p1",
           x.updates AS "p2"
        RETURNING CONTENT) INTO newXml from dual;

  end loop;
  
  return newXml;
END;

PROCEDURE P_CONTEXT(
  P_TEXT VARCHAR2,
  PO_ID_PRIORITY IN OUT NUMBER,
  O_ID_context OUT NUMBER
  --O_PRIORITY OUT NUMBER
) AS
  T_MAX_LEVEL NUMBER;
  T_ID_CONTEXT NUMBER;
  O_PRIORITY NUMBER;
  TEXT VARCHAR2(130);
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  TEXT :=upper(P_TEXT);

  MERGE INTO LOG_AUDIT.t_CONTEXT_node T
  USING(
    SELECT  C.text AS CONTEXT
    FROM TABLE(LOG_AUDIT.PKG_UTIL.F_SPLIT_DISTINCT(TEXT)) C
    ORDER BY C.ID
  ) S ON (T.CONTEXT = S.CONTEXT)
  --WHEN MATCHED THEN UPDATE SET T.IDFATHER =  S.IDFATHER
  WHEN NOT MATCHED THEN INSERT (T.CONTEXT)
       VALUES (S.CONTEXT )
  ;

  select MAX(ID)
  INTO T_MAX_LEVEL
  from TABLE(LOG_AUDIT.PKG_UTIL.F_SPLIT_DISTINCT(TEXT));
  
 
  DECLARE

      T_ID_CONTEXT NUMBER;
      T_ID_CONTEXT_FATHER NUMBER;
    BEGIN

    FOR NTREE IN (
        SELECT
            NTREE.*,
             CASE WHEN  NTREE.node_level=T_MAX_LEVEL
               THEN PO_ID_PRIORITY
               ELSE NULL
            END DEFAULT_PRIORITY_LEVEL
        FROM (
          with cte as(
             select * from TABLE(LOG_AUDIT.PKG_UTIL.F_SPLIT(TEXT))
          )
          SELECT   C.CONTEXT,
            level as node_level,
            RPAD(' ', (level-1)*2, '  ') || c.CONTEXT AS tree,
            CONNECT_BY_ROOT c.CONTEXT AS root,
            LTRIM(SYS_CONNECT_BY_PATH(c.CONTEXT, '-'), '-') AS path,
            CONNECT_BY_ISLEAF AS leaf       
          from cte  TC
            JOIN LOG_AUDIT.t_CONTEXT_NODE C ON C.CONTEXT=TC.TEXT
            LEFT JOIN cte TCP ON TC.ID-1=TCP.ID
          START WITH TCP.ID IS NULL
          CONNECT BY TCP.ID = PRIOR TC.ID
          ORDER SIBLINGS BY TCP.ID

        ) NTREE
    ) LOOP
          --pega a RELATION anterior
          T_ID_CONTEXT_FATHER:=T_ID_CONTEXT;

          BEGIN

            SELECT ID_CONTEXT,DEFAULT_PRIORITY_LEVEL
            INTO T_ID_CONTEXT,O_PRIORITY
            FROM LOG_AUDIT.V_CONTEXT OTREE
            WHERE NTREE.node_level=OTREE.node_level AND NTREE.cONTEXT=OTREE.CONTEXT AND (T_ID_CONTEXT_FATHER IS NULL OR T_ID_CONTEXT_FATHER=ID_CONTEXT_FATHER)
            ;

            IF(NTREE.DEFAULT_PRIORITY_LEVEL is not null)THEN
                UPDATE LOG_AUDIT.t_CONTEXT
                SET DEFAULT_PRIORITY_LEVEL =  NTREE.DEFAULT_PRIORITY_LEVEL
                WHERE ID_CONTEXT=T_ID_CONTEXT
                ;
            END IF;
          EXCEPTION WHEN OTHERS THEN
            --gera id da nova RELATION
            T_ID_CONTEXT:= LOG_AUDIT.seq_CONTEXT.nextval;
            O_PRIORITY:=NTREE.DEFAULT_PRIORITY_LEVEL;

            INSERT INTO LOG_AUDIT.t_CONTEXT(ID_CONTEXT,ID_CONTEXT_FATHER,context,DEFAULT_PRIORITY_LEVEL)
            values(T_ID_CONTEXT,T_ID_CONTEXT_FATHER,NTREE.context,NTREE.DEFAULT_PRIORITY_LEVEL)
            ;
          END;

      END LOOP;

      O_ID_CONTEXT:=T_ID_CONTEXT;
      PO_ID_PRIORITY:=O_PRIORITY;
    END;
  commit;

EXCEPTION
  WHEN OTHERS THEN
    P_LOG(SQLERRM, 1,'LOG.MAINTAIN.CONTEXT.ERRO');

    rollback;
    RAISE;
END P_CONTEXT;


PROCEDURE P_ADD_PRIVATE(p_name          IN OUT VARCHAR2,
                          p_Value         IN clob,
                          LOG_REFERENCE   in OUT XMLTYPE,
                          dup_error_count in number default 0,
                          o_data          out timestamp,
                          o_seq           out number,
                          o_update        out number
  ) AS

  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  if (length(p_name) > 20) then
    p_name := substr(p_name, 1, 17) || '...';
  end if;

  if(fnc_extract_ignore(LOG_REFERENCE)=0) then
    --P_LOG(P_ID_PRIORITY,LOG_REFERENCE);
    o_data := fnc_extract_data(LOG_REFERENCE);
    o_seq  := fnc_extract_seq(LOG_REFERENCE);
    o_update := fnc_extract_update(LOG_REFERENCE);
    
    insert into LOG_AUDIT.t_Parameter
    values(o_data, o_seq,o_update, p_name);

    commit;
  end if;

  select  XMLQuery('
    copy $i := $p1 modify(
      insert node <parameter name="{$name}">{$Value}</parameter>
              as last into $i/log/update[last()]
    )
    return $i
    '
  PASSING
    LOG_REFERENCE AS "p1",
    p_name AS "name",
    to_char(substr(p_Value,1,4000)) as "Value"
  RETURNING CONTENT) INTO LOG_REFERENCE from dual;



EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    rollback;

    p_name := fnc_generate_time_key(p_name, dup_error_count, 20);
    P_ADD_PRIVATE( P_name, p_Value, LOG_REFERENCE, dup_error_count + 1,o_data,o_seq,o_update);
  WHEN OTHERS THEN
    rollback;

    if(dup_error_count<2) then
      DECLARE
        t_log_erro xmltype;
        T_name1 varchar2(20):='parameterS';
        T_name2 varchar2(20):='REFERENCIA';
        T_name3 varchar2(20):='ERRO';
      BEGIN
        P_LOG('error to add parameters', 1,'LOG.CRIAR.P_ADD_PRIVATE.ERRO',t_log_erro);
        P_ADD_PRIVATE(T_name1,p_name,t_log_erro,dup_error_count + 1,o_data,o_seq,o_update);
        P_ADD_PRIVATE(T_name3,SQLERRM,t_log_erro,dup_error_count + 1,o_data,o_seq,o_update);
        if(LOG_REFERENCE is not null) then
          P_ADD_PRIVATE(T_name2,LOG_REFERENCE.getClobVal(),t_log_erro, dup_error_count + 1,o_data,o_seq,o_update);
        else
          P_ADD_PRIVATE(T_name2,'N/A',t_log_erro, dup_error_count + 1,o_data,o_seq,o_update);
        end if;
      END;
    else
      dbms_output.put_line('unknow error in log, failed to add parameters');
    end if;

    RAISE;
END P_ADD_PRIVATE;

PROCEDURE P_ADD_PRIVATE(p_name          IN OUT VARCHAR2,
                          p_Value         IN clob,
                          LOG_REFERENCE   in OUT XMLTYPE

  ) AS
  T_data      timestamp(6); --data inicial do log
  T_seq       number(3);
  t_update    number(10);

  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  P_ADD_PRIVATE( P_name, p_Value, LOG_REFERENCE, 0,T_data,t_seq,t_update);
end;

PROCEDURE P_CONTEXT_PRIORITY(P_ID_PRIORITY IN NUMBER,p_CONTEXT in varchar2, LOG_REFERENCE in OUT XMLTYPE) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  T_data       timestamp(6); --data inicial do log
  T_DATA_CHAR  varchar2(40);
  T_seq        number(3);
  T_log_exists number;
  T_ID_CONTEXT NUMBER;
  T_PRIORITY NUMBER;
  T_ignore NUMBER:=0;
BEGIN
  T_seq  := fnc_extract_seq(LOG_REFERENCE);
  T_data := fnc_extract_data(LOG_REFERENCE);
  T_ignore:=fnc_extract_ignore(LOG_REFERENCE);
  
  --VE se o ambiente existe na tabela de PRIORITYs, caso n?o exista, insere e reinicia o processo com T_PRIORITY_DB preenchido
  IF(T_ignore=0) THEN
    IF(P_ID_PRIORITY IS NOT NULL) THEN
      IF(P_ID_PRIORITY<=0) THEN
        T_ignore:=1;
      ELSE

        BEGIN
          select p.PRIORITY_LEVEL
          INTO T_PRIORITY
          from LOG_AUDIT.t_PRIORITY p
          WHERE p.PRIORITY_LEVEL=P_ID_PRIORITY
          ;
        EXCEPTION WHEN OTHERS THEN
          T_ignore:=1;
        END;
      END IF;
  END IF;

    IF(T_ignore=0) THEN
      IF(LOG_REFERENCE is not null) THEN
        BEGIN
          SELECT L.PRIORITY_LEVEL
          INTO T_PRIORITY
          FROM LOG_AUDIT.t_Log L WHERE L.DATA_LOG=T_DATA AND L.SEQ=T_SEQ;
        EXCEPTION WHEN OTHERS THEN
          T_PRIORITY:=NULL;
        END;
      END IF;
      
      IF(P_CONTEXT IS NOT NULL) THEN
 
        LOG_AUDIT.PKG_LOG.P_CONTEXT( P_CONTEXT,T_PRIORITY, T_ID_CONTEXT);
      END IF;
      
      --associa menor PRIORITY possivel
      IF(T_PRIORITY IS NULL) THEN
           select max(p.PRIORITY_LEVEL)
           INTO T_PRIORITY
           from LOG_AUDIT.t_PRIORITY p;
      END IF;
      

      
      IF(T_PRIORITY<=G_PRIORITY_DB) THEN
        select count(1)
          into T_log_exists
          from LOG_AUDIT.t_log
         where DATA_LOG = T_data
           and seq = T_seq;

        if (T_log_exists = 0) then

          insert into LOG_AUDIT.t_log (data_LOG, seq, PRIORITY_LEVEL,ID_CONTEXT)
          values (T_data, T_seq, T_PRIORITY,T_ID_CONTEXT);

          T_DATA_CHAR := to_char(T_data, C_DATA_LOG_FORMAT);
          select xmlelement("log", xmlattributes(T_DATA_CHAR as "data",T_seq as "seq")) into LOG_REFERENCE from dual;
        end if;
      else
        T_ignore:=1;
      END IF;
    END IF;
    
    IF(T_ignore=1) THEN
      T_DATA_CHAR := to_char(T_data, C_DATA_LOG_FORMAT);
      select xmlelement("log", xmlattributes(T_DATA_CHAR as "data",T_seq as "seq",'1' as "ignore")) into LOG_REFERENCE from dual;
    END IF;

    commit;
  END IF;
END P_CONTEXT_PRIORITY;


PROCEDURE P_LOG(P_Mensagem IN VARCHAR2) AS
  LOG_REFERENCE xmltype;
BEGIN
  P_LOG(p_Mensagem ,NULL,null ,LOG_REFERENCE);
END P_LOG;

PROCEDURE P_LOG(P_Mensagem IN VARCHAR2,  LOG_REFERENCE IN OUT XMLTYPE) AS
BEGIN
  P_LOG(p_Mensagem ,NULL,null ,LOG_REFERENCE);
END P_LOG;


PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_CONTEXT IN Varchar2) AS
  LOG_REFERENCE xmltype;
BEGIN
  P_LOG(p_Mensagem ,NULL,P_CONTEXT ,LOG_REFERENCE);
END P_LOG;

PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_CONTEXT IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE) AS
BEGIN
  P_LOG(p_Mensagem ,NULL,P_CONTEXT ,LOG_REFERENCE);
END P_LOG;



PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_PRIORITY IN NUMBER) AS
  LOG_REFERENCE xmltype;
BEGIN
  P_LOG(p_Mensagem ,P_PRIORITY,null ,LOG_REFERENCE);
END P_LOG;

PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_PRIORITY IN NUMBER,  LOG_REFERENCE IN OUT XMLTYPE) AS
BEGIN
  P_LOG(p_Mensagem ,P_PRIORITY,null ,LOG_REFERENCE);
END P_LOG;

PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_PRIORITY IN NUMBER,P_CONTEXT IN Varchar2) AS
  LOG_REFERENCE xmltype;
BEGIN
  P_LOG(p_Mensagem ,P_PRIORITY,p_CONTEXT ,LOG_REFERENCE);
END P_LOG;


PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_PRIORITY IN NUMBER,P_CONTEXT IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  T_data     timestamp(6); --data inicial do log
  T_seq      number(3);
  t_update      number(10);
  T_temp_key varchar2(4000);
  t_mensagem varchar2(4000);

BEGIN
  P_CONTEXT_PRIORITY(P_PRIORITY,p_CONTEXT, LOG_REFERENCE);

  T_seq  := fnc_extract_seq(LOG_REFERENCE);
  T_data := fnc_extract_data  (LOG_REFERENCE);
  t_update := fnc_extract_update(LOG_REFERENCE)+1;

   --armazena a mensagem completa como um parameter clob e adiciona a chave do parameter no updatelog quando a mensagem for maior que 200 caracteres.
  if (length(p_Mensagem) > 200) then
    T_temp_key := p_Mensagem;
    P_add_PRIVATE(T_temp_key, p_Mensagem, LOG_REFERENCE);
    t_mensagem := T_temp_key;
  else
    t_mensagem := p_Mensagem;
  end if;
  
  if(fnc_extract_ignore(LOG_REFERENCE)=0) then
  
    --sobreescreve Value de t_update quando estiver trabalhando com tabelas
    
    SELECt nvl(MAX(COD_UPDATE), 0) + 1
    into t_update
        from LOG_AUDIT.t_update ul
       where uL.DATA_LOG = T_data
         and ul.seq = t_seq;

    insert into LOG_AUDIT.t_update(data_LOG, seq, COD_UPDATE, description)
     values(T_data,T_seq,t_update,t_mensagem)
    ;
    --select xmlelement("log", xmlattributes(t_update as "update",T_seq as "seq", to_char(T_data, C_DATA_LOG_FORMAT) as "data")) into LOG_REFERENCE from dual;
    commit;
  end if;

  select  XMLQuery('
    copy $i := $p1 modify(
      (: expressao par ainserir e modificar dados basicos do log e das atualizacoes sobre o mesmo :)
      insert node <update update="{$cod_update}" data="{$data}" description="{$description}" />
              as last into $i/log,

      if (fn:exists($i/log[1]/@data)) then (
        replace value of node $i/log[1]/@data with $datalog
      ) else (
        insert node attribute  data {$datalog} into $i/log[1]
      ),
      if (fn:exists($i/log[1]/@seq)) then (
        replace value of node $i/log[1]/@seq with $seq
      ) else (
        insert node attribute  seq {$seq} into $i/log[1]
      ),
      if (fn:exists($i/log[1]/@update)) then (
        replace value of node $i/log[1]/@update with $cod_update
      ) else (
        insert node attribute  update {$cod_update} into $i/log[1]
      )
    )
    return $i
    '
    PASSING
       LOG_REFERENCE AS "p1",
       to_char(T_data,C_DATA_LOG_FORMAT) AS "datalog",
       t_update as "cod_update",
       t_mensagem as "description",
       T_seq as "seq",
       to_char(systimestamp, 'yyyy-mm-dd"T"hh:mi:ss') as "data"
    RETURNING CONTENT) INTO LOG_REFERENCE from dual;

  EXCEPTION
  WHEN OTHERS THEN
    commit;
    RAISE;
END P_LOG;


PROCEDURE P_LOG_ERR(P_Mensagem IN VARCHAR2) AS
BEGIN
   P_LOG_ERR(P_Mensagem,'DEFAULT.ERRO');
END P_LOG_ERR;


PROCEDURE P_LOG_ERR(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2) AS
BEGIN
   P_LOG_ERR(P_Mensagem,P_CONTEXT,NULL);
END P_LOG_ERR;  


PROCEDURE P_LOG_ERR(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2,PARENT_LOG_REFERENCE IN xmltype) AS
  ERR_LOG_REFERENCE  xmltype;
BEGIN
   P_LOG_ERR(P_Mensagem,P_CONTEXT,PARENT_LOG_REFERENCE,ERR_LOG_REFERENCE);
END P_LOG_ERR;


PROCEDURE P_LOG_ERR(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2,  PARENT_LOG_REFERENCE IN  xmltype,ERR_LOG_REFERENCE IN OUT xmltype) AS
  T_REMOVE_SPACE_REGEX VARCHAR2(100):='(^[[:space:]]*|[[:space:]]*$)';
BEGIN
  p_log(P_Mensagem, 1, P_CONTEXT, ERR_LOG_REFERENCE);
  p_add('ERRO',REGEXP_REPLACE (sqlerrm,T_REMOVE_SPACE_REGEX,''), ERR_LOG_REFERENCE); 
  p_add('BACKTRACE',REGEXP_REPLACE (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,T_REMOVE_SPACE_REGEX,''), ERR_LOG_REFERENCE);
  p_add('CALL_STACK',REGEXP_REPLACE (DBMS_UTILITY.FORMAT_CALL_STACK,T_REMOVE_SPACE_REGEX,''), ERR_LOG_REFERENCE);
  
  IF(PARENT_LOG_REFERENCE IS NOT NULL) then
    p_add('REFERENCIA',PARENT_LOG_REFERENCE, ERR_LOG_REFERENCE);
  end if;
END P_LOG_ERR;

procedure P_ADD(p_name IN VARCHAR2, p_Value IN VARCHAR2, LOG_REFERENCE in OUT XMLTYPE) AS
  p_name_temp varchar2(40) := p_name;
  t_value clob:=CAST(p_Value AS CLOB);
BEGIN
  P_ADD(p_name_temp,t_value,LOG_REFERENCE);
end;

  

PROCEDURE P_ADD(p_name IN VARCHAR2, p_Value IN CLOB, LOG_REFERENCE in OUT XMLTYPE) AS
   PRAGMA AUTONOMOUS_TRANSACTION;
  T_data      timestamp(6); --data inicial do log
  T_seq       number(3);
  t_update    number(10);
  p_name_temp varchar2(40) := p_name;
BEGIN
  P_ADD_PRIVATE(p_name_temp, null, LOG_REFERENCE,0,T_data,T_seq,t_update);

  IF (p_Value IS NOT NULL AND fnc_extract_ignore(LOG_REFERENCE)=0) THEN
    
    insert into LOG_AUDIT.t_Parameter_CLOB
      SELECT T_data, T_seq,t_update, p_name_temp, p_Value
        FROM LOG_AUDIT.t_log l
       where L.DATA_LOG = T_data
         and l.seq = t_seq;
    commit;
  
  END IF;
  
--insert node attribute  dataType 1 into $i/log/update[last()]/parameter[last()]
 select  XMLQuery('
    copy $i := $p1 modify(
      replace value of node $i/log/update[last()]/parameter[last()] with $Value,
      insert node attribute  dataType {"4"} into $i/log/update[last()]/parameter[last()]
    )
    return $i
    '
    PASSING
       LOG_REFERENCE AS "p1",
       cast(substr(p_Value,1,3999) as varchar2(4000)) as "Value"
    RETURNING CONTENT) INTO LOG_REFERENCE from dual;

EXCEPTION
  WHEN OTHERS THEN
    P_LOG(SQLERRM, 1,'LOG.CRIAR.P_ADD.ERRO.NUMBER');
    rollback;
    RAISE;
END P_ADD;

PROCEDURE P_ADD(p_name IN VARCHAR2, p_Value IN NUMBER, LOG_REFERENCE in OUT XMLTYPE) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  T_data      timestamp(6); --data inicial do log
  T_seq       number(3);
  t_update    number(10);
  p_name_temp varchar2(40) := p_name;
BEGIN

  P_ADD_PRIVATE(p_name_temp, null, LOG_REFERENCE,0,T_data,T_seq,t_update);

  IF (p_Value IS NOT NULL AND fnc_extract_ignore(LOG_REFERENCE)=0) THEN
    insert into LOG_AUDIT.t_Parameter_Number
      SELECT T_data, T_seq,t_update, p_name_temp, p_Value
        FROM LOG_AUDIT.t_log l
       where L.DATA_LOG = T_data
         and l.seq = t_seq;
    commit;
  END IF;
--insert node attribute  dataType 1 into $i/log/update[last()]/parameter[last()]
 select  XMLQuery('
    copy $i := $p1 modify(
      replace value of node $i/log/update[last()]/parameter[last()] with $Value,
      insert node attribute  dataType {"2"} into $i/log/update[last()]/parameter[last()]
    )
    return $i
    '
    PASSING
       LOG_REFERENCE AS "p1",
       p_Value as "Value"
    RETURNING CONTENT) INTO LOG_REFERENCE from dual;

EXCEPTION
  WHEN OTHERS THEN
    P_LOG(SQLERRM, 1,'LOG.CRIAR.P_ADD.ERRO.NUMBER');
    rollback;
    RAISE;
END P_ADD;

PROCEDURE P_ADD(p_name IN VARCHAR2, p_Value IN DATE, LOG_REFERENCE in OUT XMLTYPE) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  T_data      timestamp(6); --data inicial do log
  T_seq       number(3);
  t_update    number(10);
  p_name_temp varchar2(40) := p_name;
BEGIN

  P_ADD_PRIVATE(p_name_temp, null, LOG_REFERENCE,0,T_data,T_seq,t_update);

  IF (p_Value IS NOT NULL AND fnc_extract_ignore(LOG_REFERENCE)=0) THEN
    insert into LOG_AUDIT.t_Parameter_Date
      SELECT T_data, T_seq,t_update, p_name_temp, p_Value
        FROM LOG_AUDIT.t_log l
       where L.DATA_LOG = T_data
         and l.seq = t_seq;
    commit;
  END IF;

 select  XMLQuery('
    copy $i := $p1 modify(
      replace value of node $i/log/update[last()]/parameter[last()] with $Value,
      insert node attribute  dataType {"3"} into $i/log/update[last()]/parameter[last()]
    )
    return $i
    '
 PASSING
    LOG_REFERENCE AS "p1",
    to_char(p_Value, 'yyyy-mm-dd"T"hh:mi:ss') as "Value"
 RETURNING CONTENT) INTO LOG_REFERENCE from dual;

EXCEPTION
  WHEN OTHERS THEN
    P_LOG(SQLERRM, 1,'LOG.CRIAR.P_ADD.ERRO.DATE');
    rollback;
    RAISE;
END P_ADD;

PROCEDURE P_ADD(p_name IN VARCHAR2, p_Value IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
  T_data      timestamp(6); --data inicial do log
  T_seq       number(3);
  t_update    number(10);
  p_name_temp varchar2(40) := p_name;
  T_IMPORTED NUMBER(1):=0;
BEGIN    
  -- Se for um xml do tipo log, tenta importar os parameters
  IF(P_Value.EXISTSNODE('/log/update/parameter')=1) THEN
  	BEGIN
      P_IMPORT_LOG(p_name,p_Value,LOG_REFERENCE);
      --ADICIONA REFERENCIA ANTIGA

      T_IMPORTED:=1;
      EXCEPTION WHEN OTHERS THEN
        P_LOG_ERR('ERROR IMPORTING LOGS', 'LOG.IMPORT');
        T_IMPORTED:=0;
        
    END;
  END IF;
  
  IF(T_IMPORTED=0) THEN
    P_ADD_PRIVATE(p_name_temp, null, LOG_REFERENCE,0,T_data,T_seq,t_update);

    IF (p_Value IS NOT NULL AND fnc_extract_ignore(LOG_REFERENCE)=0) THEN
      begin
        insert into LOG_AUDIT.t_Parameter_Xml
          SELECT T_data, T_seq,t_update, p_name_temp, p_Value
            FROM LOG_AUDIT.t_log l
           where L.DATA_LOG = T_data
             and l.seq = t_seq;
        commit;
      
      exception when others then
        declare 
          t_value xmltype;
        begin
          if(SQLCODE=-19010) then --there is no root node, need a root node
            t_value:=xmltype('<root>'||p_Value.getClobVal() ||'</root>');
          else
            RAISE;
          end if;
  
  
          insert into LOG_AUDIT.t_Parameter_Xml
          SELECT T_data, T_seq,t_update, p_name_temp, t_value
            FROM LOG_AUDIT.t_log l
           where L.DATA_LOG = T_data
             and l.seq = t_seq;
          commit;
        end;
      end;
    END IF;
  
    
    select  XMLQuery('
      copy $i := $p1 modify(
        insert node attribute  dataType {"1"} into $i/log/update[last()]/parameter[last()],
        insert node $Value into $i/log/update[last()]/parameter[last()]
      )
      return $i
      '
   PASSING
      LOG_REFERENCE AS "p1",
      p_Value as "Value"
   RETURNING CONTENT) INTO LOG_REFERENCE from dual;
 END IF;

EXCEPTION
  WHEN OTHERS THEN
    P_LOG(SQLERRM, 1,'LOG.CRIAR.P_ADD.ERRO.XML');
    rollback;
    --try to save as clob
    p_add(p_name , p_Value.getClobVal() , LOG_REFERENCE );
    --RAISE;
END P_ADD;



PROCEDURE P_IMPORT_LOG(p_name IN VARCHAR2,p_LOG_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE) AS
  T_PARAMETER_REFERENCE XMLTYPE;
BEGIN
  
  SELECT LOG_AUDIT.PKG_LOG.F_METADATA_BASIC(p_LOG_XML)
  INTO T_PARAMETER_REFERENCE
  FROM DUAL;
  
  P_log('IMPORTADO LOG',LOG_REFERENCE);
  P_ADD(p_name,T_PARAMETER_REFERENCE ,LOG_REFERENCE);
  
  FOR C_UPDATE IN (
    SELECT *
    FROM 
      XMLTable('for $i in /log/update return $i'
      PASSING p_LOG_XML
      COLUMNS 
        cod_Update   number  PATH '@update',
        data_Update  VARCHAR2(19) PATH '@data',
        description  VARCHAR2(200) PATH '@description',
        parameter  xmltype PATH '/parameter'
    )
  ) LOOP
    P_LOG(C_UPDATE.description,LOG_REFERENCE);
    P_IMPORT_PARAMETER( C_UPDATE.parameter,LOG_REFERENCE);
  END LOOP;
END;

PROCEDURE P_IMPORT_PARAMETER(p_PARAMETERS_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE) AS
BEGIN
  
   FOR C_PARAMETER IN (
      SELECT *
      FROM 
        XMLTable('for $i in //parameter return $i'
        PASSING p_PARAMETERS_XML
        COLUMNS 
          name  VARCHAR2(19)  PATH '@name',
          Value xmltype PATH '/parameter',
          dataType NUMBER PATH '@dataType',
          this xmltype path '.'
      )
    ) LOOP
      begin
        IF( C_PARAMETER.dataType=1) THEN
          P_ADD(C_PARAMETER.name,C_PARAMETER.Value.extract('/parameter/*'),LOG_REFERENCE);
        ELSIF( C_PARAMETER.dataType=2) THEN
          P_ADD(C_PARAMETER.name,C_PARAMETER.Value.extract('/parameter/text()').getnumberVal(),LOG_REFERENCE);
        ELSIF( C_PARAMETER.dataType=3) THEN
          P_ADD(C_PARAMETER.name,TO_DATE(C_PARAMETER.Value.extract('/parameter/text()').getstringval(),'yyyy-mm-dd"T"hh:mi:ss'),LOG_REFERENCE);
        ELSE
          
          declare 
            t_clob clob;
          begin
            select EXTRACTVALUE(C_PARAMETER.Value,'/parameter/text()')
            into t_clob
            from dual;
            
            if(t_clob is not null) then
              P_ADD(C_PARAMETER.name,t_clob,LOG_REFERENCE);
            else
              P_ADD(C_PARAMETER.name,'NULL',LOG_REFERENCE);
            end if;
          end;
        END IF;
  
        exception when others then
          P_log('could not import parameter',LOG_REFERENCE);
          P_ADD('error',SQLERRM,LOG_REFERENCE);
          P_ADD('name',C_PARAMETER.name,LOG_REFERENCE);
          P_ADD('dataType',C_PARAMETER.dataType,LOG_REFERENCE);
           P_ADD('this',C_PARAMETER.this,LOG_REFERENCE);
      end;
    END LOOP;
END;

-- Setando variaveis estaticas do ambiente

BEGIN
  P_SET;

END PKG_LOG;
