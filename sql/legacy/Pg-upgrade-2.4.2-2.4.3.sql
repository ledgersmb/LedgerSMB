--
alter table defaults rename invnumber to sinumber;
alter table defaults add vinumber text;
alter table defaults add employeenumber text;
alter table defaults add partnumber text;
alter table defaults add customernumber text;
alter table defaults add vendornumber text;
--
alter table employee add employeenumber varchar(32);
--
alter table customer add startdate date;
alter table customer add enddate date;
--
alter table vendor add startdate date;
alter table vendor add enddate date;
--
update defaults set version = '2.4.3';
