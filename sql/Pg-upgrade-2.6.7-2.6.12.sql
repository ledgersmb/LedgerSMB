--
alter table tax add validto date;
--
update defaults set version = '2.6.12';
