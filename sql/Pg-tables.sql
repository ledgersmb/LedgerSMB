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
INSERT INTO defaults (version) VALUES ('2.6.17');
--
CREATE TABLE acc_trans (
  trans_id int,
  chart_id int NOT NULL,
  amount numeric(10,2),
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
  qty integer,
  allocated integer,
  sellprice numeric(10,2),
  fxsellprice numeric(10,2),
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
  discount numeric, 
  taxincluded bool default 'f',
  creditlimit numeric(10,2) default 0,
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
  listprice numeric(10,2),
  sellprice numeric(10,2),
  lastcost numeric(10,2),
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
  avgcost numeric(10,2)
);
--
CREATE TABLE assembly (
  id int,
  parts_id int,
  qty numeric,
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
  amount numeric(10,2),
  netamount numeric(10,2),
  paid numeric(10,2),
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
  amount numeric(10,2),
  netamount numeric(10,2),
  paid numeric(10,2),
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
  rate numeric,
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
  amount numeric(10,2),
  netamount numeric(10,2),
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
  qty numeric,
  sellprice numeric(10,2),
  discount numeric,
  unit varchar(5),
  project_id int,
  reqdate date,
  ship numeric,
  serialnumber text,
  notes text
) WITH OIDS;
--
CREATE TABLE exchangerate (
  curr char(3),
  transdate date,
  buy numeric,
  sell numeric
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
  id int default nextval('id'),
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
  discount numeric
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
  qty numeric,
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
  lastcost numeric(10,2),
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
  pricebreak numeric,
  sellprice numeric(10,2),
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
  qty numeric,
  allocated numeric,
  sellprice numeric(10,2),
  fxsellprice numeric(10,2),
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


create table id_tracker (
  id int PRIMARY KEY,
  table_name text
);

insert into id_tracker (id, table_name) SELECT id, 'ap' FROM ap;

CREATE RULE ap_id_track_i AS ON insert TO ap 
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'ap');

CREATE RULE ap_id_track_u AS ON update TO ap 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

insert into id_tracker (id, table_name) SELECT id, 'ar' FROM ap;

CREATE RULE ar_id_track_i AS ON insert TO ar 
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'ar');

CREATE RULE ar_id_track_u AS ON update TO ar 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'business' FROM business;

CREATE RULE business_id_track_i AS ON insert TO business 
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'business');

CREATE RULE business_id_track_u AS ON update TO business 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'chart' FROM chart;

CREATE RULE chart_id_track_i AS ON insert TO chart 
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'chart');

CREATE RULE chart_id_track_u AS ON update TO chart 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'customer' FROM customer;

CREATE RULE customer_id_track_i AS ON insert TO customer
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'customer');

CREATE RULE customer_id_track_u AS ON update TO customer 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'department' FROM department;

CREATE RULE department_id_track_i AS ON insert TO department
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'department');

CREATE RULE department_id_track_u AS ON update TO department 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'employee' FROM employee;

CREATE RULE employee_id_track_i AS ON insert TO employee
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'employee');

CREATE RULE employee_id_track_u AS ON update TO employee
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'gl' FROM gl;

CREATE RULE gl_id_track_i AS ON insert TO gl
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'gl');

CREATE RULE gl_id_track_u AS ON update TO gl 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'oe' FROM oe;

CREATE RULE oe_id_track_i AS ON insert TO oe
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'oe');

CREATE RULE oe_id_track_u AS ON update TO oe 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'parts' FROM parts;

CREATE RULE parts_id_track_i AS ON insert TO parts
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'parts');

CREATE RULE parts_id_track_u AS ON update TO parts 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'partsgroup' FROM partsgroup;

CREATE RULE partsgroup_id_track_i AS ON insert TO partsgroup
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'partsgroup');

CREATE RULE partsgroup_id_track_u AS ON update TO partsgroup 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'pricegroup' FROM pricegroup;

CREATE RULE pricegroup_id_track_i AS ON insert TO pricegroup
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'pricegroup');

CREATE RULE pricegroup_id_track_u AS ON update TO pricegroup 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'project' FROM project;

CREATE RULE project_id_track_i AS ON insert TO project
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'project');

CREATE RULE project_id_track_u AS ON update TO project 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'vendor' FROM vendor;

CREATE RULE vendor_id_track_i AS ON insert TO vendor
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'vendor');

CREATE RULE employee_id_track_u AS ON update TO vendor 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

INSERT INTO id_tracker (id, table_name) SELECT id, 'warehouse' FROM warehouse;

CREATE RULE warehouse_id_track_i AS ON insert TO warehouse
DO ALSO INSERT INTO id_tracker (id, table_name) VALUES (new.id, 'employee');

CREATE RULE warehouse_id_track_u AS ON update TO warehouse 
DO ALSO UPDATE id_tracker SET id = new.id WHERE id = old.id;

