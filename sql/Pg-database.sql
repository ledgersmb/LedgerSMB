begin;
--
CREATE TABLE transactions (
  id int PRIMARY KEY,
  table_name text
);

-- BEGIN new entity management
CREATE TABLE entity (
  id serial PRIMARY KEY,
  name text check (name ~ '[[:alnum:]_]'),
  entity_class integer not null);

COMMENT ON TABLE entity IS $$ The primary entity table to map to all contacts $$;
COMMENT ON COLUMN entity.name IS $$ This is the common name of an entity. If it was a person it may be Joshua Drake, a company Acme Corp. You may also choose to use a domain such as commandprompt.com $$;

CREATE TABLE entity_class (
  id serial primary key,
  class text check (class ~ '[[:alnum:]_]') NOT NULL,
  active boolean not null default TRUE);
  
COMMENT ON TABLE entity_class IS $$ Defines the class type such as vendor, customer, contact, employee $$;
  
CREATE UNIQUE index entity_class_unique_idx ON entity_class(lower(class));

COMMENT ON INDEX entity_class_unique_idx IS $$ Helps truly define unique. Which we could do that with Primary Keys $$;

ALTER TABLE entity ADD FOREIGN KEY (entity_class) REFERENCES entity_class(id);

INSERT INTO entity_class (class) VALUES ('Vendor');
INSERT INTO entity_class (class) VALUES ('Customer');
INSERT INTO entity_class (class) VALUES ('Employee');
INSERT INTO entity_class (class) VALUES ('Contact');
INSERT INTO entity_class (class) VALUES ('Lead');
INSERT INTO entity_class (class) VALUES ('Referral');

CREATE TABLE country (
  id serial PRIMARY KEY,
  name text check (name ~ '[[:alnum:]_]') NOT NULL,
  short_name text check (short_name ~ '[[:alnum:]_]') NOT NULL,
  itu text);
  
COMMENT ON COLUMN country.itu IS $$ The ITU Telecommunication Standardization Sector code for calling internationally. For example, the US is 1, Great Britain is 44 $$;


CREATE UNIQUE INDEX country_name_idx on country(lower(name));

CREATE TABLE location (
  id serial PRIMARY KEY,
  line_one text check (line_one ~ '[[:alnum:]_]') NOT NULL,
  line_two text,
  line_three text,
  city_province text check (city_province ~ '[[:alnum:]_]') NOT NULL,
  country_id integer not null REFERENCES country(id));

CREATE TABLE company (
  id serial UNIQUE,
  legal_name text check (legal_name ~ '[[:alnum:]_]'),
  entity_class_id integer not null references entity_class(id),
  primary_location_id integer references location(id),
  tax_id text,
  PRIMARY KEY (legal_name,primary_location_id));


COMMENT ON COLUMN company.primary_location_id IS $$ This is the location that should show up by default for any forms $$;
COMMENT ON COLUMN company.tax_id IS $$ In the US this would be a EIN. $$;

CREATE TABLE salutation (
 id serial unique,
 salutation text primary key);

CREATE TABLE person (
 id serial PRIMARY KEY,
 salutation_id integer references salutation(id),
 entity_class_id integer references entity_class(id),
 first_name text check (first_name ~ '[[:alnum:]_]') NOT NULL,
 middle_name text,
 last_name text check (last_name ~ '[[:alnum:]_]') NOT NULL,
 primary_location_id integer references location(id));
 


-- END entity   

--
CREATE TABLE makemodel (
  parts_id int PRIMARY KEY,
  make text,
  model text
);
--
CREATE TABLE gl (
  id serial PRIMARY KEY,
  reference text,
  description text,
  transdate date DEFAULT current_date,
  employee_id int,
  notes text,
  department_id int default 0
);
--
CREATE TABLE chart (
  id serial PRIMARY KEY,
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
  setting_key text primary key,
  value text
);
/*
  inventory_accno_id int,
  income_accno_id int,
  expense_accno_id int,
  fxgain_accno_id int,
  fxloss_accno_id int,
*/
\COPY defaults FROM stdin WITH DELIMITER |
sinumber|1
sonumber|1
yearend|1
businessnumber|1
version|1.2.0
closedto|\N
revtrans|1
ponumber|1
sqnumber|1
rfqnumber|1
audittrail|0
vinumber|1
employeenumber|1
partnumber|1
customernumber|1
vendornumber|1
glnumber|1
projectnumber|1
\.
-- */
CREATE TABLE acc_trans (
  trans_id int,
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
  id serial PRIMARY KEY,
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
  id serial PRIMARY KEY,
  entity_id int references entity(id),
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
  startdate date DEFAULT CURRENT_DATE,
  enddate date
);

COMMENT ON TABLE customer IS $$ This is now a metadata table that holds information specific to customers. Source info is not part of the entity management $$;
COMMENT ON COLUMN customer.entity_id IS $$ This is the relationship between entities and customers $$;


