CREATE OR REPLACE PACKAGE BODY LOG_AUDITORIA.PKG_LOG IS
   --formato adotado para o timestamp da pk do log
  C_DATA_LOG_FORMAT  VARCHAR2(100) := 'YYYY-MM-DD"T"hh24:mi:ss.ff6';
  G_PRIORIDADE_BANCO NUMBER;

  function is_number(p_string in varchar2) return int is
    v_new_num number;
  begin
    v_new_num := to_number(p_string, '99999999999999999999990.00');

    return 1;
    dbms_output.put_line(v_new_num);
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

  FUNCTION fnc_extract_ignorar(LOG_REFERENCE xmltype) return NUMBER IS
  BEGIN
    IF (LOG_REFERENCE is not null and LOG_REFERENCE.EXTRACT('/log/@ignorar') IS NOT NULL) THEN
      RETURN LOG_REFERENCE.EXTRACT('/log/@ignorar').getnumberval();
    else
      return 0;
    END IF;
  END fnc_extract_ignorar;

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

  FUNCTION fnc_generate_time_key(prefix varchar2, precisao number, maxsize number) return varchar2 IS
    T_key   varchar2(20);
    T_saida varchar2(200);
    t_size  number;
  BEGIN

    if (maxsize < 15) then
      t_size := 15;
    else
      t_size := maxsize;
    end if;

    select case precisao
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
        dbms_output.put_line('FORMATO: '||C_DATA_LOG_FORMAT);
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

    if(is_number(p_xml,'/log/@ignorar')=1) then
       t_logkey.ignorar  := p_xml.extract('/log/@ignorar').getnumberval;
    end if;

    pipe row(t_logkey);
    return;
  END;
  
  FUNCTION F_CONTEXTO_LEAF(p_ID_RELACAO NUMBER) return t_contextotree_recordtype
    pipelined is
    t_contextotree r_contextotree_recordtype;
  BEGIN
    
    FOR c_contextotree IN (
      SELECT cr.id_relacao,cr.id_relacao_pai,c.id AS ID_CONTEXTO,c.CONTEXTO,ID_PRIORIDADE_DEFAULT,
           level as nivel,
           RPAD(' ', (level-1)*2, '  ') || c.CONTEXTO AS tree,
           CONNECT_BY_ROOT cr.id_relacao AS root,
           LTRIM(SYS_CONNECT_BY_PATH(cr.id_relacao, '-'), '-') AS path,
           LTRIM(SYS_CONNECT_BY_PATH(C.CONTEXTO, '.'), '.') AS PATH_CONTEXTO,
           CONNECT_BY_ISLEAF AS leaf
      FROM LOG_AUDITORIA.tab_contexto c
          join LOG_AUDITORIA.tab_contexto_relacao cr on c.id=cr.id_contexto
      START WITH cr.id_relacao =p_ID_RELACAO
      CONNECT BY PRIOR cr.id_relacao_pai =  cr.id_relacao
      ORDER SIBLINGS BY cr.id_relacao_pai  
    ) LOOP
      t_contextotree.ID_RELACAO := c_contextotree.ID_RELACAO;
      t_contextotree.ID_RELACAO_PAI := c_contextotree.ID_RELACAO_PAI;
      t_contextotree.ID_CONTEXTO := c_contextotree.ID_CONTEXTO;
      t_contextotree.CONTEXTO := c_contextotree.CONTEXTO;
      t_contextotree.ID_PRIORIDADE_DEFAULT := c_contextotree.ID_PRIORIDADE_DEFAULT;
      t_contextotree.NIVEL := c_contextotree.NIVEL;
      t_contextotree.TREE := c_contextotree.TREE;
      t_contextotree.ROOT := c_contextotree.ROOT;
      t_contextotree.PATH := c_contextotree.PATH;
      t_contextotree.PATH_CONTEXTO := c_contextotree.PATH_CONTEXTO;
      t_contextotree.LEAF := c_contextotree.LEAF;
      pipe row(t_contextotree);
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

    newXml:= log_auditoria.pkg_log.F_METADATA_BASIC(p_xml);
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

  PROCEDURE P_CONTEXTO(
    P_TEXT VARCHAR2,
    PO_ID_PRIORIDADE IN OUT NUMBER,
    O_ID_RELACAO OUT NUMBER
    --O_PRIORIDADE OUT NUMBER
  ) AS
    T_MAX_LEVEL NUMBER;
    T_ID_RELACAO NUMBER;
    O_PRIORIDADE NUMBER;
    TEXT VARCHAR2(130);
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    TEXT :=upper(P_TEXT);
    MERGE INTO LOG_AUDITORIA.tab_contexto T
    USING(
      SELECT  C.text AS CONTEXTO
      FROM TABLE(LOG_AUDITORIA.PKG_UTIL.F_SPLIT_DISTINCT(TEXT)) C
      ORDER BY C.ID
    ) S ON (T.CONTEXTO = S.CONTEXTO)
    --WHEN MATCHED THEN UPDATE SET T.IDPAI =  S.IDPAI
    WHEN NOT MATCHED THEN INSERT (T.CONTEXTO)
         VALUES (S.CONTEXTO )
    ;

    select MAX(ID)
    INTO T_MAX_LEVEL
    from TABLE(LOG_AUDITORIA.PKG_UTIL.F_SPLIT_DISTINCT(TEXT));

    DECLARE
        T_ID_RELACAO NUMBER;
        T_ID_RELACAO_PAI NUMBER;
      BEGIN

      FOR NTREE IN (
      SELECT
              NTREE.*,
               CASE WHEN  NTREE.NIVEL=T_MAX_LEVEL
                 THEN PO_ID_PRIORIDADE
                 ELSE NULL
              END ID_PRIORIDADE_DEFAULT
          FROM (
            with cte as(
                 select * from TABLE(LOG_AUDITORIA.PKG_UTIL.F_SPLIT(TEXT))
            )
            select
               C.ID id_contexto,C.CONTEXTO,
               level as nivel,
               RPAD(' ', (level-1)*2, '  ') || c.CONTEXTO AS tree,
               CONNECT_BY_ROOT c.id AS root,
               LTRIM(SYS_CONNECT_BY_PATH(c.id, '-'), '-') AS path,
               CONNECT_BY_ISLEAF AS leaf

            from cte  TC
                JOIN LOG_AUDITORIA.tab_contexto C ON C.CONTEXTO=TC.TEXT
                LEFT JOIN cte TCP ON TC.ID-1=TCP.ID

            START WITH TCP.ID IS NULL
            CONNECT BY TCP.ID = PRIOR TC.ID
            ORDER SIBLINGS BY TCP.ID
            ) NTREE
      ) LOOP
            --pega a relacao anterior
            T_ID_RELACAO_PAI:=T_ID_RELACAO;

            BEGIN
              SELECT ID_RELACAO,ID_PRIORIDADE_DEFAULT
              INTO T_ID_RELACAO,O_PRIORIDADE
              FROM LOG_AUDITORIA.V_CONTEXTO OTREE
              WHERE NTREE.NIVEL=OTREE.NIVEL AND NTREE.ID_CONTEXTO=OTREE.ID_CONTEXTO AND (T_ID_RELACAO_PAI IS NULL OR T_ID_RELACAO_PAI=ID_RELACAO_PAI)
              ;
              IF(NTREE.ID_PRIORIDADE_DEFAULT is not null)THEN
                  UPDATE LOG_AUDITORIA.TAB_CONTEXTO_RELACAO
                  SET ID_PRIORIDADE_DEFAULT =  NTREE.ID_PRIORIDADE_DEFAULT
                  WHERE ID_RELACAO=T_ID_RELACAO
                  ;
              END IF;
            EXCEPTION WHEN OTHERS THEN
              --gera id da nova relacao
              T_ID_RELACAO:= LOG_AUDITORIA.seq_contexto_relacao.nextval;
              O_PRIORIDADE:=NTREE.ID_PRIORIDADE_DEFAULT;

              INSERT INTO LOG_AUDITORIA.TAB_CONTEXTO_RELACAO(ID_RELACAO,ID_RELACAO_PAI,ID_CONTEXTO,ID_PRIORIDADE_DEFAULT)
              values(T_ID_RELACAO,T_ID_RELACAO_PAI,NTREE.ID_CONTEXTO,NTREE.ID_PRIORIDADE_DEFAULT)
              ;
            END;

        END LOOP;

        O_ID_RELACAO:=T_ID_RELACAO;
        PO_ID_PRIORIDADE:=O_PRIORIDADE;
      END;


    commit;

  EXCEPTION
    WHEN OTHERS THEN
      P_LOG(SQLERRM, 1,'LOG.MANTER.CONTEXTO.ERRO');

      rollback;
      RAISE;
  END P_CONTEXTO;


  PROCEDURE P_ADD_INTERNA(p_Nome          IN OUT VARCHAR2,
                            p_Valor         IN clob,
                            LOG_REFERENCE   in OUT XMLTYPE,
                            dup_error_count in number default 0,
                            o_data          out timestamp,
                            o_seq           out number,
                            o_update        out number
    ) AS

    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    if (length(p_Nome) > 20) then
      p_Nome := substr(p_Nome, 1, 17) || '...';
    end if;

    if(fnc_extract_ignorar(LOG_REFERENCE)=0) then
      --P_LOG(P_ID_PRIORIDADE,LOG_REFERENCE);
      o_data := fnc_extract_data(LOG_REFERENCE);
      o_seq  := fnc_extract_seq(LOG_REFERENCE);
      o_update := fnc_extract_update(LOG_REFERENCE);
      
      insert into LOG_AUDITORIA.Tab_Parameter
      values(o_data, o_seq,o_update, p_Nome, p_Valor);

      commit;
    end if;

    select  XMLQuery('
      copy $i := $p1 modify(
        insert node <parametro nome="{$nome}">{$valor}</parametro>
                as last into $i/log/update[last()]
      )
      return $i
      '
    PASSING
      LOG_REFERENCE AS "p1",
      p_Nome AS "nome",
      to_char(substr(p_Valor,1,4000)) as "valor"
    RETURNING CONTENT) INTO LOG_REFERENCE from dual;



  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      rollback;

      p_Nome := fnc_generate_time_key(p_Nome, dup_error_count, 20);
      P_ADD_interna( P_NOME, p_Valor, LOG_REFERENCE, dup_error_count + 1,o_data,o_seq,o_update);
    WHEN OTHERS THEN
      rollback;

      if(dup_error_count<2) then
        DECLARE
          t_log_erro xmltype;
          T_NOME1 varchar2(20):='PARAMETROS';
          T_NOME2 varchar2(20):='REFERENCIA';
          T_NOME3 varchar2(20):='ERRO';
        BEGIN
          P_LOG('erro ao adicionar parametros', 1,'LOG.CRIAR.P_ADD_INTERNA.ERRO',t_log_erro);
          P_ADD_INTERNA(T_NOME1,p_Nome,t_log_erro,dup_error_count + 1,o_data,o_seq,o_update);
          P_ADD_interna(T_NOME3,SQLERRM,t_log_erro,dup_error_count + 1,o_data,o_seq,o_update);
          if(LOG_REFERENCE is not null) then
            P_ADD_INTERNA(T_NOME2,LOG_REFERENCE.getClobVal(),t_log_erro, dup_error_count + 1,o_data,o_seq,o_update);
          else
            P_ADD_INTERNA(T_NOME2,'N/A',t_log_erro, dup_error_count + 1,o_data,o_seq,o_update);
          end if;
        END;
      else
        dbms_output.put_line('erro desconhecido no log! N?o ? poss?vel adicionar parametros');
      end if;

      RAISE;
  END P_ADD_interna;

  PROCEDURE P_ADD_INTERNA(p_Nome          IN OUT VARCHAR2,
                            p_Valor         IN clob,
                            LOG_REFERENCE   in OUT XMLTYPE

    ) AS
    T_data      timestamp(6); --data inicial do log
    T_seq       number(3);
    t_update    number(10);

    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    P_ADD_interna( P_NOME, p_Valor, LOG_REFERENCE, 0,T_data,t_seq,t_update);
  end;

  PROCEDURE P_CONTEXTO_PRIORIDADE(P_ID_PRIORIDADE IN NUMBER,p_Contexto in varchar2, LOG_REFERENCE in OUT XMLTYPE) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    T_data       timestamp(6); --data inicial do log
    T_DATA_CHAR  varchar2(40);
    T_seq        number(3);
    T_log_exists number;
    T_ID_RELACAO NUMBER;
    T_PRIORIDADE NUMBER;
    T_IGNORAR NUMBER:=0;
  BEGIN

    T_seq  := fnc_extract_seq(LOG_REFERENCE);
    T_data := fnc_extract_data(LOG_REFERENCE);
    T_IGNORAR:=fnc_extract_ignorar(LOG_REFERENCE);
    --VE se o ambiente existe na tabela de prioridades, caso n?o exista, insere e reinicia o processo com T_PRIORIDADE_BANCO preenchido
    IF(T_IGNORAR=0) THEN
      IF(P_ID_PRIORIDADE IS NOT NULL) THEN
        IF(P_ID_PRIORIDADE<=0) THEN
          T_IGNORAR:=1;
        ELSE
          BEGIN
            select p.id
            INTO T_PRIORIDADE
            from log_auditoria.tab_prioridade p
            WHERE p.id=P_ID_PRIORIDADE
            ;
          EXCEPTION WHEN OTHERS THEN
            T_IGNORAR:=1;
          END;
        END IF;
      END IF;
 
      IF(T_IGNORAR=0) THEN
        IF(LOG_REFERENCE is not null) THEN
          BEGIN
            SELECT L.TIPO
            INTO T_PRIORIDADE
            FROM log_auditoria.Tab_Log L WHERE L.DATA_LOG=T_DATA AND L.SEQ=T_SEQ;
          EXCEPTION WHEN OTHERS THEN
            T_PRIORIDADE:=NULL;
          END;
        END IF;
        
        IF(p_Contexto is not null) then
          log_auditoria.pkg_log.P_CONTEXTO(
             p_Contexto,
             T_PRIORIDADE,
             T_ID_RELACAO
          );
        END IF;
        
        --associa menor prioridade possivel
        IF(T_PRIORIDADE IS NULL) THEN
             select max(p.id)
             INTO T_PRIORIDADE
             from log_auditoria.tab_prioridade p;
        END IF;
        
        IF(T_PRIORIDADE<=G_PRIORIDADE_BANCO) THEN
          select count(1)
            into T_log_exists
            from LOG_AUDITORIA.tab_log
           where DATA_LOG = T_data
             and seq = T_seq;

          if (T_log_exists = 0) then
            insert into LOG_AUDITORIA.tab_log (data_LOG, seq, tipo,id_relacao)
            values (T_data, T_seq, T_PRIORIDADE,T_ID_RELACAO);

            T_DATA_CHAR := to_char(T_data, C_DATA_LOG_FORMAT);
            select xmlelement("log", xmlattributes(T_DATA_CHAR as "data",T_seq as "seq")) into LOG_REFERENCE from dual;
          end if;
        else
          T_IGNORAR:=1;
        END IF;
      END IF;
      
      IF(T_IGNORAR=1) THEN
        T_DATA_CHAR := to_char(T_data, C_DATA_LOG_FORMAT);
        select xmlelement("log", xmlattributes(T_DATA_CHAR as "data",T_seq as "seq",'1' as "ignorar")) into LOG_REFERENCE from dual;
      END IF;

      commit;
    END IF;
  END P_CONTEXTO_PRIORIDADE;


  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2) AS
    LOG_REFERENCE xmltype;
  BEGIN
    P_LOG(p_Mensagem ,NULL,null ,LOG_REFERENCE);
  END P_LOG;

  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2,  LOG_REFERENCE IN OUT XMLTYPE) AS
  BEGIN
    P_LOG(p_Mensagem ,NULL,null ,LOG_REFERENCE);
  END P_LOG;


  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_Contexto IN Varchar2) AS
    LOG_REFERENCE xmltype;
  BEGIN
    P_LOG(p_Mensagem ,NULL,P_Contexto ,LOG_REFERENCE);
  END P_LOG;

  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_Contexto IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE) AS
  BEGIN
    P_LOG(p_Mensagem ,NULL,P_Contexto ,LOG_REFERENCE);
  END P_LOG;



  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_Prioridade IN NUMBER) AS
    LOG_REFERENCE xmltype;
  BEGIN
    P_LOG(p_Mensagem ,P_Prioridade,null ,LOG_REFERENCE);
  END P_LOG;

  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_Prioridade IN NUMBER,  LOG_REFERENCE IN OUT XMLTYPE) AS
  BEGIN
    P_LOG(p_Mensagem ,P_Prioridade,null ,LOG_REFERENCE);
  END P_LOG;

  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_Prioridade IN NUMBER,P_Contexto IN Varchar2) AS
    LOG_REFERENCE xmltype;
  BEGIN
    P_LOG(p_Mensagem ,P_Prioridade,p_contexto ,LOG_REFERENCE);
  END P_LOG;


  PROCEDURE P_LOG(P_Mensagem IN VARCHAR2, P_Prioridade IN NUMBER,P_Contexto IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    T_data     timestamp(6); --data inicial do log
    T_seq      number(3);
    t_update      number(10);
    T_temp_key varchar2(4000);
    t_mensagem varchar2(4000);

  BEGIN
    P_CONTEXTO_PRIORIDADE(P_PRIORIDADE,p_contexto, LOG_REFERENCE);

    T_seq  := fnc_extract_seq(LOG_REFERENCE);
    T_data := fnc_extract_data  (LOG_REFERENCE);
    t_update := fnc_extract_update(LOG_REFERENCE)+1;

     --armazena a mensagem completa como um parametro clob e adiciona a chave do parametro no updatelog quando a mensagem for maior que 200 caracteres.
    if (length(p_Mensagem) > 200) then
      T_temp_key := p_Mensagem;
      P_add_interna(T_temp_key, p_Mensagem, LOG_REFERENCE);
      t_mensagem := T_temp_key;
    else
      t_mensagem := p_Mensagem;
    end if;

    if(fnc_extract_ignorar(LOG_REFERENCE)=0) then
      --sobreescreve valor de t_update quando estiver trabalhando com tabelas
      SELECt nvl(MAX(COD_UPDATE), 0) + 1
      into t_update
          from LOG_AUDITORIA.tab_update ul
         where uL.DATA_LOG = T_data
           and ul.seq = t_seq;
      insert into LOG_AUDITORIA.tab_update(data_LOG, seq, COD_UPDATE, descricao)
       values(T_data,T_seq,t_update,t_mensagem)
      ;
      --select xmlelement("log", xmlattributes(t_update as "update",T_seq as "seq", to_char(T_data, C_DATA_LOG_FORMAT) as "data")) into LOG_REFERENCE from dual;
      commit;
    end if;

    select  XMLQuery('
      copy $i := $p1 modify(
        (: expressao par ainserir e modificar dados basicos do log e das atualizacoes sobre o mesmo :)
        insert node <update update="{$cod_update}" data="{$data}" descricao="{$descricao}" />
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
         t_mensagem as "descricao",
         T_seq as "seq",
         to_char(systimestamp, 'yyyy-mm-dd"T"hh:mi:ss') as "data"
      RETURNING CONTENT) INTO LOG_REFERENCE from dual;


  END P_LOG;

  
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2) AS
  BEGIN
     P_LOG_ERRO(P_Mensagem,'DEFAULT.ERRO');
  END P_LOG_ERRO;
  
  
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2) AS
  BEGIN
     P_LOG_ERRO(P_Mensagem,P_Contexto,NULL);
  END P_LOG_ERRO;  
  
  
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2,PARENT_LOG_REFERENCE IN xmltype) AS
    ERR_LOG_REFERENCE  xmltype;
  BEGIN
     P_LOG_ERRO(P_Mensagem,P_Contexto,PARENT_LOG_REFERENCE,ERR_LOG_REFERENCE);
  END P_LOG_ERRO;
  
  
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2,  PARENT_LOG_REFERENCE IN  xmltype,ERR_LOG_REFERENCE IN OUT xmltype) AS
    T_REMOVE_SPACE_REGEX VARCHAR2(100):='(^[[:space:]]*|[[:space:]]*$)';
  BEGIN
    p_log(P_Mensagem, 1, P_Contexto, ERR_LOG_REFERENCE);
    p_add('ERRO',REGEXP_REPLACE (sqlerrm,T_REMOVE_SPACE_REGEX,''), ERR_LOG_REFERENCE); 
    p_add('BACKTRACE',REGEXP_REPLACE (DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,T_REMOVE_SPACE_REGEX,''), ERR_LOG_REFERENCE);
    p_add('CALL_STACK',REGEXP_REPLACE (DBMS_UTILITY.FORMAT_CALL_STACK,T_REMOVE_SPACE_REGEX,''), ERR_LOG_REFERENCE);
    
    IF(PARENT_LOG_REFERENCE IS NOT NULL) then
      p_add('REFERENCIA',PARENT_LOG_REFERENCE, ERR_LOG_REFERENCE);
    end if;
  END P_LOG_ERRO;
  
  procedure P_ADD(p_Nome IN VARCHAR2, p_Valor IN VARCHAR2, LOG_REFERENCE in OUT XMLTYPE) AS
    p_nome_temp varchar2(40) := p_Nome;
  BEGIN
    P_ADD_interna(p_nome_temp, p_valor, LOG_REFERENCE);
    if (p_nome_temp <> p_Nome) then
      dbms_output.put_line('parametro ' || p_Nome || ' ja existia. Novo nome: ' || p_nome_temp);
    end if;
  end;


  PROCEDURE P_ADD(p_Nome IN VARCHAR2, p_Valor IN CLOB, LOG_REFERENCE in OUT XMLTYPE) AS
    p_nome_temp varchar2(40) := p_Nome;
  BEGIN
    P_ADD_interna(p_nome_temp, p_valor, LOG_REFERENCE);
    if (p_nome_temp <> p_Nome) then
      dbms_output.put_line('parametro ' || p_Nome || ' ja existia. Novo nome: ' || p_nome_temp);
    end if;
  end;

  PROCEDURE P_ADD(p_Nome IN VARCHAR2, p_Valor IN NUMBER, LOG_REFERENCE in OUT XMLTYPE) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    T_data      timestamp(6); --data inicial do log
    T_seq       number(3);
    t_update    number(10);
    p_nome_temp varchar2(40) := p_Nome;
  BEGIN

    P_ADD_interna(p_nome_temp, null, LOG_REFERENCE,0,T_data,T_seq,t_update);

    IF (p_Valor IS NOT NULL AND fnc_extract_ignorar(LOG_REFERENCE)=0) THEN
      insert into LOG_AUDITORIA.Tab_Parameter_Number
        SELECT T_data, T_seq,t_update, p_nome_temp, p_Valor
          FROM LOG_AUDITORIA.tab_log l
         where L.DATA_LOG = T_data
           and l.seq = t_seq;
      commit;
    END IF;
