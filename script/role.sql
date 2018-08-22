-- Interface para ser usada por aplicações
grant execute on log_audit.PKG_log_i to youruser;

-- Permissões para utilziar o pkg_log dentro da base de dados
grant execute on log_audit.PKG_log to youruser;
grant execute on log_audit.PKG_log_i to youruser;
grant execute on log_audit.PKG_util to youruser;
grant select on log_audit.v_log to youruser;
grant select on log_audit.v_log_recent to youruser;
grant select on log_audit.v_parameter to youruser;
grant select on log_audit.v_Context to youruser;
grant select on log_audit.v_priority to youruser;
grant select on log_audit.v_update to youruser;

grant select on log_audit.t_priority to youruser;
grant select on log_audit.t_log to youruser;
grant select on log_audit.t_update to youruser;
grant select on log_audit.t_context to youruser;
grant select on log_audit.t_context_node to youruser;
grant select on log_audit.t_parameter to youruser;
grant select on log_audit.t_parameter_clob to youruser;
grant select on log_audit.t_parameter_date to youruser;
grant select on log_audit.t_parameter_xml to youruser;
grant select on log_audit.t_parameter_number to youruser;

