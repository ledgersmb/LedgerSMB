--
alter table chart add column gifi_accno text;
--
create table gifi (accno text, description text);
create unique index gifi_accno_key on gifi (accno);
--
create table mtemp (parts_id int, name text);
insert into mtemp select parts_id, name from makemodel;
drop table makemodel;
alter table mtemp rename to makemodel;
--
alter table defaults add column closedto date;
alter table defaults add column revtrans bool;
--
alter table ap add column notes text;
--
alter table customer add column businessnumber text;
alter table vendor add column businessnumber text;
--
update defaults set version = '1.8.4', revtrans = 'f';
--
