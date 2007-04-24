--
delete from status where formname = 'receipt';
delete from status where formname = 'check';
create table statu (trans_id int, formname text, printed bool default 'f', emailed bool default 'f', spoolfile text);
insert into statu select trans_id, formname, printed, emailed, spoolfile from status;
drop table status;
alter table statu rename to status;
create index status_trans_id_key on status (trans_id);
--
update defaults set version = '2.6.3';