--
--
CREATE TABLE parts (
  id serial PRIMARY KEY,
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
  id serial PRIMARY KEY,
  invnumber text,
  transdate date DEFAULT current_date,
  entity_id int REFERENCES entity(id),
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

COMMENT ON COLUMN ar.entity_id IS $$ Used to be customer_id, but customer is now metadata. You need to push to entity $$;

--
CREATE TABLE ap (
  id serial PRIMARY KEY,
  invnumber text,
  transdate date DEFAULT current_date,
  entity_id int REFERENCES entity(id),
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

COMMENT ON COLUMN ap.entity_id IS $$ Used to be customer_id, but customer is now metadata. You need to push to entity $$;

--
CREATE TABLE taxmodule (
  taxmodule_id serial PRIMARY KEY,
  taxmodulename text NOT NULL
);
--
CREATE TABLE taxcategory (
  taxcategory_id serial PRIMARY KEY,
  taxcategoryname text NOT NULL,
  taxmodule_id int NOT NULL,
  FOREIGN KEY (taxmodule_id) REFERENCES taxmodule (taxmodule_id)
);
--
CREATE TABLE partstax (
  parts_id int,
  chart_id int,
  taxcategory_id int,
  PRIMARY KEY (parts_id, chart_id),
  FOREIGN KEY (parts_id) REFERENCES parts (id),
  FOREIGN KEY (chart_id) REFERENCES chart (id),
  FOREIGN KEY (taxcategory_id) REFERENCES taxcategory (taxcategory_id)
);
--
CREATE TABLE tax (
  chart_id int PRIMARY KEY,
  rate numeric,
  taxnumber text,
  validto date,
  pass integer DEFAULT 0 NOT NULL,
  taxmodule_id int DEFAULT 1 NOT NULL,
  FOREIGN KEY (chart_id) REFERENCES chart (id),
  FOREIGN KEY (taxmodule_id) REFERENCES taxmodule (taxmodule_id)
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

CREATE TABLE oe_class (
  id smallint unique check(id IN (1,2)),
  oe_class text primary key);
  
INSERT INTO oe_class(id,oe_class) values (1,'Sales Order');
INSERT INTO oe_class(id,oe_class) values (2,'Purchase Order');

COMMENT ON TABLE oe_class IS $$ This could probably be done better. But I need to remove the customer_id/vendor_id relationship and instead rely on a classification $$;


CREATE TABLE oe (
  id serial PRIMARY KEY,
  ordnumber text,
  transdate date default current_date,
  entity_id integer references entity(id) NOT NULL,
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
  terms int2 DEFAULT 0,
  oe_class_id int references oe_class(id) NOT NULL
);



--
CREATE TABLE orderitems (
  id serial PRIMARY KEY,
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
  id serial PRIMARY KEY,
  entity_id integer references entity(id) not null,
  login text,
  startdate date default current_date,
  enddate date,
  notes text,
  role varchar(20),
  sales bool default 'f',
  ssn varchar(20),
  iban varchar(34),
  bic varchar(11),
  managerid int,
  employeenumber varchar(32),
  dob date
);

COMMENT ON TABLE employee IS $$ Is a metadata table specific to employees $$;

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

-- SHIPTO really needs to be pushed into entities too

--
CREATE TABLE vendor (
  id serial PRIMARY KEY,
  entity_id int references entity(id) not null,
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

COMMENT ON TABLE vendor IS $$ Now a meta data table $$;

--
CREATE TABLE project (
  id serial PRIMARY KEY,
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
  id serial PRIMARY KEY,
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
  id serial PRIMARY KEY,
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
  id serial PRIMARY KEY,
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
  id serial PRIMARY KEY,
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
  entity_id int references entity(id) not null,
  parts_id int,
  partnumber text,
  leadtime int2,
  lastcost NUMERIC,
  curr char(3),
  entry_id SERIAL PRIMARY KEY
);
--
CREATE TABLE pricegroup (
  id serial PRIMARY KEY,
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

-- How does partscustomer.customer_id relate here?

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
  id serial PRIMARY KEY,
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

INSERT INTO taxmodule (
  taxmodule_id, taxmodulename
  ) VALUES (
  1, 'Simple'
);

create index acc_trans_trans_id_key on acc_trans (trans_id);
create index acc_trans_chart_id_key on acc_trans (chart_id);
create index acc_trans_transdate_key on acc_trans (transdate);
create index acc_trans_source_key on acc_trans (lower(source));
--
create index ap_id_key on ap (id);
create index ap_transdate_key on ap (transdate);
create index ap_invnumber_key on ap (invnumber);
create index ap_ordnumber_key on ap (ordnumber);
create index ap_employee_id_key on ap (employee_id);
create index ap_quonumber_key on ap (quonumber);
--
create index ar_id_key on ar (id);
create index ar_transdate_key on ar (transdate);
create index ar_invnumber_key on ar (invnumber);
create index ar_ordnumber_key on ar (ordnumber);
create index ar_employee_id_key on ar (employee_id);
create index ar_quonumber_key on ar (quonumber);
--
create index assembly_id_key on assembly (id);
--
create index chart_id_key on chart (id);
create unique index chart_accno_key on chart (accno);
create index chart_category_key on chart (category);
create index chart_link_key on chart (link);
create index chart_gifi_accno_key on chart (gifi_accno);
--
create index customer_id_key on customer (id);
create index customer_customernumber_key on customer (customernumber);
create index customer_name_key on customer (lower(name));
create index customer_contact_key on customer (lower(contact));
create index customer_customer_id_key on customertax (customer_id);
--
create index employee_id_key on employee (id);
create unique index employee_login_key on employee (login);
create index employee_name_key on employee (lower(name));
--
create index exchangerate_ct_key on exchangerate (curr, transdate);
--
create unique index gifi_accno_key on gifi (accno);
--
create index gl_id_key on gl (id);
create index gl_transdate_key on gl (transdate);
create index gl_reference_key on gl (reference);
create index gl_description_key on gl (lower(description));
create index gl_employee_id_key on gl (employee_id);
--
create index invoice_id_key on invoice (id);
create index invoice_trans_id_key on invoice (trans_id);
--
create index makemodel_parts_id_key on makemodel (parts_id);
create index makemodel_make_key on makemodel (lower(make));
create index makemodel_model_key on makemodel (lower(model));
--
create index oe_id_key on oe (id);
create index oe_transdate_key on oe (transdate);
create index oe_ordnumber_key on oe (ordnumber);
create index oe_employee_id_key on oe (employee_id);
create index orderitems_trans_id_key on orderitems (trans_id);
create index orderitems_id_key on orderitems (id);
--
create index parts_id_key on parts (id);
create index parts_partnumber_key on parts (lower(partnumber));
create index parts_description_key on parts (lower(description));
create index partstax_parts_id_key on partstax (parts_id);
--
create index vendor_id_key on vendor (id);
create index vendor_name_key on vendor (lower(name));
create index vendor_vendornumber_key on vendor (vendornumber);
create index vendor_contact_key on vendor (lower(contact));
--
create index shipto_trans_id_key on shipto (trans_id);
--
create index project_id_key on project (id);
create unique index projectnumber_key on project (projectnumber);
--
create index partsgroup_id_key on partsgroup (id);
create unique index partsgroup_key on partsgroup (partsgroup);
--
create index status_trans_id_key on status (trans_id);
--
create index department_id_key on department (id);
--
create index partsvendor_parts_id_key on partsvendor (parts_id);
--
create index pricegroup_pricegroup_key on pricegroup (pricegroup);
create index pricegroup_id_key on pricegroup (id);
--
create index audittrail_trans_id_key on audittrail (trans_id);
--
create index translation_trans_id_key on translation (trans_id);
--
create unique index language_code_key on language (code);
--
create index jcitems_id_key on jcitems (id);

-- Popular some entity data

INSERT INTO country(short_name,name) VALUES ('AC','Ascension Island');
INSERT INTO country(short_name,name) VALUES ('AD','Andorra');
INSERT INTO country(short_name,name) VALUES ('AE','United Arab Emirates');
INSERT INTO country(short_name,name) VALUES ('AF','Afghanistan');
INSERT INTO country(short_name,name) VALUES ('AG','Antigua and Barbuda');
INSERT INTO country(short_name,name) VALUES ('AI','Anguilla');
INSERT INTO country(short_name,name) VALUES ('AL','Albania');
INSERT INTO country(short_name,name) VALUES ('AM','Armenia');
INSERT INTO country(short_name,name) VALUES ('AN','Netherlands Antilles');
INSERT INTO country(short_name,name) VALUES ('AO','Angola');
INSERT INTO country(short_name,name) VALUES ('AQ','Antarctica');
INSERT INTO country(short_name,name) VALUES ('AR','Argentina');
INSERT INTO country(short_name,name) VALUES ('AS','American Samoa');
INSERT INTO country(short_name,name) VALUES ('AT','Austria');
INSERT INTO country(short_name,name) VALUES ('AU','Australia');
INSERT INTO country(short_name,name) VALUES ('AW','Aruba');
INSERT INTO country(short_name,name) VALUES ('AX','Aland Islands');
INSERT INTO country(short_name,name) VALUES ('AZ','Azerbaijan');
INSERT INTO country(short_name,name) VALUES ('BA','Bosnia and Herzegovina');
INSERT INTO country(short_name,name) VALUES ('BB','Barbados');
INSERT INTO country(short_name,name) VALUES ('BD','Bangladesh');
INSERT INTO country(short_name,name) VALUES ('BE','Belgium');
INSERT INTO country(short_name,name) VALUES ('BF','Burkina Faso');
INSERT INTO country(short_name,name) VALUES ('BG','Bulgaria');
INSERT INTO country(short_name,name) VALUES ('BH','Bahrain');
INSERT INTO country(short_name,name) VALUES ('BI','Burundi');
INSERT INTO country(short_name,name) VALUES ('BJ','Benin');
INSERT INTO country(short_name,name) VALUES ('BM','Bermuda');
INSERT INTO country(short_name,name) VALUES ('BN','Brunei Darussalam');
INSERT INTO country(short_name,name) VALUES ('BO','Bolivia');
INSERT INTO country(short_name,name) VALUES ('BR','Brazil');
INSERT INTO country(short_name,name) VALUES ('BS','Bahamas');
INSERT INTO country(short_name,name) VALUES ('BT','Bhutan');
INSERT INTO country(short_name,name) VALUES ('BV','Bouvet Island');
INSERT INTO country(short_name,name) VALUES ('BW','Botswana');
INSERT INTO country(short_name,name) VALUES ('BY','Belarus');
INSERT INTO country(short_name,name) VALUES ('BZ','Belize');
INSERT INTO country(short_name,name) VALUES ('CA','Canada');
INSERT INTO country(short_name,name) VALUES ('CC','Cocos (Keeling) Islands');
INSERT INTO country(short_name,name) VALUES ('CD','Congo, Democratic Republic');
INSERT INTO country(short_name,name) VALUES ('CF','Central African Republic');
INSERT INTO country(short_name,name) VALUES ('CG','Congo');
INSERT INTO country(short_name,name) VALUES ('CH','Switzerland');
INSERT INTO country(short_name,name) VALUES ('CI','Cote D\'Ivoire (Ivory Coast)');
INSERT INTO country(short_name,name) VALUES ('CK','Cook Islands');
INSERT INTO country(short_name,name) VALUES ('CL','Chile');
INSERT INTO country(short_name,name) VALUES ('CM','Cameroon');
INSERT INTO country(short_name,name) VALUES ('CN','China');
INSERT INTO country(short_name,name) VALUES ('CO','Colombia');
INSERT INTO country(short_name,name) VALUES ('CR','Costa Rica');
INSERT INTO country(short_name,name) VALUES ('CS','Czechoslovakia (former)');
INSERT INTO country(short_name,name) VALUES ('CU','Cuba');
INSERT INTO country(short_name,name) VALUES ('CV','Cape Verde');
INSERT INTO country(short_name,name) VALUES ('CX','Christmas Island');
INSERT INTO country(short_name,name) VALUES ('CY','Cyprus');
INSERT INTO country(short_name,name) VALUES ('CZ','Czech Republic');
INSERT INTO country(short_name,name) VALUES ('DE','Germany');
INSERT INTO country(short_name,name) VALUES ('DJ','Djibouti');
INSERT INTO country(short_name,name) VALUES ('DK','Denmark');
INSERT INTO country(short_name,name) VALUES ('DM','Dominica');
INSERT INTO country(short_name,name) VALUES ('DO','Dominican Republic');
INSERT INTO country(short_name,name) VALUES ('DZ','Algeria');
INSERT INTO country(short_name,name) VALUES ('EC','Ecuador');
INSERT INTO country(short_name,name) VALUES ('EE','Estonia');
INSERT INTO country(short_name,name) VALUES ('EG','Egypt');
INSERT INTO country(short_name,name) VALUES ('EH','Western Sahara');
INSERT INTO country(short_name,name) VALUES ('ER','Eritrea');
INSERT INTO country(short_name,name) VALUES ('ES','Spain');
INSERT INTO country(short_name,name) VALUES ('ET','Ethiopia');
INSERT INTO country(short_name,name) VALUES ('FI','Finland');
INSERT INTO country(short_name,name) VALUES ('FJ','Fiji');
INSERT INTO country(short_name,name) VALUES ('FK','Falkland Islands (Malvinas)');
INSERT INTO country(short_name,name) VALUES ('FM','Micronesia');
INSERT INTO country(short_name,name) VALUES ('FO','Faroe Islands');
INSERT INTO country(short_name,name) VALUES ('FR','France');
INSERT INTO country(short_name,name) VALUES ('FX','France, Metropolitan');
INSERT INTO country(short_name,name) VALUES ('GA','Gabon');
INSERT INTO country(short_name,name) VALUES ('GB','Great Britain (UK)');
INSERT INTO country(short_name,name) VALUES ('GD','Grenada');
INSERT INTO country(short_name,name) VALUES ('GE','Georgia');
INSERT INTO country(short_name,name) VALUES ('GF','French Guiana');
INSERT INTO country(short_name,name) VALUES ('GH','Ghana');
INSERT INTO country(short_name,name) VALUES ('GI','Gibraltar');
INSERT INTO country(short_name,name) VALUES ('GL','Greenland');
INSERT INTO country(short_name,name) VALUES ('GM','Gambia');
INSERT INTO country(short_name,name) VALUES ('GN','Guinea');
INSERT INTO country(short_name,name) VALUES ('GP','Guadeloupe');
INSERT INTO country(short_name,name) VALUES ('GQ','Equatorial Guinea');
INSERT INTO country(short_name,name) VALUES ('GR','Greece');
INSERT INTO country(short_name,name) VALUES ('GS','S. Georgia and S. Sandwich Isls.');
INSERT INTO country(short_name,name) VALUES ('GT','Guatemala');
INSERT INTO country(short_name,name) VALUES ('GU','Guam');
INSERT INTO country(short_name,name) VALUES ('GW','Guinea-Bissau');
INSERT INTO country(short_name,name) VALUES ('GY','Guyana');
INSERT INTO country(short_name,name) VALUES ('HK','Hong Kong');
INSERT INTO country(short_name,name) VALUES ('HM','Heard and McDonald Islands');
INSERT INTO country(short_name,name) VALUES ('HN','Honduras');
INSERT INTO country(short_name,name) VALUES ('HR','Croatia (Hrvatska)');
INSERT INTO country(short_name,name) VALUES ('HT','Haiti');
INSERT INTO country(short_name,name) VALUES ('HU','Hungary');
INSERT INTO country(short_name,name) VALUES ('ID','Indonesia');
INSERT INTO country(short_name,name) VALUES ('IE','Ireland');
INSERT INTO country(short_name,name) VALUES ('IL','Israel');
INSERT INTO country(short_name,name) VALUES ('IM','Isle of Man');
INSERT INTO country(short_name,name) VALUES ('IN','India');
INSERT INTO country(short_name,name) VALUES ('IO','British Indian Ocean Territory');
INSERT INTO country(short_name,name) VALUES ('IQ','Iraq');
INSERT INTO country(short_name,name) VALUES ('IR','Iran');
INSERT INTO country(short_name,name) VALUES ('IS','Iceland');
INSERT INTO country(short_name,name) VALUES ('IT','Italy');
INSERT INTO country(short_name,name) VALUES ('JE','Jersey');
INSERT INTO country(short_name,name) VALUES ('JM','Jamaica');
INSERT INTO country(short_name,name) VALUES ('JO','Jordan');
INSERT INTO country(short_name,name) VALUES ('JP','Japan');
INSERT INTO country(short_name,name) VALUES ('KE','Kenya');
INSERT INTO country(short_name,name) VALUES ('KG','Kyrgyzstan');
INSERT INTO country(short_name,name) VALUES ('KH','Cambodia');
INSERT INTO country(short_name,name) VALUES ('KI','Kiribati');
INSERT INTO country(short_name,name) VALUES ('KM','Comoros');
INSERT INTO country(short_name,name) VALUES ('KN','Saint Kitts and Nevis');
INSERT INTO country(short_name,name) VALUES ('KP','Korea (North)');
INSERT INTO country(short_name,name) VALUES ('KR','Korea (South)');
INSERT INTO country(short_name,name) VALUES ('KW','Kuwait');
INSERT INTO country(short_name,name) VALUES ('KY','Cayman Islands');
INSERT INTO country(short_name,name) VALUES ('KZ','Kazakhstan');
INSERT INTO country(short_name,name) VALUES ('LA','Laos');
INSERT INTO country(short_name,name) VALUES ('LB','Lebanon');
INSERT INTO country(short_name,name) VALUES ('LC','Saint Lucia');
INSERT INTO country(short_name,name) VALUES ('LI','Liechtenstein');
INSERT INTO country(short_name,name) VALUES ('LK','Sri Lanka');
INSERT INTO country(short_name,name) VALUES ('LR','Liberia');
INSERT INTO country(short_name,name) VALUES ('LS','Lesotho');
INSERT INTO country(short_name,name) VALUES ('LT','Lithuania');
INSERT INTO country(short_name,name) VALUES ('LU','Luxembourg');
INSERT INTO country(short_name,name) VALUES ('LV','Latvia');
INSERT INTO country(short_name,name) VALUES ('LY','Libya');
INSERT INTO country(short_name,name) VALUES ('MA','Morocco');
INSERT INTO country(short_name,name) VALUES ('MC','Monaco');
INSERT INTO country(short_name,name) VALUES ('MD','Moldova');
INSERT INTO country(short_name,name) VALUES ('MG','Madagascar');
INSERT INTO country(short_name,name) VALUES ('MH','Marshall Islands');
INSERT INTO country(short_name,name) VALUES ('MK','F.Y.R.O.M. (Macedonia)');
INSERT INTO country(short_name,name) VALUES ('ML','Mali');
INSERT INTO country(short_name,name) VALUES ('MM','Myanmar');
INSERT INTO country(short_name,name) VALUES ('MN','Mongolia');
INSERT INTO country(short_name,name) VALUES ('MO','Macau');
INSERT INTO country(short_name,name) VALUES ('MP','Northern Mariana Islands');
INSERT INTO country(short_name,name) VALUES ('MQ','Martinique');
INSERT INTO country(short_name,name) VALUES ('MR','Mauritania');
INSERT INTO country(short_name,name) VALUES ('MS','Montserrat');
INSERT INTO country(short_name,name) VALUES ('MT','Malta');
INSERT INTO country(short_name,name) VALUES ('MU','Mauritius');
INSERT INTO country(short_name,name) VALUES ('MV','Maldives');
INSERT INTO country(short_name,name) VALUES ('MW','Malawi');
INSERT INTO country(short_name,name) VALUES ('MX','Mexico');
INSERT INTO country(short_name,name) VALUES ('MY','Malaysia');
INSERT INTO country(short_name,name) VALUES ('MZ','Mozambique');
INSERT INTO country(short_name,name) VALUES ('NA','Namibia');
INSERT INTO country(short_name,name) VALUES ('NC','New Caledonia');
INSERT INTO country(short_name,name) VALUES ('NE','Niger');
INSERT INTO country(short_name,name) VALUES ('NF','Norfolk Island');
INSERT INTO country(short_name,name) VALUES ('NG','Nigeria');
INSERT INTO country(short_name,name) VALUES ('NI','Nicaragua');
INSERT INTO country(short_name,name) VALUES ('NL','Netherlands');
INSERT INTO country(short_name,name) VALUES ('NO','Norway');
INSERT INTO country(short_name,name) VALUES ('NP','Nepal');
INSERT INTO country(short_name,name) VALUES ('NR','Nauru');
INSERT INTO country(short_name,name) VALUES ('NT','Neutral Zone');
INSERT INTO country(short_name,name) VALUES ('NU','Niue');
INSERT INTO country(short_name,name) VALUES ('NZ','New Zealand (Aotearoa)');
INSERT INTO country(short_name,name) VALUES ('OM','Oman');
INSERT INTO country(short_name,name) VALUES ('PA','Panama');
INSERT INTO country(short_name,name) VALUES ('PE','Peru');
INSERT INTO country(short_name,name) VALUES ('PF','French Polynesia');
INSERT INTO country(short_name,name) VALUES ('PG','Papua New Guinea');
INSERT INTO country(short_name,name) VALUES ('PH','Philippines');
INSERT INTO country(short_name,name) VALUES ('PK','Pakistan');
INSERT INTO country(short_name,name) VALUES ('PL','Poland');
INSERT INTO country(short_name,name) VALUES ('PM','St. Pierre and Miquelon');
INSERT INTO country(short_name,name) VALUES ('PN','Pitcairn');
INSERT INTO country(short_name,name) VALUES ('PR','Puerto Rico');
INSERT INTO country(short_name,name) VALUES ('PS','Palestinian Territory, Occupied');
INSERT INTO country(short_name,name) VALUES ('PT','Portugal');
INSERT INTO country(short_name,name) VALUES ('PW','Palau');
INSERT INTO country(short_name,name) VALUES ('PY','Paraguay');
INSERT INTO country(short_name,name) VALUES ('QA','Qatar');
INSERT INTO country(short_name,name) VALUES ('RE','Reunion');
INSERT INTO country(short_name,name) VALUES ('RO','Romania');
INSERT INTO country(short_name,name) VALUES ('RS','Serbia');
INSERT INTO country(short_name,name) VALUES ('RU','Russian Federation');
INSERT INTO country(short_name,name) VALUES ('RW','Rwanda');
INSERT INTO country(short_name,name) VALUES ('SA','Saudi Arabia');
INSERT INTO country(short_name,name) VALUES ('SB','Solomon Islands');
INSERT INTO country(short_name,name) VALUES ('SC','Seychelles');
INSERT INTO country(short_name,name) VALUES ('SD','Sudan');
INSERT INTO country(short_name,name) VALUES ('SE','Sweden');
INSERT INTO country(short_name,name) VALUES ('SG','Singapore');
INSERT INTO country(short_name,name) VALUES ('SH','St. Helena');
INSERT INTO country(short_name,name) VALUES ('SI','Slovenia');
INSERT INTO country(short_name,name) VALUES ('SJ','Svalbard & Jan Mayen Islands');
INSERT INTO country(short_name,name) VALUES ('SK','Slovak Republic');
INSERT INTO country(short_name,name) VALUES ('SL','Sierra Leone');
INSERT INTO country(short_name,name) VALUES ('SM','San Marino');
INSERT INTO country(short_name,name) VALUES ('SN','Senegal');
INSERT INTO country(short_name,name) VALUES ('SO','Somalia');
INSERT INTO country(short_name,name) VALUES ('SR','Suriname');
INSERT INTO country(short_name,name) VALUES ('ST','Sao Tome and Principe');
INSERT INTO country(short_name,name) VALUES ('SU','USSR (former)');
INSERT INTO country(short_name,name) VALUES ('SV','El Salvador');
INSERT INTO country(short_name,name) VALUES ('SY','Syria');
INSERT INTO country(short_name,name) VALUES ('SZ','Swaziland');
INSERT INTO country(short_name,name) VALUES ('TC','Turks and Caicos Islands');
INSERT INTO country(short_name,name) VALUES ('TD','Chad');
INSERT INTO country(short_name,name) VALUES ('TF','French Southern Territories');
INSERT INTO country(short_name,name) VALUES ('TG','Togo');
INSERT INTO country(short_name,name) VALUES ('TH','Thailand');
INSERT INTO country(short_name,name) VALUES ('TJ','Tajikistan');
INSERT INTO country(short_name,name) VALUES ('TK','Tokelau');
INSERT INTO country(short_name,name) VALUES ('TM','Turkmenistan');
INSERT INTO country(short_name,name) VALUES ('TN','Tunisia');
INSERT INTO country(short_name,name) VALUES ('TO','Tonga');
INSERT INTO country(short_name,name) VALUES ('TP','East Timor');
INSERT INTO country(short_name,name) VALUES ('TR','Turkey');
INSERT INTO country(short_name,name) VALUES ('TT','Trinidad and Tobago');
INSERT INTO country(short_name,name) VALUES ('TV','Tuvalu');
INSERT INTO country(short_name,name) VALUES ('TW','Taiwan');
INSERT INTO country(short_name,name) VALUES ('TZ','Tanzania');
INSERT INTO country(short_name,name) VALUES ('UA','Ukraine');
INSERT INTO country(short_name,name) VALUES ('UG','Uganda');
INSERT INTO country(short_name,name) VALUES ('UK','United Kingdom');
INSERT INTO country(short_name,name) VALUES ('UM','US Minor Outlying Islands');
INSERT INTO country(short_name,name) VALUES ('US','United States');
INSERT INTO country(short_name,name) VALUES ('UY','Uruguay');
INSERT INTO country(short_name,name) VALUES ('UZ','Uzbekistan');
INSERT INTO country(short_name,name) VALUES ('VA','Vatican City State (Holy See)');
INSERT INTO country(short_name,name) VALUES ('VC','Saint Vincent & the Grenadines');
INSERT INTO country(short_name,name) VALUES ('VE','Venezuela');
INSERT INTO country(short_name,name) VALUES ('VG','British Virgin Islands');
INSERT INTO country(short_name,name) VALUES ('VI','Virgin Islands (U.S.)');
INSERT INTO country(short_name,name) VALUES ('VN','Viet Nam');
INSERT INTO country(short_name,name) VALUES ('VU','Vanuatu');
INSERT INTO country(short_name,name) VALUES ('WF','Wallis and Futuna Islands');
INSERT INTO country(short_name,name) VALUES ('WS','Samoa');
INSERT INTO country(short_name,name) VALUES ('YE','Yemen');
INSERT INTO country(short_name,name) VALUES ('YT','Mayotte');
INSERT INTO country(short_name,name) VALUES ('YU','Yugoslavia (former)');
INSERT INTO country(short_name,name) VALUES ('ZA','South Africa');
INSERT INTO country(short_name,name) VALUES ('ZM','Zambia');
INSERT INTO country(short_name,name) VALUES ('ZR','Zaire');
INSERT INTO country(short_name,name) VALUES ('ZW','Zimbabwe');



--
CREATE FUNCTION del_yearend() RETURNS TRIGGER AS '
begin
  delete from yearend where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_yearend AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_yearend();
-- end trigger
--
CREATE FUNCTION del_department() RETURNS TRIGGER AS '
begin
  delete from dpt_trans where trans_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_department AFTER DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
CREATE TRIGGER del_department AFTER DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_department();
-- end trigger
--
CREATE FUNCTION del_customer() RETURNS TRIGGER AS '
begin
  delete from shipto where trans_id = old.id;
  delete from customertax where customer_id = old.id;
  delete from partscustomer where customer_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_customer AFTER DELETE ON customer FOR EACH ROW EXECUTE PROCEDURE del_customer();
-- end trigger
--
CREATE FUNCTION del_vendor() RETURNS TRIGGER AS '
begin
  delete from shipto where trans_id = old.id;
  delete from vendortax where vendor_id = old.id;
  delete from partsvendor where vendor_id = old.id;
  return NULL;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_vendor AFTER DELETE ON vendor FOR EACH ROW EXECUTE PROCEDURE del_vendor();
-- end trigger
--
CREATE FUNCTION del_exchangerate() RETURNS TRIGGER AS '

declare
  t_transdate date;
  t_curr char(3);
  t_id int;
  d_curr text;

begin

  select into d_curr substr(value,1,3) from defaults where setting_key = ''curr'';
  
  if TG_RELNAME = ''ar'' then
    select into t_curr, t_transdate curr, transdate from ar where id = old.id;
  end if;
  if TG_RELNAME = ''ap'' then
    select into t_curr, t_transdate curr, transdate from ap where id = old.id;
  end if;
  if TG_RELNAME = ''oe'' then
    select into t_curr, t_transdate curr, transdate from oe where id = old.id;
  end if;

  if d_curr != t_curr then

    select into t_id a.id from acc_trans ac
    join ar a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate

    except select a.id from ar a where a.id = old.id
    
    union
    
    select a.id from acc_trans ac
    join ap a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate
    
    except select a.id from ap a where a.id = old.id
    
    union
    
    select o.id from oe o
    where o.curr = t_curr
    and o.transdate = t_transdate
    
    except select o.id from oe o where o.id = old.id;

    if not found then
      delete from exchangerate where curr = t_curr and transdate = t_transdate;
    end if;
  end if;
return old;

end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE TRIGGER del_exchangerate BEFORE DELETE ON oe FOR EACH ROW EXECUTE PROCEDURE del_exchangerate();
-- end trigger
--
CREATE FUNCTION check_inventory() RETURNS TRIGGER AS '

declare
  itemid int;
  row_data inventory%rowtype;

begin

  if not old.quotation then
    for row_data in select * from inventory where trans_id = old.id loop
      select into itemid id from orderitems where trans_id = old.id and id = row_data.orderitems_id;

      if itemid is null then
	delete from inventory where trans_id = old.id and orderitems_id = row_data.orderitems_id;
      end if;
    end loop;
  end if;
return old;
end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER check_inventory AFTER UPDATE ON oe FOR EACH ROW EXECUTE PROCEDURE check_inventory();
-- end trigger
--
--
CREATE FUNCTION check_department() RETURNS TRIGGER AS '

declare
  dpt_id int;

begin
 
  if new.department_id = 0 then
    delete from dpt_trans where trans_id = new.id;
    return NULL;
  end if;

  select into dpt_id trans_id from dpt_trans where trans_id = new.id;
  
  if dpt_id > 0 then
    update dpt_trans set department_id = new.department_id where trans_id = dpt_id;
  else
    insert into dpt_trans (trans_id, department_id) values (new.id, new.department_id);
  end if;
return NULL;

end;
' language 'plpgsql';
-- end function
--
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ar FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON ap FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON gl FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
CREATE TRIGGER check_department AFTER INSERT OR UPDATE ON oe FOR EACH ROW EXECUTE PROCEDURE check_department();
-- end trigger
--
CREATE FUNCTION del_recurring() RETURNS TRIGGER AS '
BEGIN
  DELETE FROM recurring WHERE id = old.id;
  DELETE FROM recurringemail WHERE id = old.id;
  DELETE FROM recurringprint WHERE id = old.id;
  RETURN NULL;
END;
' language 'plpgsql';
--end function
CREATE TRIGGER del_recurring AFTER DELETE ON ar FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
CREATE TRIGGER del_recurring AFTER DELETE ON ap FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
CREATE TRIGGER del_recurring AFTER DELETE ON gl FOR EACH ROW EXECUTE PROCEDURE del_recurring();
-- end trigger
--
CREATE FUNCTION avgcost(int) RETURNS FLOAT AS '

DECLARE

v_cost float;
v_qty float;
v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost, v_qty SUM(i.sellprice * i.qty), SUM(i.qty)
  FROM invoice i
  JOIN ap a ON (a.id = i.trans_id)
  WHERE i.parts_id = v_parts_id;
  
  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

  IF NOT v_qty IS NULL THEN
    IF v_qty = 0 THEN
      v_cost := 0;
    ELSE
      v_cost := v_cost/v_qty;
    END IF;
  END IF;

RETURN v_cost;
END;
' language 'plpgsql';
-- end function
--
CREATE FUNCTION lastcost(int) RETURNS FLOAT AS '

DECLARE

v_cost float;
v_parts_id alias for $1;

BEGIN

  SELECT INTO v_cost sellprice FROM invoice i
  JOIN ap a ON (a.id = i.trans_id)
  WHERE i.parts_id = v_parts_id
  ORDER BY a.transdate desc, a.id desc
  LIMIT 1;

  IF v_cost IS NULL THEN
    v_cost := 0;
  END IF;

RETURN v_cost;
END;
' language plpgsql;
-- end function
--

CREATE OR REPLACE FUNCTION trigger_parts_short() RETURNS TRIGGER
AS
'
BEGIN
  IF NEW.onhand >= NEW.rop THEN
    NOTIFY parts_short;
  END IF;
  RETURN NEW;
END;
' LANGUAGE PLPGSQL;
-- end function

CREATE TRIGGER parts_short AFTER UPDATE ON parts 
FOR EACH ROW EXECUTE PROCEDURE trigger_parts_short();
-- end function

CREATE OR REPLACE FUNCTION add_custom_field (VARCHAR, VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
new_field_name ALIAS FOR $2;
field_datatype ALIAS FOR $3;

BEGIN
	EXECUTE ''SELECT TABLE_ID FROM custom_table_catalog 
		WHERE extends = '''''' || table_name || '''''' '';
	IF NOT FOUND THEN
		BEGIN
			INSERT INTO custom_table_catalog (extends) 
				VALUES (table_name);
			EXECUTE ''CREATE TABLE custom_''||table_name || 
				'' (row_id INT PRIMARY KEY)'';
		EXCEPTION WHEN duplicate_table THEN
			-- do nothing
		END;
	END IF;
	EXECUTE ''INSERT INTO custom_field_catalog (field_name, table_id)
	VALUES ( '''''' || new_field_name ||'''''', (SELECT table_id FROM custom_table_catalog
		WHERE extends = ''''''|| table_name || ''''''))'';
	EXECUTE ''ALTER TABLE custom_''||table_name || '' ADD COLUMN '' 
		|| new_field_name || '' '' || field_datatype;
	RETURN TRUE;
END;
' LANGUAGE PLPGSQL;
-- end function

CREATE OR REPLACE FUNCTION drop_custom_field (VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
custom_field_name ALIAS FOR $2;
BEGIN
	DELETE FROM custom_field_catalog 
	WHERE field_name = custom_field_name AND 
		table_id = (SELECT table_id FROM custom_table_catalog 
			WHERE extends = table_name);
	EXECUTE ''ALTER TABLE custom_'' || table_name || 
		'' DROP COLUMN '' || custom_field_name;
	RETURN TRUE;	
END;
' LANGUAGE PLPGSQL;
-- end function
commit;
