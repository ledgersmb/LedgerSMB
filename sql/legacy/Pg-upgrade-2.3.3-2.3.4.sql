--
alter table customer add employee_id int;
alter table vendor add employee_id int;
alter table employee add managerid int;
--
update defaults set version = '2.3.4';
