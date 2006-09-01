--
CREATE SEQUENCE id start 10000;
SELECT nextval ('id');
--
CREATE SEQUENCE invoiceid;
SELECT nextval ('invoiceid');
--
CREATE SEQUENCE orderitemsid;
SELECT nextval ('orderitemsid');
--
CREATE SEQUENCE jcitemsid;
SELECT nextval ('jcitemsid');
--
CREATE TABLE makemodel (
  parts_id int,
  make text,
  model text
);
--
CREATE TABLE gl (
  id int DEFAULT nextval ( 'id' ),
  reference text,
  description text,
  transdate date DEFAULT current_date,
  employee_id int,
  notes text,
  department_id int default 0
);
--
CREATE TABLE chart (
  id int DEFAULT nextval ( 'id' ),
  accno text NOT NULL,
  description text,
  charttype char(1) DEFAULT 'A',
  category char(1),
  link text,
  gifi_accno text,
  contra bool DEFAULT 'f'
);
--
CREATE TABLE gifi (
  accno text,
  description text
);
--
CREATE TABLE defaults (
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  fxgain_accno_id int,
  fxloss_accno_id int,
  sinumber text,
  sonumber text,
  yearend varchar(5),
  weightunit varchar(5),
  businessnumber text,
  version varchar(8),
  curr text,
  closedto date,
  revtrans bool DEFAULT 'f',
  ponumber text,
  sqnumber text,
  rfqnumber text,
  audittrail bool default 'f',
  vinumber text,
  employeenumber text,
  partnumber text,
  customernumber text,
  vendornumber text,
  glnumber text,
  projectnumber text
);
INSERT INTO defaults (version) VALUES ('2.6.12');
--
CREATE TABLE acc_trans (
  trans_id int,
  chart_id int NOT NULL,
  amount float,
  transdate date DEFAULT current_date,
  source text,
  cleared bool DEFAULT 'f',
  fx_transaction bool DEFAULT 'f',
  project_id int,
  memo text,
  invoice_id int
);
--
CREATE TABLE invoice (
  id int DEFAULT nextval ( 'invoiceid' ),
  trans_id int,
  parts_id int,
  description text,
  qty float4,
  allocated float4,
  sellprice float,
  fxsellprice float,
  discount float4,
  assemblyitem bool DEFAULT 'f',
  unit varchar(5),
  project_id int,
  deliverydate date,
  serialnumber text,
  notes text
);
--
CREATE TABLE customer (
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
  employee_id int,
  language_code varchar(6),
  pricegroup_id int,
  curr char(3),
  startdate date,
  enddate date
);
--
--
CREATE TABLE parts (
  id int DEFAULT nextval ( 'id' ),
  partnumber text,
  description text,
  unit varchar(5),
  listprice float,
  sellprice float,
  lastcost float,
  priceupdate date DEFAULT current_date,
  weight float4,
  onhand float4 DEFAULT 0,
  notes text,
  makemodel bool DEFAULT 'f',
  assembly bool DEFAULT 'f',
  alternate bool DEFAULT 'f',
  rop float4,
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  bin text,
  obsolete bool DEFAULT 'f',
  bom bool DEFAULT 'f',
  image text,
  drawing text,
  microfiche text,
  partsgroup_id int,
  project_id int,
  avgcost float
);
--
CREATE TABLE assembly (
  id int,
  parts_id int,
  qty float,
  bom bool,
  adj bool
) WITH OIDS;
--
CREATE TABLE ar (
  id int DEFAULT nextval ( 'id' ),
  invnumber text,
  transdate date DEFAULT current_date,
  customer_id int,
  taxincluded bool,
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  shippingpoint text,
  terms int2 DEFAULT 0,
  notes text,
  curr char(3),
  ordnumber text,
  employee_id int,
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text
);
--
CREATE TABLE ap (
  id int DEFAULT nextval ( 'id' ),
  invnumber text,
  transdate date DEFAULT current_date,
  vendor_id int,
  taxincluded bool DEFAULT 'f',
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT 'f',
  ordnumber text,
  curr char(3),
  notes text,
  employee_id int,
  till varchar(20),
  quonumber text,
  intnotes text,
  department_id int DEFAULT 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  shippingpoint text,
  terms int2 DEFAULT 0
);
--
CREATE TABLE partstax (
  parts_id int,
  chart_id int
);
--
CREATE TABLE tax (
  chart_id int,
  rate float,
  taxnumber text,
  validto date
);
--
CREATE TABLE customertax (
  customer_id int,
  chart_id int
);
--
CREATE TABLE vendortax (
  vendor_id int,
  chart_id int
);
--
CREATE TABLE oe (
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
  curr char(3),
  employee_id int,
  closed bool default 'f',
  quotation bool default 'f',
  quonumber text,
  intnotes text,
  department_id int default 0,
  shipvia text,
  language_code varchar(6),
  ponumber text,
  terms int2 DEFAULT 0
);
--
CREATE TABLE orderitems (
  id int default nextval('orderitemsid'),
  trans_id int,
  parts_id int,
  description text,
  qty float4,
  sellprice float8,
  discount float4,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship float4,
  serialnumber text,
  notes text
) WITH OIDS;
--
CREATE TABLE exchangerate (
  curr char(3),
  transdate date,
  buy float8,
  sell float8
);
--
create table employee (
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
  ssn varchar(20),
  iban varchar(34),
  bic varchar(11),
  managerid int,
  employeenumber varchar(32),
  dob date
);
--
create table shipto (
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
CREATE TABLE vendor (
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
  employee_id int,
  language_code varchar(6),
  pricegroup_id int,
  curr char(3),
  startdate date,
  enddate date
);
--
CREATE TABLE project (
  id int default nextval('id'),
  projectnumber text,
  description text,
  startdate date,
  enddate date,
  parts_id int,
  production float default 0,
  completed float default 0,
  customer_id int
);
--
CREATE TABLE partsgroup (
  id int default nextval('id'),
  partsgroup text
);
--
CREATE TABLE status (
  trans_id int,
  formname text,
  printed bool default 'f',
  emailed bool default 'f',
  spoolfile text
);
--
CREATE TABLE department (
  id int default nextval('id'),
  description text,
  role char(1) default 'P'
);
--
-- department transaction table
CREATE TABLE dpt_trans (
  trans_id int,
  department_id int
);
--
-- business table
CREATE TABLE business (
  id int default nextval('id'),
  description text,
  discount float4
);
--
-- SIC
CREATE TABLE sic (
  code varchar(6),
  sictype char(1),
  description text
);
--
CREATE TABLE warehouse (
  id int default nextval('id'),
  description text
);
--
CREATE TABLE inventory (
  warehouse_id int,
  parts_id int,
  trans_id int,
  orderitems_id int,
  qty float4,
  shippingdate date,
  employee_id int
) WITH OIDS;
--
CREATE TABLE yearend (
  trans_id int,
  transdate date
);
--
CREATE TABLE partsvendor (
  vendor_id int,
  parts_id int,
  partnumber text,
  leadtime int2,
  lastcost float,
  curr char(3)
);
--
CREATE TABLE pricegroup (
  id int default nextval('id'),
  pricegroup text
);
--
CREATE TABLE partscustomer (
  parts_id int,
  customer_id int,
  pricegroup_id int,
  pricebreak float4,
  sellprice float,
  validfrom date,
  validto date,
  curr char(3)
);
--
CREATE TABLE language (
  code varchar(6),
  description text
);
--
CREATE TABLE audittrail (
  trans_id int,
  tablename text,
  reference text,
  formname text,
  action text,
  transdate timestamp default current_timestamp,
  employee_id int
);
--
CREATE TABLE translation (
  trans_id int,
  language_code varchar(6),
  description text
);
--
CREATE TABLE recurring (
  id int,
  reference text,
  startdate date,
  nextdate date,
  enddate date,
  repeat int2,
  unit varchar(6),
  howmany int,
  payment bool default 'f'
);
--
CREATE TABLE recurringemail (
  id int,
  formname text,
  format text,
  message text
);
--
CREATE TABLE recurringprint (
  id int,
  formname text,
  format text,
  printer text
);
--
CREATE TABLE jcitems (
  id int default nextval('jcitemsid'),
  project_id int,
  parts_id int,
  description text,
  qty float4,
  allocated float4,
  sellprice float8,
  fxsellprice float8,
  serialnumber text,
  checkedin timestamp with time zone,
  checkedout timestamp with time zone,
  employee_id int,
  notes text
);

-- Session tracking table


CREATE SEQUENCE session_session_id_seq;

CREATE TABLE session(
session_id INTEGER PRIMARY KEY DEFAULT nextval('session_session_id_seq'),
sl_login VARCHAR(50),
token CHAR(32),
last_used TIMESTAMP default now()
);


