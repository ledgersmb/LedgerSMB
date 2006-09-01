--
alter table customer add (cc VARCHAR2(50));
alter table customer add (bcc VARCHAR2(50));
--
alter table vendor add (cc VARCHAR2(50));
alter table vendor add (bcc VARCHAR2(50));
--
create table shipto (
  trans_id integer,
  shiptoname varchar2(35),
  shiptoaddr1 varchar2(35),
  shiptoaddr2 varchar2(35),
  shiptoaddr3 varchar2(35),
  shiptoaddr4 varchar2(35),
  shiptocontact varchar2(35),
  shiptophone varchar2(20),
  shiptofax varchar2(20),
  shiptoemail VARCHAR2(50)
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
  id integer,
  name varchar2(35),
  addr1 varchar2(35),
  addr2 varchar2(35),
  addr3 varchar2(35),
  addr4 varchar2(35),
  contact varchar2(35),
  phone varchar2(20),
  fax varchar2(20),
  email VARCHAR2(50),
  notes RCHAR2(4000),
  discount float,
  taxincluded char(1),
  creditlimit float DEFAULT 0,
  terms integer DEFAULT 0,
  customernumber VARCHAR2(40),
  cc VARCHAR2(50),
  bcc VARCHAR2(50)
);
insert into custome (id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, customernumber) select id, name, addr1, addr2, addr3, addr4, contact, phone, fax, email, notes, discount, taxincluded, creditlimit, terms, customernumber from customer;
--
drop table customer;
alter table custome rename to customer;
create index customer_id_key on customer (id);
create index customer_name_key on customer (name);
create index customer_contact_key on customer (contact);
--
alter table parts add (bom char(1) default '0');
update parts set bom = '0';
update parts set bom = '1' where assembly = '1';
alter table parts add (image VARCHAR2(100));
alter table parts add (drawing VARCHAR2(100));
alter table parts add (microfiche VARCHAR2(100));
--
alter table gl add (notes VARCHAR2(4000));
--
alter table oe add (closed char(1) default '0');
update oe set closed = '0';
--
create table project (
  id integer,
  projectnumber VARCHAR2(50),
  description VARCHAR2(4000)
);
--
create index project_id_key on project (id);
--
alter table acc_trans add (project_id integer);
update acc_trans set cleared = '0' where cleared = '1';
--
alter table invoice add (project_id integer);
alter table invoice add (deliverydate date);
alter table orderitems add (project_id integer);
alter table orderitems add (reqdate date);
--
CREATE OR REPLACE TRIGGER projectid BEFORE INSERT ON project FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
alter table gl add (reference VARCHAR2(50));
update gl set reference = source;
alter table gl drop column source;
--
create index gl_reference_key on gl (reference);
create index acc_trans_source_key on acc_trans (source);
--
update defaults set version = '2.0.0';
--
