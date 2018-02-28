
CREATE OR REPLACE PACKAGE LOG_AUDIT.PKG_LOG IS

  type r_logkey_recordtype is record(
      data_log    LOG_AUDIT.t_LOG.DATA_LOG%type,
      seq         LOG_AUDIT.t_LOG.SEQ%type,
      ignore_this number(1)
  );
  type t_logkey_recordtype is table of r_logkey_recordtype;
  
  type r_CONTEXTtree_recordtype is record(
  
       id_CONTEXT LOG_AUDIT.T_CONTEXT.ID_CONTEXT%TYPE,
       ID_CONTEXT_FATHER LOG_AUDIT.T_CONTEXT.ID_CONTEXT_FATHER%TYPE,
       CONTEXT LOG_AUDIT.T_CONTEXT_NODE.CONTEXT%TYPE,
       default_priority_level LOG_AUDIT.T_CONTEXT.default_priority_level%TYPE,
       node_level NUMBER(20),
       tree VARCHAR2(500),
       root NUMBER(20),
       path VARCHAR2(4000),
       PATH_CONTEXT CLOB,
       leaf NUMBER(1)
     
  );
  type T_CONTEXT_NODEtree_recordtype is table of r_CONTEXTtree_recordtype;
    
  FUNCTION F_TO_LOG_DATA(p_data_str in varchar2) return timestamp;
  
  --extrair metadados de um xml de referencia
  FUNCTION F_METADATA_EXTRACT(p_xml in xmltype)  return t_logkey_recordtype pipelined;
  --converte o xml de referencia para somente o basico
  FUNCTION F_METADATA_BASIC(p_xml in XMLTYPE) return XMLTYPE;
  FUNCTION F_CONTEXT_LEAF(p_ID_CONTEXT NUMBER) return T_CONTEXT_NODEtree_recordtype pipelined;
  
  FUNCTION F_XML_LAST_UPDATE(p_xml in XMLTYPE) return XMLTYPE;
  FUNCTION F_XML_LAST_UPDATES(p_number_updates number:=0,p_xml in XMLTYPE) return xmltype;
  
  procedure P_LOG(P_Mensagem IN VARCHAR2);
  procedure P_LOG(P_Mensagem IN VARCHAR2,  LOG_REFERENCE IN OUT XMLTYPE);

  procedure P_LOG(P_Mensagem IN VARCHAR2,P_priority IN NUMBER);
  procedure P_LOG(P_Mensagem IN VARCHAR2,P_priority IN NUMBER,  LOG_REFERENCE IN OUT XMLTYPE);

  procedure P_LOG(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2);
  procedure P_LOG(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE);

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER,P_CONTEXT IN Varchar2);
  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER,P_CONTEXT IN Varchar2,  LOG_REFERENCE IN OUT XMLTYPE);
  
  PROCEDURE P_LOG_err(P_Mensagem IN VARCHAR2);
  PROCEDURE P_LOG_err(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2);
  PROCEDURE P_LOG_err(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2,  PARENT_LOG_REFERENCE IN  xmltype);
  PROCEDURE P_LOG_err(P_Mensagem IN VARCHAR2,P_CONTEXT IN Varchar2,  PARENT_LOG_REFERENCE IN  xmltype,ERR_LOG_REFERENCE IN OUT  xmltype);
    
  procedure P_ADD(p_Name IN VARCHAR2, p_Value IN VARCHAR2, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Name IN VARCHAR2, p_Value IN CLOB, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Name IN VARCHAR2, p_Value IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Name IN VARCHAR2, p_Value IN DATE, LOG_REFERENCE in OUT XMLTYPE);
  procedure P_ADD(p_Name IN VARCHAR2, p_Value IN NUMBER, LOG_REFERENCE in OUT XMLTYPE);
  --mantem um CONTEXT
  procedure P_CONTEXT( P_TEXT VARCHAR2, PO_ID_PRIORITY IN OUT NUMBER, O_ID_context OUT NUMBER);
  
  PROCEDURE P_IMPORT_LOG(p_Name IN VARCHAR2,p_LOG_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE);
  PROCEDURE P_IMPORT_PARAMETER(p_PARAMETERS_XML IN XMLTYPE, LOG_REFERENCE in OUT XMLTYPE);
END PKG_LOG;
