--
create table def (
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  fxgain_accno_id int,
  fxloss_accno_id int,
  invnumber text,
  ordnumber text,
  yearend varchar(5),
  weightunit varchar(5),
  businessnumber text,
  version varchar(8),
  curr text
);
insert into def (inventory_accno_id, income_accno_id, expense_accno_id, invnumber, ordnumber, yearend, weightunit, businessnumber, version, curr) select inventory_accno_id, income_accno_id, expense_accno_id, invnumber, ponumber, yearend, weightunit, businessnumber, version, nativecurr from defaults;
drop table defaults;
alter table def rename to defaults;
update defaults set version = '1.8.0';
--
-- create a default accno for exchange rate gain and loss
--
select accno into temp from chart where category = 'I' order by accno desc limit 1;
update temp set accno = accno + 1;
insert into chart (accno) select accno from temp;
update chart set description = 'Foreign Exchange Gain', category = 'I', charttype = 'A' where accno = (select accno from temp);
update defaults set fxgain_accno_id = (select id from chart where chart.accno = temp.accno);
drop table temp;
select accno into temp from chart where category = 'E' order by accno desc limit 1;
update temp set accno = accno + 1;
insert into chart (accno) select accno from temp;
update chart set description = 'Foreign Exchange Loss', category = 'E', charttype = 'A' where accno = (select accno from temp);
update defaults set fxloss_accno_id = (select id from chart where chart.accno = temp.accno);
drop table temp;
--
alter table parts add column bin text;
alter table parts alter column onhand set default 0;
update parts set onhand = 0 where onhand = NULL;
alter table parts add column obsolete bool;
alter table parts alter column obsolete set default 'f';
update parts set obsolete = 'f';
--
alter table ap rename column vendor to vendor_id;
alter table ap add column curr char(3);
--
alter table ar rename column customer to customer_id;
alter table ar add column curr char(3);
alter table ar add column ordnumber text;
--
alter table acc_trans add column source text;
alter table acc_trans add column cleared bool;
alter table acc_trans alter column cleared set default 'f';
alter table acc_trans add column fx_transaction bool;
alter table acc_trans alter column fx_transaction set default 'f';
update acc_trans set cleared = 'f', fx_transaction = 'f';
--
create table oe (
  id int default nextval('id'),
  ordnumber text,
  transdate date default current_date,
  vendor_id int,
  customer_id int,
  amount float8,
  netamount float8,
  reqdate date,
  taxincluded bool,
  shippingpoint text,
  notes text,
  curr char(3)
);
--
create table orderitems (
  trans_id int,
  parts_id int,
  description text,
  qty float4,
  sellprice float8,
  discount float4
);
--
alter table invoice rename to invoiceold;
create table invoice (
  id int default nextval('id'),
  trans_id int,
  parts_id int,
  description text,
  qty float4,
  allocated float4,
  sellprice float8,
  fxsellprice float8,
  discount float4,
  assemblyitem bool default 'f'
);
insert into invoice (id, trans_id, parts_id, description, qty, allocated, sellprice, fxsellprice, discount, assemblyitem) select id, trans_id, parts_id, description, qty, allocated, sellprice, sellprice, discount, assemblyitem from invoiceold;
update invoice set assemblyitem = 'f' where assemblyitem = NULL;
drop table invoiceold;
--
create table exchangerate (
  curr char(3),
  transdate date,
  buy float8,
  sell float8
);
--
