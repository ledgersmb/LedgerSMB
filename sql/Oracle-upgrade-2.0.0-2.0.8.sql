--
create table partsgroup (id integer, partsgroup varchar2(100));
create index partsgroup_id_key on partsgroup (id);
--
alter table parts add (partsgroup_id integer);
--
alter table assembly add (bom char(1));
update assembly set bom = '0' where assembly.id = parts.id and parts.bom = '0';
update assembly set bom = '1' where assembly.id = parts.id and parts.bom = '1';
--
CREATE OR REPLACE TRIGGER partsgroupid BEFORE INSERT ON partsgroup FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--      
update defaults set version = '2.0.8';
--
