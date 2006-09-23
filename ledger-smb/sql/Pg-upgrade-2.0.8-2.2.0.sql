--
create unique index projectnumber_key on project (projectnumber);
create unique index partsgroup_key on partsgroup (partsgroup);
--
alter table ar add till varchar(20);
alter table ap add till varchar(20);
--
update defaults set version = '2.2.0';
--
