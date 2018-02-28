CREATE OR REPLACE VIEW LOG_AUDIT.V_LOG AS
select l.DATA_log ,
       L.SEQ,
       l.priority_level,

       lu.cod_update ,
       lu.data_update,
       lu.description as description_update,
      XMLELEMENT
      (
        "log",xmlattributes(to_char( l.data_log,'YYYY-MM-DD"T"hh24:mi:ss.ff6') as "data",  l.seq as "seq"),
        (
            SELECT xmlAgg
            (
               XMLELEMENT
               ("update",xmlattributes( lu.cod_update "update",to_char(lu.data_UPDATE,'yyyy-mm-dd"T"hh:mi:ss') as "data", lu.description as "description"),
                  (
                     SELECT xmlAgg(
                         case lp.especialization
                         when 1  then XMLELEMENT("parameter",xmlattributes( lp.name as "name", lp.especialization AS "dataType"),xmltype(lp.param_Value) )
                         else XMLELEMENT("parameter",xmlattributes( lp.name as "name", lp.especialization AS "dataType"), lp.param_Value)
                         end
                     )
                     FROM LOG_AUDIT.v_parameter lp
                     where lp.data_log=l.data_log and lp.seq=l.seq and lp.cod_update=lu.cod_update
                  )
               )
            )
            FROM LOG_AUDIT.t_update lu
            where lu.data_log=l.data_log and lu.seq=l.seq
        )
      )as log,
      C.PATH_CONTEXT,
      C.id_context ,
      C.id_context_father

from LOG_AUDIT.t_log l
      join LOG_AUDIT.t_UPDATE lu on lu.data_log=l.data_log and lu.seq=l.seq and lu.cod_update=
     ( select max(tlu.cod_update) as last_update from  LOG_AUDIT.t_update tlu where tlu.data_log=l.data_log and tlu.seq=l.seq )
     join LOG_AUDIT.t_priority p on l.priority_level=p.priority_level
     LEFT JOIN LOG_AUDIT.V_CONTEXT C ON C.id_context=L.ID_CONTEXT;
