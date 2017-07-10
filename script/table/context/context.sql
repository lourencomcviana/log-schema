create table T_CONTEXT
(
  id_context             NUMBER(10) not null,
  id_context_father      NUMBER(10),
  ID_CONTEXT_NODE        VARCHAR2(30) not null,
  default_priority_level NUMBER(6)
);

alter table T_CONTEXT constraint PK_CONTEXT primary key (id_context);

alter table T_CONTEXT constraint FK_CONTEXT_NAME foreign key (name)
  REFERENCES T_context_name (name);

alter table T_CONTEXT constraint FK_CONTEXT_id_context foreign key (id_context_father)
  REFERENCES T_CONTEXT (id_context);

alter table T_CONTEXT constraint FK_PRIORITY_priority_level foreign key (default_priority_level)
  REFERENCES t_priority (priority_level);