--insert node attribute  dataType 1 into $i/log/update[last()]/parametro[last()]
   select  XMLQuery('
      copy $i := $p1 modify(
        replace value of node $i/log/update[last()]/parametro[last()] with $valor,
        insert node attribute  dataType {"2"} into $i/log/update[last()]/parametro[last()]
      )
      return $i
      '
      PASSING
         LOG_REFERENCE AS "p1",
         p_Valor as "valor"
      RETURNING CONTENT) INTO LOG_REFERENCE from dual;

  EXCEPTION
    WHEN OTHERS THEN
      P_LOG(SQLERRM, 1,'LOG.CRIAR.P_ADD.ERRO.NUMBER');
      rollback;
      RAISE;
  END P_ADD;

  PROCEDURE P_ADD(p_Nome IN VARCHAR2, p_Valor IN DATE, LOG_REFERENCE in OUT XMLTYPE) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    T_data      timestamp(6); --data inicial do log
    T_seq       number(3);
    t_update    number(10);
    p_nome_temp varchar2(40) := p_Nome;
  BEGIN

    P_ADD_interna(p_nome_temp, null, LOG_REFERENCE,0,T_data,T_seq,t_update);

    IF (p_Valor IS NOT NULL AND fnc_extract_ignorar(LOG_REFERENCE)=0) THEN
      insert into LOG_AUDITORIA.Tab_Parameter_Data
        SELECT T_data, T_seq,t_update, p_nome_temp, p_Valor
          FROM LOG_AUDITORIA.tab_log l
         where L.DATA_LOG = T_data
           and l.seq = t_seq;
      commit;
    END IF;

   select  XMLQuery('
      copy $i := $p1 modify(
        replace value of node $i/log/update[last()]/parametro[last()] with $valor,
        insert node attribute  dataType {"3"} into $i/log/update[last()]/parametro[last()]
      )
      return $i
      '
   PASSING
      LOG_REFERENCE AS "p1",
      to_char(p_Valor, 'yyyy-mm-dd"T"hh:mi:ss') as "valor"
   RETURNING CONTENT) INTO LOG_REFERENCE from dual;

  EXCEPTION
    WHEN OTHERS THEN
      P_LOG(SQLERRM, 1,'LOG.CRIAR.P_ADD.ERRO.DATE');
      rollback;
      RAISE;
  END P_ADD;

  PROCEDURE P_ADD(p_Nome IN VARCHAR2, p_Valor IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    T_data      timestamp(6); --data inicial do log
    T_seq       number(3);
    t_update    number(10);
    p_nome_temp varchar2(40) := p_Nome;
    T_IMPORTED NUMBER(1):=0;
  BEGIN    
    -- Se for um xml do tipo log, tenta importar os parametros
    IF(P_VALOR.EXISTSNODE('/log/update/parametro')=1) THEN
    	BEGIN
        P_IMPORT_PARAMETER(p_Valor,LOG_REFERENCE);
        --ADICIONA REFERENCIA ANTIGA
        
        P_ADD(P_NOME,F_METADATA_BASIC(P_VALOR),LOG_REFERENCE);
       
       
        T_IMPORTED:=1;
        EXCEPTION WHEN OTHERS THEN
          P_LOG_ERRO('ERRO AO IMPORTAR LOGS', 'LOG.IMPORTAR');
          T_IMPORTED:=0;
          
      END;
    END IF;
    
    IF(T_IMPORTED=0) THEN
      P_ADD_interna(p_nome_temp, null, LOG_REFERENCE,0,T_data,T_seq,t_update);

      IF (p_Valor IS NOT NULL AND fnc_extract_ignorar(LOG_REFERENCE)=0) THEN
        insert into LOG_AUDITORIA.Tab_Parameter_Xml
          SELECT T_data, T_seq,t_update, p_nome_temp, p_Valor
            FROM LOG_AUDITORIA.tab_log l
           where L.DATA_LOG = T_data
             and l.seq = t_seq;
        commit;
      END IF;
    
      
      select  XMLQuery('
        copy $i := $p1 modify(
          insert node attribute  dataType {"1"} into $i/log/update[last()]/parametro[last()],
          insert node $valor into $i/log/update[last()]/parametro[last()]
        )
        return $i
        '
     PASSING
        LOG_REFERENCE AS "p1",
        p_Valor as "valor"
     RETURNING CONTENT) INTO LOG_REFERENCE from dual;
   END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_LOG(SQLERRM, 1,'LOG.CRIAR.P_ADD.ERRO.XML');
      rollback;
      RAISE;
  END P_ADD;



  PROCEDURE P_IMPORT_LOG(p_Nome IN VARCHAR2,p_LOG_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE) AS
    T_PARAMETER_REFERENCE XMLTYPE;
  BEGIN
    
    SELECT LOG_AUDITORIA.PKG_LOG.F_METADATA_BASIC(p_LOG_XML)
    INTO T_PARAMETER_REFERENCE
    FROM DUAL;
    
    P_log('IMPORTADO LOG',LOG_REFERENCE);
    P_ADD(p_Nome,T_PARAMETER_REFERENCE ,LOG_REFERENCE);
    
    FOR C_UPDATE IN (
      SELECT *
      FROM 
        XMLTable('for $i in /log/update return $i'
        PASSING p_LOG_XML
        COLUMNS 
          cod_Update   number  PATH '@update',
          data_Update  VARCHAR2(19) PATH '@data',
          descricao  VARCHAR2(200) PATH '@descricao',
          parametro  xmltype PATH '/parametro'
      )
    ) LOOP
      P_LOG(C_UPDATE.DESCRICAO,LOG_REFERENCE);
      P_IMPORT_PARAMETER( C_UPDATE.PARAMETRO,LOG_REFERENCE);
    END LOOP;
  END;
  
  PROCEDURE P_IMPORT_PARAMETER(p_PARAMETERS_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE) AS
  BEGIN
    
     FOR C_PARAMETER IN (
        SELECT *
        FROM 
          XMLTable('for $i in //parametro return $i'
          PASSING p_PARAMETERS_XML
          COLUMNS 
            nome  VARCHAR2(19)  PATH '@nome',
            valor xmltype PATH '/parametro',
            dataType NUMBER PATH '@dataType'
        )
      ) LOOP
        IF( C_PARAMETER.dataType=1) THEN
          P_ADD(C_PARAMETER.NOME,C_PARAMETER.VALOR.extract('/parametro/*'),LOG_REFERENCE);
        ELSIF( C_PARAMETER.dataType=2) THEN
          P_ADD(C_PARAMETER.NOME,C_PARAMETER.VALOR.extract('/parametro/text()').getnumberVal(),LOG_REFERENCE);
        ELSIF( C_PARAMETER.dataType=3) THEN
          P_ADD(C_PARAMETER.NOME,TO_DATE(C_PARAMETER.VALOR.extract('/parametro/text()').getstringval(),'yyyy-mm-dd"T"hh:mi:ss'),LOG_REFERENCE);
        ELSE
          P_ADD(C_PARAMETER.NOME,C_PARAMETER.VALOR.extract('/parametro/text()').getClobVal(),LOG_REFERENCE);
        END IF;
      END LOOP;
  END;
  
-- Setando variaveis estaticas do ambiente
BEGIN

 DECLARE
    T_PRIORIDADE_BANCO NUMBER;
 BEGIN
    select min(ID)
    INTO G_PRIORIDADE_BANCO
    from Tab_Prioridade
    WHERE  REGEXP_LIKE (UPPER(sys_context('userenv','instance_name')),UPPER('^'||DESCRICAO)||'\d*$','i')
    ;


  EXCEPTION WHEN OTHERS THEN
    select nvl(max(id),0)+1
    into T_PRIORIDADE_BANCO
    from  log_auditoria.TAB_PRIORIDADE;

    INSERT INTO LOG_AUDITORIA.TAB_PRIORIDADE(ID,DESCRICAO)
    VALUES(T_PRIORIDADE_BANCO,UPPER(sys_context('userenv','instance_name')))
    ;
    G_PRIORIDADE_BANCO:=T_PRIORIDADE_BANCO;
    DBMS_OUTPUT.PUT_LINE(G_PRIORIDADE_BANCO);
    
    P_LOG('INSERIU PRIORIDADE '|| G_PRIORIDADE_BANCO);
  END;



END PKG_LOG;
