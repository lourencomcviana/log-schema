--PARAMETER HEADER
create table LOG_AUDIT.T_PARAMETER
(
  data_log   TIMESTAMP(6) not null,
  seq        NUMBER(3) not null,
  cod_update NUMBER(10) not null,
  name       VARCHAR2(40) not null,
  constraint PK_PARAMETER primary key (DATA_LOG, SEQ, COD_UPDATE, NAME),
  constraint FK_UPDATE foreign key (DATA_LOG, SEQ, COD_UPDATE)
  references LOG_AUDIT.T_UPDATE (DATA_LOG, SEQ, COD_UPDATE)
);
