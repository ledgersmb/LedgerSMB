begin;
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

CREATE TABLE transactions (
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
  id int DEFAULT nextval ( 'invoiceid' ) PRIMARY KEY,
  trans_id int,
  parts_id int,
  description text,
  qty NUMERIC,
  allocated NUMERIC,
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
create index ap_vendor_id_key on ap (vendor_id);
create index ap_employee_id_key on ap (employee_id);
create index ap_quonumber_key on ap (quonumber);
--
create index ar_id_key on ar (id);
create index ar_transdate_key on ar (transdate);
create index ar_invnumber_key on ar (invnumber);
create index ar_ordnumber_key on ar (ordnumber);
create index ar_customer_id_key on ar (customer_id);
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
create index vendortax_vendor_id_key on vendortax (vendor_id);
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
create index partsvendor_vendor_id_key on partsvendor (vendor_id);
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
CREATE FUNCTION avgcost(int) RETURNS NUMERIC AS '

DECLARE

v_cost numeric;
v_qty numeric;
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
CREATE FUNCTION lastcost(int) RETURNS numeric AS '

DECLARE

v_cost numeric;
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
