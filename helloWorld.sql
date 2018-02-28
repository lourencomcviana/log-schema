declare 
  t_log_ref xmltype;
begin
  --delete log_audit.t_temp;
  LOG_AUDIT.pkg_log.p_log('most simpler log');
  
  LOG_AUDIT.pkg_log.p_log('categorizing a log by its context','TEST.CONTEXT');

  LOG_AUDIT.pkg_log.p_log('number 1 is the priority of the log, it will only run on servers with a priority level smaller than itself',1,'TEST.CONTEXT');

  LOG_AUDIT.pkg_log.p_log('this one is a complex log. It has a reference that can be used to make new interactions','TEST.CONTEXT.REFENCE',T_LOG_REF);
  LOG_AUDIT.pkg_log.p_log('in a complex log, we can add new interactions, like this one',T_LOG_REF);
  LOG_AUDIT.pkg_log.p_log('or we can add parameters, of 4 types (clob,date,number,xml)',T_LOG_REF);
  LOG_AUDIT.pkg_log.p_add('CLOB','ANY STRING IS SAVED AS CLOB PARAMETER',T_LOG_REF);
  LOG_AUDIT.pkg_log.p_add('DATE',SYSDATE,T_LOG_REF);
  LOG_AUDIT.pkg_log.p_add('NUMBER',12,T_LOG_REF);
  LOG_AUDIT.pkg_log.p_add('XML',xmltype('<tag>onde xml</tag>'),T_LOG_REF);
  LOG_AUDIT.pkg_log.p_log('T_LOG_REF is the object where all information needed to make new interections is stored',T_LOG_REF);
 
  LOG_AUDIT.pkg_log.p_add('BasicReference',LOG_AUDIT.pkg_log.F_METADATA_BASIC(T_LOG_REF),T_LOG_REF);
  LOG_AUDIT.pkg_log.p_log('if you do `dbms_output.put_line(T_LOG_REF.getClobVal());` you will get the same xml of view log_audit.V_LOG',T_LOG_REF);
  
  LOG_AUDIT.pkg_log.p_log('Note that in the news p_log of the same reference we do not need to pass context or priority. The first context and priority are aways used',T_LOG_REF);
  LOG_AUDIT.pkg_log.p_log('look at xml content of log_audit.v_log or join tab_log with tab_update to see all updates from a log',T_LOG_REF);


  
end;

/
select * from log_audit.V_LOG_RECENT;
SELECT * FROM LOG_AUDIT.V_PARAMETER;
select * from LOG_AUDIT.T_CONTEXT_NODE;
select * from LOG_AUDIT.T_CONTEXT;

/*
- you can delete theses tests the code bellow 
- Recomend to remove all delete permisions from real users. Logs arent made to be deletede by anyone!

DELETE LOG_AUDIT.T_PARAMETER_CLOB;
DELETE LOG_AUDIT.T_PARAMETER_DATE;
DELETE LOG_AUDIT.T_PARAMETER_NUMBER;
DELETE LOG_AUDIT.T_PARAMETER_XML;
DELETE LOG_AUDIT.T_PARAMETER;
DELETE LOG_AUDIT.T_UPDATE;
DELETE LOG_AUDIT.T_LOG;

DELETE LOG_AUDIT.T_CONTEXT;
DELETE LOG_AUDIT.T_CONTEXT_NODE;
*/