--
alter table customer rename column businessnumber to customernumber;
create index customer_customernumber_key on customer (customernumber);
alter table vendor rename column businessnumber to vendornumber;
create index vendor_vendornumber_key on vendor (vendornumber);
--
CREATE TABLE employee (
  id int DEFAULT nextval ('id'),
  login text,
  name varchar(35),
  addr1 varchar(35),
  addr2 varchar(35),
  addr3 varchar(35),
  addr4 varchar(35),
  workphone varchar(20),
  homephone varchar(20),
  startdate date default current_date,
  enddate date,
  notes text
);
--
create index employee_id_key on employee (id);
create unique index employee_login_key on employee (login);
create index employee_name_key on employee (name);
--
alter table gl add column employee_id int;
create index gl_employee_id_key on gl (employee_id);
alter table ar add column employee_id int;
create index ar_employee_id_key on ar (employee_id);
alter table ap add column employee_id int;
create index ap_employee_id_key on ap (employee_id);
alter table oe add column employee_id int;
create index oe_employee_id_key on oe (employee_id);
--
alter table invoice add column unit varchar(5);
alter table orderitems add column unit varchar(5);
--
update chart set gifi_accno = '' where gifi_accno = NULL;
alter table chart rename to chartold;
CREATE TABLE chart (
  id int DEFAULT nextval ('id'),
  accno text NOT NULL,
  description text,
  charttype char(1) DEFAULT 'A',
  category char(1),
  link text,
  gifi_accno text
);
insert into chart (id, accno, description, charttype, category, link, gifi_accno) select id, accno, description, charttype, category, link, gifi_accno from chartold;
drop table chartold;
create index chart_id_key on chart (id);
create unique index chart_accno_key on chart (accno);
create index chart_category_key on chart (category);
create index chart_link_key on chart (link);
create index chart_gifi_accno_key on chart (gifi_accno);
--
alter table parts alter column inventory_accno_id drop default;
--
alter table defaults rename ordnumber to sonumber;
alter table defaults add column ponumber text;
--
update defaults set version = '1.8.5', ponumber = sonumber;
--
