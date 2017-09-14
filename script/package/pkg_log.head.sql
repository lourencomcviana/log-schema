CREATE OR REPLACE PACKAGE LOG_AUDITORIA.PKG_LOG IS

  type r_logkey_recordtype is record(
      data_log   LOG_AUDITORIA.TAB_LOG.DATA_LOG%type,
      seq        LOG_AUDITORIA.TAB_LOG.SEQ%type,
      ignorar    number(1)
  );
  type t_logkey_recordtype is table of r_logkey_recordtype;
  
  type r_contextotree_recordtype is record(
  
       id_relacao LOG_AUDITORIA.TAB_CONTEXTO_RELACAO.ID_RELACAO%TYPE,
       id_relacao_pai LOG_AUDITORIA.TAB_CONTEXTO_RELACAO.ID_RELACAO_PAI%TYPE,
       ID_CONTEXTO LOG_AUDITORIA.TAB_CONTEXTO.ID%TYPE,
       CONTEXTO LOG_AUDITORIA.TAB_CONTEXTO.CONTEXTO%TYPE,
       ID_PRIORIDADE_DEFAULT LOG_AUDITORIA.TAB_PRIORIDADE.ID%TYPE,
       nivel NUMBER(20),
       tree VARCHAR2(500),
       root NUMBER(20),
       path VARCHAR2(4000),
       PATH_CONTEXTO CLOB,
       leaf NUMBER(1)
     
  );
  type t_contextotree_recordtype is table of r_contextotree_recordtype;
    
  FUNCTION F_TO_LOG_DATA(p_data_str in varchar2) return timestamp;
  
  --extrair metadados de um xml de referencia
  FUNCTION F_METADATA_EXTRACT(p_xml in xmltype)  return t_logkey_recordtype pipelined;
  --converte o xml de referencia para somente o basico
  FUNCTION F_METADATA_BASIC(p_xml in XMLTYPE) return XMLTYPE;
  FUNCTION F_CONTEXTO_LEAF(p_ID_RELACAO NUMBER) return t_contextotree_recordtype pipelined;
  
  FUNCTION F_XML_LAST_UPDATE(p_xml in XMLTYPE) return XMLTYPE;
  FUNCTION F_XML_LAST_UPDATES(p_number_updates number:=0,p_xml in XMLTYPE) return xmltype;
  
  procedure P_LOG(P_Mensagem IN VARCHAR2);
  procedure P_LOG(P_Mensagem IN VARCHAR2,  LOG_REFERENCE IN OUT XMLTYPE);

  procedure P_LOG(P_Mensagem IN VARCHAR2,P_Prioridade IN NUMBER);
  procedure P_LOG(P_Mensagem IN VARCHAR2,P_Prioridade IN NUMBER,  LOG_REFERENCE IN OUT XMLTYPE);

  procedure P_LOG(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2);
  procedure P_LOG(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE);

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_Prioridade IN NUMBER,P_Contexto IN Varchar2);
  procedure P_LOG(P_Mensagem IN VARCHAR2, P_Prioridade IN NUMBER,P_Contexto IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE);
  
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2);
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2);
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2,  PARENT_LOG_REFERENCE IN  xmltype);
  PROCEDURE P_LOG_ERRO(P_Mensagem IN VARCHAR2,P_Contexto IN Varchar2,  PARENT_LOG_REFERENCE IN  xmltype,ERR_LOG_REFERENCE IN OUT  xmltype);
    
  procedure P_ADD(p_Nome IN VARCHAR2, p_Valor IN VARCHAR2, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Nome IN VARCHAR2, p_Valor IN CLOB, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Nome IN VARCHAR2, p_Valor IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Nome IN VARCHAR2, p_Valor IN DATE, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Nome IN VARCHAR2, p_Valor IN NUMBER, LOG_REFERENCE in OUT XMLTYPE);
  --mantem um contexto
  procedure P_CONTEXTO( P_TEXT VARCHAR2, PO_ID_PRIORIDADE IN OUT NUMBER, O_ID_RELACAO OUT NUMBER);
  
  PROCEDURE P_IMPORT_LOG(p_Nome IN VARCHAR2,p_LOG_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE);
  PROCEDURE P_IMPORT_PARAMETER(p_PARAMETERS_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE);
END PKG_LOG;
