--
create table audittrail (
  trans_id int,
  tablename text,
  reference text,
  formname text,
  action text,
  transdate timestamp default current_timestamp,
  employee_id int
);
create index audittrail_trans_id_key on audittrail (trans_id);
--
alter table defaults add audittrail bool;
alter table defaults alter audittrail set default '0';
--
update defaults set version = '2.3.8', audittrail = '0';
