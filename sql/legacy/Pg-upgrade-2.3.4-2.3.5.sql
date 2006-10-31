--
create table temp (
  id int default nextval('id'),
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  discount float4,
  taxincluded bool default 'f',
  creditlimit float default 0,
  terms int2 default 0,
  customernumber varchar(32),
  cc text,
  bcc text,
  business_id int,
  taxnumber varchar(32),
  sic_code varchar(6),
  iban varchar(34),
  bic varchar(11),
  employee_id int
);
--
insert into temp (id,name,address1,city,country,state,contact,phone,fax,email,notes,discount,taxincluded,creditlimit,terms,customernumber,cc,bcc,business_id,taxnumber,sic_code,iban,bic,employee_id) select id,name,substr(addr1,1,32),substr(addr2,1,32),substr(addr3,1,32),substr(addr4,1,32),contact,phone,fax,email,notes,discount,taxincluded,creditlimit,terms,substr(customernumber,1,32),cc,bcc,business_id,substr(taxnumber,1,32),sic_code,iban,bic,employee_id from customer;
--
drop table customer;
alter table temp rename to customer;
--
create index customer_id_key on customer (id);
create index customer_customernumber_key on customer (customernumber);
create index customer_name_key on customer (name);
create index customer_contact_key on customer (contact);
--
create trigger del_customer after delete on customer for each row execute procedure del_customer();
-- end trigger
--
create table temp (
  id int default nextval('id'),
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  contact varchar(64),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  terms int2 default 0,
  taxincluded bool default 'f',
  vendornumber varchar(32),
  cc text,
  bcc text,
  gifi_accno varchar(30),
  business_id int,
  taxnumber varchar(32),
  sic_code varchar(6),
  discount float4,
  creditlimit float default 0,
  iban varchar(34),
  bic varchar(11),
  employee_id int
);
--
insert into temp (id,name,address1,city,country,state,contact,phone,fax,email,notes,terms,taxincluded,vendornumber,cc,bcc,gifi_accno,business_id,taxnumber,sic_code,discount,creditlimit,iban,bic,employee_id) select id,name,substr(addr1,1,32),substr(addr2,1,32),substr(addr3,1,32),substr(addr4,1,32),contact,phone,fax,email,notes,terms,taxincluded,substr(vendornumber,1,32),cc,bcc,gifi_accno,business_id,substr(taxnumber,1,32),sic_code,discount,creditlimit,iban,bic,employee_id from vendor;
--
drop table vendor;
alter table temp rename to vendor;
--
create index vendor_id_key on vendor (id);
create index vendor_name_key on vendor (name);
create index vendor_vendornumber_key on vendor (vendornumber);
create index vendor_contact_key on vendor (contact);
--
create trigger del_vendor after delete on vendor for each row execute procedure del_vendor();
-- end trigger
--
create table temp (
  trans_id int,
  shiptoname varchar(64),
  shiptoaddress1 varchar(32),
  shiptoaddress2 varchar(32),
  shiptocity varchar(32),
  shiptostate varchar(32),
  shiptozipcode varchar(10),
  shiptocountry varchar(32),
  shiptocontact varchar(64),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);
--
insert into temp (trans_id,shiptoname,shiptoaddress1,shiptocity,shiptocountry,shiptostate,shiptocontact,shiptophone,shiptofax,shiptoemail) select trans_id,shiptoname,substr(shiptoaddr1,1,32),substr(shiptoaddr2,1,32),substr(shiptoaddr3,1,32),substr(shiptoaddr4,1,32),shiptocontact,shiptophone,shiptofax,shiptoemail from shipto;
--
drop table shipto;
alter table temp rename to shipto;
create index shipto_trans_id_key on shipto (trans_id);
--
create table temp (
  id int default nextval('id'),
  login text,
  name varchar(64),
  address1 varchar(32),
  address2 varchar(32),
  city varchar(32),
  state varchar(32),
  zipcode varchar(10),
  country varchar(32),
  workphone varchar(20),
  homephone varchar(20),
  startdate date default current_date,
  enddate date,
  notes text,
  role varchar(20),
  sales bool default 'f',
  email text,
  sin varchar(20),
  iban varchar(34),
  bic varchar(11),
  managerid int
);
--
insert into temp (id,login,name,address1,city,country,state,workphone,homephone,startdate,enddate,notes,role,sales,email,sin,iban,bic,managerid) select id,login,name,substr(addr1,1,32),substr(addr2,1,32),substr(addr3,1,32),substr(addr4,1,32),workphone,homephone,startdate,enddate,notes,role,sales,email,sin,iban,bic,managerid from employee;
--
drop table employee;
alter table temp rename to employee;
--
create index employee_id_key on employee (id);
create unique index employee_login_key on employee (login);
create index employee_name_key on employee (name);
--
update defaults set version = '2.3.5';

