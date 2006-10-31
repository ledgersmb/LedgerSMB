--
create table partsgroup (id int default nextval('id'), partsgroup text);
create index partsgroup_id_key on partsgroup (id);
-- 
alter table parts add partsgroup_id int;
--
alter table assembly add bom bool;
update assembly set bom = '0' where assembly.id = parts.id and parts.bom = '0';
update assembly set bom = '1' where assembly.id = parts.id and parts.bom = '1';
--
update defaults set version = '2.0.8';
--
