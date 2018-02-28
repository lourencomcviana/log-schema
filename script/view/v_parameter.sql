CREATE OR REPLACE VIEW LOG_AUDIT.V_parameter AS
SELECT  p.data_log ,p.SEQ ,p.cod_update  ,p.NAME ,
  case
    when px.SEQ is not null then 1
    when pn.SEQ is not null then 2
    when pd.SEQ is not null then 3
    when pc.SEQ is not null then 4
  else null end as especialization,
  case
    when px.SEQ is not null then px.param_value.getClobVal()
    when pn.SEQ is not null then TO_CLOB(pn.param_value)
    when pd.SEQ is not null then to_clob(TO_char(pd.param_value,'yyyy-mm-dd"T"hh:mi:ss' ))
    when pc.SEQ is not null then pc.param_value
  else null end as param_value
  
FROM LOG_AUDIT.t_Parameter p
  left join LOG_AUDIT.t_Parameter_xml px on p.data_log=px.data_log and p.SEQ=px.SEQ and p.NAME=px.NAME and p.cod_update = px.cod_update
  left join LOG_AUDIT.t_Parameter_number pn  on p.data_log=pn.data_log and p.SEQ=pn.SEQ and p.NAME=pn.NAME and p.cod_update = pn.cod_update
  left join LOG_AUDIT.t_Parameter_date pd  on p.data_log=pd.data_log and p.SEQ=pd.SEQ and p.NAME=pd.NAME and p.cod_update = pd.cod_update
  left join LOG_AUDIT.t_Parameter_clob pc  on p.data_log=pc.data_log and p.SEQ=pc.SEQ and p.NAME=pc.NAME and p.cod_update = pc.cod_update
  ;