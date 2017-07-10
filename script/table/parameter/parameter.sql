--PARAMETER HEADER
create table T_PARAMETER
(
  data_log   TIMESTAMP(6) not null,
  seq        NUMBER(3) not null,
  cod_update NUMBER(10) not null,
  name       VARCHAR2(40) not null,
  id_type    NUMBER(10) NOT NULL
);

alter table T_PARAMETER
  add constraint PK_PARAMETER primary key (DATA_LOG, SEQ, COD_UPDATE, NAME)
  ;

alter table T_PARAMETER
  add constraint FK_UPDATE foreign key (DATA_LOG, SEQ, COD_UPDATE)
  references T_UPDATE (DATA_LOG, SEQ, COD_UPDATE);

alter table T_PARAMETER
  add constraint FK_PARAMETER_TYPE foreign key (id_type)
  references T_PARAMETER_TYPE (id_type);