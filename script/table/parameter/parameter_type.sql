-- store all used contexts
create table t_context_node
(
  id_type NUMBER(10),
  table_name varchar2(30) not null,
  --context name
  NAME VARCHAR2(30) not null UNIQUE
);

alter table t_context_node constraint PK_CONTEXT_NODE primary key (ID_CONTEXT_NODE);

insert into t_context_node(id_type,table_name,name) values(1,'t_parameter_clob');
insert into t_context_node(id_type,table_name,name) values(2,'t_parameter_date');
insert into t_context_node(id_type,table_name,name) values(3,'t_parameter_type');
insert into t_context_node(id_type,table_name,name) values(4,'t_parameter_number');