-- store all used contexts
create table t_context_node
(
  ID_CONTEXT_NODE NUMBER(10),
  --context name
  NAME VARCHAR2(30) not null UNIQUE
);

alter table t_context_node constraint PK_CONTEXT_NODE primary key (ID_CONTEXT_NODE);
