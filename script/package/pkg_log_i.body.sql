create or replace PACKAGE BODY log_audit.PKG_LOG_I AS

  FUNCTION TO_XML(p_resource IN CLOB)
    RETURN XMLTYPE IS
    T_ENTRADA XMLTYPE;
    BEGIN
      IF (p_resource IS NOT NULL)
      THEN
        T_ENTRADA := XMLTYPE(p_resource);
      END IF;
      RETURN T_ENTRADA;
    END;

  procedure P_LOG(P_Mensagem IN VARCHAR2) AS
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem);
    END P_LOG;

  procedure P_LOG(P_Mensagem IN VARCHAR2, LOG_REFERENCE IN OUT CLOB) AS
    t_reference xmltype := to_xml(LOG_REFERENCE);
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END P_LOG;

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER) AS
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem, P_priority);
    END P_LOG;

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER, LOG_REFERENCE IN OUT CLOB) AS
    t_reference xmltype := to_xml(LOG_REFERENCE);
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem, P_priority, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END P_LOG;


  procedure P_LOG(P_Mensagem IN VARCHAR2, P_CONTEXT IN Varchar2) AS
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem, P_CONTEXT);
    END P_LOG;

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_CONTEXT IN Varchar2, LOG_REFERENCE IN OUT CLOB) AS
    t_reference xmltype := to_xml(LOG_REFERENCE);
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem, P_CONTEXT, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END P_LOG;


  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER, P_CONTEXT IN Varchar2) AS
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem, P_priority, P_CONTEXT);
    END P_LOG;

  procedure P_LOG(P_Mensagem IN VARCHAR2, P_priority IN NUMBER, P_CONTEXT IN Varchar2, LOG_REFERENCE IN OUT CLOB) AS
    t_reference xmltype := to_xml(LOG_REFERENCE);
    BEGIN
      LOG_AUDIT.pkg_log.P_LOG(p_Mensagem, P_priority, P_CONTEXT, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END P_LOG;


  procedure P_ADD_clob(p_Name IN VARCHAR2, p_Value IN CLOB, LOG_REFERENCE in OUT clob) as
    t_reference xmltype := to_xml(LOG_REFERENCE);
    BEGIN
      LOG_AUDIT.pkg_log.P_add(p_Name, p_Value, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END;

  procedure P_ADD_xml(p_Name IN VARCHAR2, p_Value IN clob, LOG_REFERENCE in OUT clob) as
    t_reference xmltype := to_xml(LOG_REFERENCE);
    t_value     xmltype := to_xml(p_Value);
    BEGIN
      LOG_AUDIT.pkg_log.P_add(p_Name, t_value, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END;

  procedure P_ADD_date(p_Name IN VARCHAR2, p_Value IN DATE, LOG_REFERENCE in OUT clob) as
    t_reference xmltype := to_xml(LOG_REFERENCE);
    BEGIN
      LOG_AUDIT.pkg_log.P_add(p_Name, p_Value, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END;

  procedure P_ADD_number(p_Name IN VARCHAR2, p_Value IN NUMBER, LOG_REFERENCE in OUT clob) as
    t_reference xmltype := to_xml(LOG_REFERENCE);
    BEGIN
      LOG_AUDIT.pkg_log.P_add(p_Name, p_Value, t_reference);
      if (t_reference is not null)
      then
        LOG_REFERENCE := t_reference.getClobVal();
      end if;
    END;

END;