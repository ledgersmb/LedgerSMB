--
alter table employee add dob date;
alter table employee rename sin to ssn;
--
update defaults set version = '2.4.4';
