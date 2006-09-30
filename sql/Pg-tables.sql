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

create table transactions (
  id int PRIMARY KEY,
  table_name text
);
--
CREATE TABLE makemodel (
  parts_id int PRIMARY KEY,
  make text,
  model text
);
--
CREATE TABLE gl (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY,
  reference text,
  description text,
  transdate date DEFAULT current_date,
  employee_id int,
  notes text,
  department_id int default 0
);
--
CREATE TABLE chart (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY,
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
  accno text PRIMARY KEY,
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
  version varchar(8) PRIMARY KEY,
  curr text,
  closedto date,
  revtrans bool DEFAULT 't',
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
--
CREATE TABLE acc_trans (
  trans_id int REFERENCES transactions(id),
  chart_id int NOT NULL REFERENCES chart (id),
  amount NUMERIC,
  transdate date DEFAULT current_date,
  source text,
  cleared bool DEFAULT 'f',
  fx_transaction bool DEFAULT 'f',
  project_id int,
  memo text,
  invoice_id int,
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE invoice (
  id int DEFAULT nextval ( 'invoiceid' ) PRIMARY KEY,
  trans_id int,
  parts_id int,
  description text,
  qty integer,
  allocated integer,
  sellprice NUMERIC,
  fxsellprice NUMERIC,
  discount float4, -- jd: check into this
  assemblyitem bool DEFAULT 'f',
  unit varchar(5),
  project_id int,
  deliverydate date,
  serialnumber text,
  notes text
);
--
CREATE TABLE customer (
  id int default nextval('id') PRIMARY KEY,
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
  discount numeric, 
  taxincluded bool default 'f',
  creditlimit NUMERIC default 0,
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
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY,
  partnumber text,
  description text,
  unit varchar(5),
  listprice NUMERIC,
  sellprice NUMERIC,
  lastcost NUMERIC,
  priceupdate date DEFAULT current_date,
  weight numeric,
  onhand numeric DEFAULT 0,
  notes text,
  makemodel bool DEFAULT 'f',
  assembly bool DEFAULT 'f',
  alternate bool DEFAULT 'f',
  rop float4, -- jd: what is this
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
  avgcost NUMERIC
);
--
CREATE TABLE assembly (
  id int,
  parts_id int,
  qty numeric,
  bom bool,
  adj bool,
  PRIMARY KEY (id, parts_id)
);
--
CREATE TABLE ar (
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY,
  invnumber text,
  transdate date DEFAULT current_date,
  customer_id int,
  taxincluded bool,
  amount NUMERIC,
  netamount NUMERIC,
  paid NUMERIC,
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
  id int DEFAULT nextval ( 'id' ) PRIMARY KEY,
  invnumber text,
  transdate date DEFAULT current_date,
  vendor_id int,
  taxincluded bool DEFAULT 'f',
  amount NUMERIC,
  netamount NUMERIC,
  paid NUMERIC,
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
  chart_id int,
  PRIMARY KEY (parts_id, chart_id)
);
--
CREATE TABLE tax (
  chart_id int PRIMARY KEY,
  rate numeric,
  taxnumber text,
  validto date,
  FOREIGN KEY (chart_id) REFERENCES chart (id)
);
--
CREATE TABLE customertax (
  customer_id int,
  chart_id int,
  PRIMARY KEY (customer_id, chart_id)
);
--
CREATE TABLE vendortax (
  vendor_id int,
  chart_id int,
  PRIMARY KEY (vendor_id, chart_id)
);
--
CREATE TABLE oe (
  id int default nextval('id') PRIMARY KEY,
  ordnumber text,
  transdate date default current_date,
  vendor_id int,
  customer_id int,
  amount NUMERIC,
  netamount NUMERIC,
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
  id int default nextval('orderitemsid') PRIMARY KEY,
  trans_id int,
  parts_id int,
  description text,
  qty numeric,
  sellprice NUMERIC,
  discount numeric,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship numeric,
  serialnumber text,
  notes text
);
--
CREATE TABLE exchangerate (
  curr char(3),
  transdate date,
  buy numeric,
  sell numeric,
  PRIMARY KEY (curr, transdate)
);
--
create table employee (
  id int default nextval('id') PRIMARY KEY,
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
  shiptoemail text,
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE vendor (
  id int default nextval('id') PRIMARY KEY,
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
  discount numeric,
  creditlimit numeric default 0,
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
  id int default nextval('id') PRIMARY KEY,
  projectnumber text,
  description text,
  startdate date,
  enddate date,
  parts_id int,
  production numeric default 0,
  completed numeric default 0,
  customer_id int
);
--
CREATE TABLE partsgroup (
  id int default nextval('id') PRIMARY KEY,
  partsgroup text
);
--
CREATE TABLE status (
  trans_id int PRIMARY KEY,
  formname text,
  printed bool default 'f',
  emailed bool default 'f',
  spoolfile text
);
--
CREATE TABLE department (
  id int default nextval('id') PRIMARY KEY,
  description text,
  role char(1) default 'P'
);
--
-- department transaction table
CREATE TABLE dpt_trans (
  trans_id int PRIMARY KEY,
  department_id int
);
--
-- business table
CREATE TABLE business (
  id int default nextval('id') PRIMARY KEY,
  description text,
  discount numeric
);
--
-- SIC
CREATE TABLE sic (
  code varchar(6) PRIMARY KEY,
  sictype char(1),
  description text
);
--
CREATE TABLE warehouse (
  id int default nextval('id') PRIMARY KEY,
  description text
);
--
CREATE TABLE inventory (
  warehouse_id int,
  parts_id int,
  trans_id int,
  orderitems_id int,
  qty numeric,
  shippingdate date,
  employee_id int,
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE yearend (
  trans_id int PRIMARY KEY,
  transdate date
);
--
CREATE TABLE partsvendor (
  vendor_id int,
  parts_id int,
  partnumber text,
  leadtime int2,
  lastcost NUMERIC,
  curr char(3),
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE pricegroup (
  id int default nextval('id') PRIMARY KEY,
  pricegroup text
);
--
CREATE TABLE partscustomer (
  parts_id int,
  customer_id int,
  pricegroup_id int,
  pricebreak numeric,
  sellprice NUMERIC,
  validfrom date,
  validto date,
  curr char(3),
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE language (
  code varchar(6) PRIMARY KEY,
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
  employee_id int,
  entry_id BIGSERIAL PRIMARY KEY
);
--
CREATE TABLE translation (
  trans_id int,
  language_code varchar(6),
  description text,
  PRIMARY KEY (trans_id, language_code)
);
--
CREATE TABLE recurring (
  id int PRIMARY KEY,
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
  id int PRIMARY KEY,
  formname text,
  format text,
  message text
);
--
CREATE TABLE recurringprint (
  id int PRIMARY KEY,
  formname text,
  format text,
  printer text
);
--
CREATE TABLE jcitems (
  id int default nextval('jcitemsid') PRIMARY KEY,
  project_id int,
  parts_id int,
  description text,
  qty numeric,
  allocated numeric,
  sellprice NUMERIC,
  fxsellprice NUMERIC,
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


create table transactions (
  id int PRIMARY KEY,
  table_name text
);

insert into transactions (id, table_name) SELECT id, 'ap' FROM ap;

CREATE RULE ap_id_track_i AS ON insert TO ap 
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'ap');

CREATE RULE ap_id_track_u AS ON update TO ap 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

insert into transactions (id, table_name) SELECT id, 'ar' FROM ap;

CREATE RULE ar_id_track_i AS ON insert TO ar 
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'ar');

CREATE RULE ar_id_track_u AS ON update TO ar 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'business' FROM business;

CREATE RULE business_id_track_i AS ON insert TO business 
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'business');

CREATE RULE business_id_track_u AS ON update TO business 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'chart' FROM chart;

CREATE RULE chart_id_track_i AS ON insert TO chart 
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'chart');

CREATE RULE chart_id_track_u AS ON update TO chart 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'customer' FROM customer;

CREATE RULE customer_id_track_i AS ON insert TO customer
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'customer');

CREATE RULE customer_id_track_u AS ON update TO customer 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'department' FROM department;

CREATE RULE department_id_track_i AS ON insert TO department
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'department');

CREATE RULE department_id_track_u AS ON update TO department 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'employee' FROM employee;

CREATE RULE employee_id_track_i AS ON insert TO employee
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'employee');

