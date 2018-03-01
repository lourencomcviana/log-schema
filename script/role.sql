CREATE ROLE logger;

grant execute on log_audit.PKG_log to logger;
grant execute on log_audit.PKG_util to logger;
grant select on log_audit.v_log to logger;
grant select on log_audit.v_log_recent to logger;
grant select on log_audit.v_parameter to logger;
grant select on log_audit.v_Context to logger;
grant select on log_audit.v_priority to logger;
grant select on log_audit.v_update to logger;

grant select on log_audit.t_priority to logger;
grant select on log_audit.t_log to logger;
grant select on log_audit.t_update to logger;
grant select on log_audit.t_context to logger;
grant select on log_audit.t_context_node to logger;
grant select on log_audit.t_parameter to logger;
grant select on log_audit.t_parameter_clob to logger;
grant select on log_audit.t_parameter_date to logger;
grant select on log_audit.t_parameter_xml to logger;
grant select on log_audit.t_parameter_number to logger;
