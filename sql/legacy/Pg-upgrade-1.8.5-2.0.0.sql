--
alter table customer add column cc text;
alter table customer add column bcc text;
--
alter table vendor add column cc text;
alter table vendor add column bcc text;
--
create table shipto (
  trans_id int,
  shiptoname varchar(35),
  shiptoaddr1 varchar(35),
  shiptoaddr2 varchar(35),
  shiptoaddr3 varchar(35),
  shiptoaddr4 varchar(35),
  shiptocontact varchar(35),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);
--
insert into shipto (trans_id, shiptoname, shiptoaddr1, shiptoaddr2, shiptoaddr3, shiptoaddr4, shiptocontact, shiptophone, shiptofax, shiptoemail) select id, shiptoname, shiptoaddr1, shiptoaddr2, shiptoaddr3, shiptoaddr4, shiptocontact, shiptophone, shiptofax, shiptoemail from customer where shiptoname != '' or shiptoname is not null;
--
insert into shipto (trans_id, shiptoname, shiptoaddr1, shiptoaddr2, shiptoaddr3, shiptoaddr4, shiptocontact, shiptophone, shiptofax, shiptoemail) select distinct on (a.id) a.id, c.shiptoname, c.shiptoaddr1, c.shiptoaddr2, c.shiptoaddr3, c.shiptoaddr4, c.shiptocontact, c.shiptophone, c.shiptofax, c.shiptoemail from customer c, ar a where a.customer_id = c.id;
--
insert into shipto (trans_id, shiptoname, shiptoaddr1, shiptoaddr2, shiptoaddr3, shiptoaddr4, shiptocontact, shiptophone, shiptofax, shiptoemail) select distinct on (o.id) o.id, c.shiptoname, c.shiptoaddr1, c.shiptoaddr2, c.shiptoaddr3, c.shiptoaddr4, c.shiptocontact, c.shiptophone, c.shiptofax, c.shiptoemail from customer c, oe o where o.customer_id = c.id;
--
create index shipto_trans_id_key on shipto (trans_id);
--
create table custome (
  id int default nextval('id'),
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
  creditlimit float DEFAULT 0,
  terms int2 DEFAULT 0,
  customernumber text,
  cc text,
  bcc text
);
insert into custome (id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, customernumber) select id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, customernumber from customer;
--
drop table customer;
alter table custome rename to customer;
create index customer_id_key on customer (id);
create index customer_name_key on customer (name);
create index customer_contact_key on customer (contact);
--
alter table parts add column bom boolean;
alter table parts alter column bom set default 'f';
update parts set bom = 'f';
update parts set bom = 't' where assembly;
alter table parts add column image text;
alter table parts add column drawing text;
alter table parts add column microfiche text;
--
alter table gl add column notes text;
--
alter table oe add column closed bool;
alter table oe alter column closed set default 'f';
update oe set closed = 'f';
--
create table project (
  id int default nextval('id'),
  projectnumber text,
  description text
);
--
create index project_id_key on project (id);
--
alter table acc_trans add column project_id int;
update acc_trans set cleared = '0' where cleared = '1';
--
alter table invoice add column project_id int;
alter table invoice add column deliverydate date;
alter table orderitems add column project_id int;
alter table orderitems add column reqdate date;
--
alter table gl rename source to reference;
create index gl_reference_key on gl (reference);
create index acc_trans_source_key on acc_trans (lower(source));
--
update defaults set version = '2.0.0';
--
