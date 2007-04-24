--
create table partsvendor (vendor_id int, parts_id int, partnumber text, leadtime int2, lastcost float, curr char(3));
create index partsvendor_vendor_id_key on partsvendor (vendor_id);
create index partsvendor_parts_id_key on partsvendor (parts_id);
--
alter table assembly add column adj bool;
update assembly set adj = 't';
--
update defaults set version = '2.3.3';
