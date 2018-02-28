--TABELA QUE REPREsenta o cabecalho do log
create table LOG_AUDIT.T_log
(
  --initial date
  DATA_LOG    TIMESTAMP(6) default systimestamp not null,
  --security sequence
  SEQ         NUMBER(3) not null, 
  --log context
  ID_CONTEXT  NUMBER(10) ,
  --defines where your log can or can't run
  priority_level NUMBER(6) not null
);

ALTER TABLE LOG_AUDIT.T_log ADD CONSTRAINT PK_LOG PRIMARY KEY(DATA_LOG, SEQ);

ALTER TABLE LOG_AUDIT.T_log ADD  CONSTRAINT FK_priority FOREIGN KEY (priority_level)
  REFERENCES LOG_AUDIT.T_priority (priority_level);

ALTER TABLE LOG_AUDIT.T_log ADD  CONSTRAINT FK_CONTEXT FOREIGN KEY (ID_CONTEXT)
  REFERENCES LOG_AUDIT.T_CONTEXT (ID_CONTEXT);