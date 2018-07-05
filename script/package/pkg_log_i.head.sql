create or replace PACKAGE log_audit.PKG_LOG_I AS

  procedure P_LOG(P_Mensagem IN VARCHAR2);
  procedure P_LOG(P_Mensagem IN VARCHAR2, LOG_REFERENCE IN OUT CLOB);

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER);
  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER, LOG_REFERENCE IN OUT CLOB);

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_CONTEXT IN Varchar2);
  procedure P_LOG(P_Mensagem IN VARCHAR2, P_CONTEXT IN Varchar2, LOG_REFERENCE IN OUT CLOB);

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER, P_CONTEXT IN Varchar2);
  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER, P_CONTEXT IN Varchar2, LOG_REFERENCE IN OUT CLOB);


  procedure P_ADD_clob(p_Name IN VARCHAR2, p_Value IN CLOB, LOG_REFERENCE in OUT clob);
  procedure P_ADD_xml(p_Name IN VARCHAR2, p_Value IN clob, LOG_REFERENCE in OUT clob);
  procedure P_ADD_date(p_Name IN VARCHAR2, p_Value IN DATE, LOG_REFERENCE in OUT clob);
  procedure P_ADD_number(p_Name IN VARCHAR2, p_Value IN NUMBER, LOG_REFERENCE in OUT clob);


END;
