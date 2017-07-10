--TABELA QUE REPREsenta o cabecalho do log
create table t_log
(
  --initial date
  DATA_LOG    TIMESTAMP(6) default systimestamp not null,
  --security sequence
  SEQ         NUMBER(3) not null, 
  --log context
  ID_CONTEXT  NUMBER(10) NOT NULL,
  --defines where your log can or can't run
  priority_level NUMBER(6) not null
);

ALTER TABLE t_log ADD CONSTRAINT PK_LOG PRIMARY KEY(DATA_LOG, SEQ);

ALTER TABLE t_log ADD  CONSTRAINT FK_priority FOREIGN KEY (priority_level)
  REFERENCES t_priority (priority_level);

ALTER TABLE t_log ADD  CONSTRAINT FK_CONTEXT FOREIGN KEY (ID_CONTEXT)
  REFERENCES T_CONTEXT (ID_CONTEXT);