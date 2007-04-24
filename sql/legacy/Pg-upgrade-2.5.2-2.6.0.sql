--
alter table oe add terms smallint;
alter table oe alter terms set default 0;
--
alter table ap alter terms set default 0;
--
delete from inventory where warehouse_id = 0;
--
update defaults set version = '2.6.0';
