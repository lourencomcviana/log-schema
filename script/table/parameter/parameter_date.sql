-- Create table
create table LOG_AUDIT.T_PARAMETER_DATE
(
  data_log   TIMESTAMP(6) not null,
  seq        NUMBER(3) not null,
  cod_update NUMBER(10) not null,
  name       VARCHAR2(40) not null,
  param_value      DATE not null
);

alter table LOG_AUDIT.T_PARAMETER_DATE
  add constraint PK_PARAMETER_DATE primary key (DATA_LOG, SEQ, COD_UPDATE, NAME)
  ;

alter table LOG_AUDIT.T_PARAMETER_DATE
  add constraint FK_PARAMETER_date foreign key (DATA_LOG, SEQ, COD_UPDATE, NAME)
  references LOG_AUDIT.T_PARAMETER (DATA_LOG, SEQ, COD_UPDATE, NAME);
