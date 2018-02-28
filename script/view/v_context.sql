CREATE OR REPLACE VIEW LOG_AUDIT.V_CONTEXT AS
SELECT cr.id_context,cr.id_context_father,cr.CONTEXT,default_priority_level,
     level as node_level,
     RPAD(' ', (level-1)*2, '  ') || cr.CONTEXT AS tree,
     CONNECT_BY_ROOT cr.id_context AS root,
     LTRIM(SYS_CONNECT_BY_PATH(cr.id_context, '-'), '-') AS path,
     LTRIM(SYS_CONNECT_BY_PATH(Cr.CONTEXT, '.'), '.') AS PATH_CONTEXT,
     CONNECT_BY_ISLEAF AS leaf

FROM LOG_AUDIT.t_context cr
START WITH cr.id_context_father is null
CONNECT BY cr.id_context_father = PRIOR cr.id_context
ORDER SIBLINGS BY cr.id_context_father;
