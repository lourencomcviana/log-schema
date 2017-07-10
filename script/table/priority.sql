CREATE TABLE t_priority(
  priority_level NUMBER(6),
  database VARCHAR2(30) not null unique,
  description VARCHAR2(120)
);

ALTER TABLE t_priority ADD CONSTRAINT PK_LOG PRIMARY KEY(priority_level);