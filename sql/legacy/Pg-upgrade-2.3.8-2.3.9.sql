--
create table translation (
  trans_id int,
  language_code varchar(6),
  description text
);
create index translation_trans_id_key on translation (trans_id);
--
alter table ar add language_code varchar(6);
alter table ap add language_code varchar(6);
alter table oe add language_code varchar(6);
--
create unique index language_code_key on language (code);
--
update defaults set version = '2.3.9';
