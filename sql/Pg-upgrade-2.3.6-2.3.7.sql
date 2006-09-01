--
alter table partscustomer add curr char(3);
alter table customer add curr char(3);
alter table vendor add curr char(3);
--
update defaults set version = '2.3.7';
