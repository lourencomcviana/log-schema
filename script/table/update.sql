create table LOG_AUDIT.T_UPDATE
(
  data_log    TIMESTAMP(6) not null,
  seq         NUMBER(3) not null,
  cod_update  NUMBER(10) not null,
  data_update DATE default sysdate not null,
  description VARCHAR2(200) not null,
   constraint PK_UPDATE primary key (DATA_LOG, SEQ, COD_UPDATE),
   constraint FK_T_UPDATE foreign key (DATA_LOG, SEQ)
  references LOG_AUDIT.T_LOG (DATA_LOG, SEQ)
);