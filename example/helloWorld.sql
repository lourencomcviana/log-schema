declare 
  t_log_ref xmltype;
  t_err_test xmltype;
  
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
  

  LOG_AUDIT.pkg_log.p_log('we will force a exception now...',1,'TEST.DIVIDE',t_err_test);
  LOG_AUDIT.pkg_log.p_log('there is a special p_log_err procedure that make it easyer to log errors. If you don`t like it you can simple use p_log to log anything',t_err_test);
  LOG_AUDIT.pkg_log.p_log('Error logs are automatically set to max priority. We don`t want to miss these',t_err_test);
  LOG_AUDIT.pkg_log.p_log('passing a reference as the third parameter will save the details of what this reference was logging at the time of the error. Even if the t_err_test priprity is lower tham where you are running it',t_err_test);
  LOG_AUDIT.pkg_log.p_log('a fourth reference can ba passed, in that case it will be a refence for the error log itself',t_err_test);
  

  LOG_AUDIT.pkg_log.p_log('lets divide stuff by 0!!!!!'||(1/0),t_err_test);

  exception
  when others then
    declare
      t_err_test_internal xmltype;
    begin
      LOG_AUDIT.pkg_log.p_log_err('wops! Error here...','TEST.DIVIDE.ERROR',t_err_test,t_err_test_internal);
      LOG_AUDIT.pkg_log.p_log('you can add new updates normally to this log using its own reference',t_err_test_internal);
      LOG_AUDIT.pkg_log.p_add('param','and even parameters!',t_err_test_internal);
    
    end;

end;

declare 
  t_log_ref xmltype;
  
begin
  LOG_AUDIT.pkg_log.p_log('THIS IS A SUPER LOW PRIORITY LOG',99,'TEST.LOW.PRIORITY',t_log_ref);
  LOG_AUDIT.pkg_log.p_log('it will not be saved anywhere in the dabase',t_log_ref);
  LOG_AUDIT.pkg_log.p_log('it will log just in its own xml reference',t_log_ref);
  LOG_AUDIT.pkg_log.p_log('if you pass one',t_log_ref);
  LOG_AUDIT.pkg_log.p_log('note that at the top of that log is a attribute called ignore="1"',t_log_ref);
  LOG_AUDIT.pkg_log.p_log('if you change it to 0 (not recommended) the log will try yo save itself. In theory. Don`t do that',t_log_ref);
  dbms_output.put_line(LOG_AUDIT.pkg_util.f_xml_beautify(t_log_ref));
end;

/
select * from log_audit.V_LOG;
SELECT * FROM LOG_AUDIT.V_PARAMETER;
select * from LOG_AUDIT.V_CONTEXT;
select * from LOG_AUDIT.t_PRIORITY;

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
  

   