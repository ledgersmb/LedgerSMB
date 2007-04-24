alter table acc_trans rename column accno to chart_id;
update acc_trans set chart_id =
  (select id from chart where accno = acc_trans.chart_id);
--
alter table parts rename column inventory_accno to inventory_accno_id;
alter table parts rename column income_accno to income_accno_id;
alter table parts rename column expense_accno to expense_accno_id;
alter table parts rename column number to partnumber;
update parts set inventory_accno_id =
  (select id from chart where chart.accno = parts.inventory_accno_id);
update parts set income_accno_id =
  (select id from chart where chart.accno = parts.income_accno_id);
update parts set expense_accno_id =
  (select id from chart where chart.accno = parts.expense_accno_id);
--
create table assembly (id int, parts_id int, qty float);
--
alter table defaults rename column inventory_accno to inventory_accno_id;
alter table defaults rename column income_accno to income_accno_id;
alter table defaults rename column expense_accno to expense_accno_id;
alter table defaults add column businessnumber text;
alter table defaults add column version varchar(8);
update defaults set inventory_accno_id =
  (select id from chart where chart.accno = defaults.inventory_accno_id);
update defaults set income_accno_id =
  (select id from chart where chart.accno = defaults.income_accno_id);
update defaults set expense_accno_id =
  (select id from chart where chart.accno = defaults.expense_accno_id);
update defaults set version = '1.6.0';
--
alter table invoice rename column inventory_accno to inventory_accno_id;
alter table invoice rename column income_accno to income_accno_id;
alter table invoice rename column expense_accno to expense_accno_id;
alter table invoice rename column number to partnumber;
alter table invoice add column assemblyitem bool;
update invoice set assemblyitem = 'f';
update invoice set inventory_accno_id =
  (select id from chart where invoice.inventory_accno_id = chart.accno);
update invoice set income_accno_id =
  (select id from chart where invoice.income_accno_id = chart.accno);
update invoice set expense_accno_id =
  (select id from chart where invoice.expense_accno_id = chart.accno);
--
alter table gl rename column comment to description;
--
create table newvendor (
  id int default nextval ( 'id' ),
  name varchar(35),
  addr1 varchar(35),
  addr2 varchar(35),
  addr3 varchar(35),
  addr4 varchar(35),
  contact varchar(35),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  terms int2,
  taxincluded bool
);
insert into newvendor (
  id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, terms,
  taxincluded)
  select
  id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, terms,
  taxincluded from vendor;
drop table vendor;
alter table newvendor rename to vendor;
--
create table newcustomer (
  id int default nextval ( 'id' ),
  name varchar(35),
  addr1 varchar(35),
  addr2 varchar(35),
  addr3 varchar(35),
  addr4 varchar(35),
  contact varchar(35),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  discount float4,
  taxincluded bool,
  creditlimit float,
  terms int2,
  shiptoname varchar(35),
  shiptoaddr1 varchar(35),
  shiptoaddr2 varchar(35),
  shiptoaddr3 varchar(35),
  shiptoaddr4 varchar(35),
  shiptocontact varchar(20),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);
insert into newcustomer (
  id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, discount,
  taxincluded, creditlimit, terms, shiptoname, shiptoaddr1, shiptoaddr2,
  shiptoaddr3, shiptocontact, shiptophone, shiptofax, shiptoemail
  )
  select
  id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, discount,
  taxincluded, creditlimit, terms, shiptoname, shiptoaddr1, shiptoaddr2,
  shiptoaddr3, shiptocontact, shiptophone, shiptofax, shiptoemail
  from customer;
drop table customer;
alter table newcustomer rename to customer;
--
drop index chart_accno_key;
alter table chart rename to oldchart;
create table chart (
  id int default nextval('id'),
  accno int unique,
  description text,
  charttype char(1),
  gifi int,
  category char(1),
  link text
);
insert into chart (id, accno, description, charttype, gifi, category, link)
  select id, accno, description, type, gifi, category, link from oldchart;
drop table oldchart;
--
alter table tax rename column number to taxnumber;
--
-- apply
