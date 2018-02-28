create table LOG_AUDIT.T_CONTEXT
(
  id_context             NUMBER(10) not null,
  id_context_father      NUMBER(10),
  CONTEXT               VARCHAR2(30) not null,
  default_priority_level NUMBER(6)
);

alter table LOG_AUDIT.T_CONTEXT ADD constraint PK_CONTEXT primary key (id_context);

alter table LOG_AUDIT.T_CONTEXT ADD constraint FK_CONTEXT_node foreign key (CONTEXT)
  REFERENCES LOG_AUDIT.T_context_node (CONTEXT);

alter table LOG_AUDIT.T_CONTEXT ADD constraint FK_CONTEXT_id_context foreign key (id_context_father)
  REFERENCES LOG_AUDIT.T_CONTEXT (id_context);

alter table LOG_AUDIT.T_CONTEXT ADD constraint FK_PRIORITY_priority_level foreign key (default_priority_level)
  REFERENCES LOG_AUDIT.T_priority (priority_level);