CREATE RULE employee_id_track_u AS ON update TO employee
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'gl' FROM gl;

CREATE RULE gl_id_track_i AS ON insert TO gl
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'gl');

CREATE RULE gl_id_track_u AS ON update TO gl 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'oe' FROM oe;

CREATE RULE oe_id_track_i AS ON insert TO oe
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'oe');

CREATE RULE oe_id_track_u AS ON update TO oe 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'parts' FROM parts;

CREATE RULE parts_id_track_i AS ON insert TO parts
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'parts');

CREATE RULE parts_id_track_u AS ON update TO parts 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'partsgroup' FROM partsgroup;

CREATE RULE partsgroup_id_track_i AS ON insert TO partsgroup
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'partsgroup');

CREATE RULE partsgroup_id_track_u AS ON update TO partsgroup 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'pricegroup' FROM pricegroup;

CREATE RULE pricegroup_id_track_i AS ON insert TO pricegroup
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'pricegroup');

CREATE RULE pricegroup_id_track_u AS ON update TO pricegroup 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'project' FROM project;

CREATE RULE project_id_track_i AS ON insert TO project
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'project');

CREATE RULE project_id_track_u AS ON update TO project 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'vendor' FROM vendor;

CREATE RULE vendor_id_track_i AS ON insert TO vendor
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'vendor');

CREATE RULE employee_id_track_u AS ON update TO vendor 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'warehouse' FROM warehouse;

CREATE RULE warehouse_id_track_i AS ON insert TO warehouse
DO INSERT INTO transactions (id, table_name) VALUES (new.id, 'employee');

CREATE RULE warehouse_id_track_u AS ON update TO warehouse 
DO UPDATE transactions SET id = new.id WHERE id = old.id;

CREATE TABLE custom_table_catalog (
table_id SERIAL PRIMARY KEY,
extends TEXT,
table_name TEXT
);

CREATE TABLE custom_field_catalog (
field_id SERIAL PRIMARY KEY,
table_id INT REFERENCES custom_table_catalog,
field_name TEXT
);
INSERT INTO defaults (version) VALUES ('2.6.18');
