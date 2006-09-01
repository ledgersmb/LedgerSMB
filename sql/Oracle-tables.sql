-- Oracle-tables.sql
-- Paulo Rodrigues: added functions and triggers, Oct. 31, 2001
-- 
-- Modified for use with SL 2.0 and Oracle 9i2, Dec 13, 2002
-- Updated to 2.3.0, Dec 18, 2003
--
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
--
CREATE SEQUENCE id START WITH 10000 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT ID.NEXTVAL FROM DUAL;
--
CREATE SEQUENCE invoiceid START WITH 1 INCREMENT BY 1 MAXVALUE 2147483647 MINVALUE 1  CACHE 2;
SELECT INVOICEID.NEXTVAL FROM DUAL;
--
CREATE TABLE makemodel (
  parts_id INTEGER,
  make VARCHAR2(64),
  model VARCHAR2(64)
);
--
CREATE TABLE gl (
  id INTEGER,
  reference VARCHAR2(50),
  description VARCHAR2(100),
  transdate DATE DEFAULT SYSDATE,
  employee_id INTEGER,
  notes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0
);
--
CREATE TABLE chart (
  id INTEGER,
  accno VARCHAR2(20) NOT NULL,
  description VARCHAR2(100),
  charttype CHAR(1) DEFAULT 'A',
  category CHAR(1),
  link VARCHAR2(100),
  gifi_accno VARCHAR2(20)
);
--
CREATE TABLE gifi (
  accno VARCHAR2(20),
  description VARCHAR2(100)
);
--
CREATE TABLE defaults (
  inventory_accno_id INTEGER,
  income_accno_id INTEGER,
  expense_accno_id INTEGER,
  fxgain_accno_id INTEGER,
  fxloss_accno_id INTEGER,
  invnumber VARCHAR2(30),
  sonumber VARCHAR2(30),
  yearend VARCHAR2(5),
  weightunit VARCHAR2(5),
  businessnumber VARCHAR2(30),
  version VARCHAR2(8),
  curr VARCHAR2(500),
  closedto DATE,
  revtrans CHAR(1) DEFAULT '0',
  ponumber VARCHAR2(30),
  sqnumber VARCHAR2(30),
  rfqnumber VARCHAR2(30)
);
INSERT INTO defaults (version) VALUES ('2.3.0');
--
CREATE TABLE acc_trans (
  trans_id INTEGER,
  chart_id INTEGER,
  amount FLOAT,
  transdate DATE DEFAULT SYSDATE,
  source VARCHAR2(20),
  cleared CHAR(1) DEFAULT '0',
  fx_transaction CHAR(1) DEFAULT '0',
  project_id INTEGER
);
--
CREATE TABLE invoice (
  id INTEGER,
  trans_id INTEGER,
  parts_id INTEGER,
  description VARCHAR2(4000),
  qty FLOAT,
  allocated FLOAT,
  sellprice FLOAT,
  fxsellprice FLOAT,
  discount FLOAT,
  assemblyitem CHAR(1) DEFAULT '0',
  unit VARCHAR2(5),
  project_id INTEGER,
  deliverydate DATE,
  serialnumber VARCHAR2(200)
);
--
CREATE TABLE vendor (
  id INTEGER,
  name VARCHAR2(35),
  addr1 VARCHAR2(35),
  addr2 VARCHAR2(35),
  addr3 VARCHAR2(35),
  addr4 VARCHAR2(35),
  contact VARCHAR2(35),
  phone VARCHAR2(20),
  fax VARCHAR2(20),
  email VARCHAR2(50),
  notes VARCHAR2(4000),
  terms INTEGER DEFAULT 0,
  taxincluded CHAR(1),
  vendornumber VARCHAR2(40),
  cc VARCHAR2(50),
  bcc VARCHAR2(50)
);
--
CREATE TABLE customer (
  id INTEGER,
  name VARCHAR2(35),
  addr1 VARCHAR2(35),
  addr2 VARCHAR2(35),
  addr3 VARCHAR2(35),
  addr4 VARCHAR2(35),
  contact VARCHAR2(35),
  phone VARCHAR2(20),
  fax VARCHAR2(20),
  email VARCHAR2(50),
  notes VARCHAR2(4000),
  discount FLOAT,
  taxincluded CHAR(1),
  creditlimit FLOAT,
  terms INTEGER DEFAULT 0,
  customernumber VARCHAR2(40),
  cc VARCHAR2(50),
  bcc VARCHAR2(50)
);
--
CREATE TABLE parts (
  id INTEGER,
  partnumber VARCHAR2(30), 
  description VARCHAR2(4000),
  unit VARCHAR2(5),
  listprice FLOAT,
  sellprice FLOAT,
  lastcost FLOAT,
  priceupdate DATE DEFAULT SYSDATE,
  weight FLOAT,
  onhand FLOAT DEFAULT 0,
  notes VARCHAR2(4000),
  makemodel CHAR(1) DEFAULT '0',
  assembly CHAR(1) DEFAULT '0',
  alternate CHAR(1) DEFAULT '0',
  rop FLOAT,
  inventory_accno_id INTEGER,
  income_accno_id INTEGER,
  expense_accno_id INTEGER,
  bin VARCHAR2(20),
  obsolete CHAR(1) DEFAULT '0',
  bom CHAR(1) DEFAULT '0',
  image VARCHAR2(100),
  drawing VARCHAR2(100),
  microfiche VARCHAR2(100),
  partsgroup_id INTEGER
);
--
CREATE TABLE assembly (
  id INTEGER,
  parts_id INTEGER,
  qty FLOAT,
  bom char(1)
);
--
CREATE TABLE ar (
  id INTEGER,
  invnumber VARCHAR2(30),
  transdate DATE DEFAULT SYSDATE,
  customer_id INTEGER,
  taxincluded CHAR(1),
  amount FLOAT,
  netamount FLOAT,
  paid FLOAT,
  datepaid DATE,
  duedate DATE,
  invoice CHAR(1) DEFAULT '0',
  shippingpoint VARCHAR2(100),
  terms INTEGER DEFAULT 0,
  notes VARCHAR2(4000),
  curr CHAR(3),
  ordnumber VARCHAR2(30),
  employee_id INTEGER,
  till VARCHAR2(20),
  quonumber VARCHAR2(30),
  intnotes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0
);
--
CREATE TABLE ap (
  id INTEGER,
  invnumber VARCHAR2(30),
  transdate DATE DEFAULT SYSDATE,
  vendor_id INTEGER,
  taxincluded CHAR(1) DEFAULT '0',
  amount FLOAT,
  netamount FLOAT,
  paid FLOAT,
  datepaid DATE,
  duedate DATE,
  invoice CHAR(1) DEFAULT '0',
  ordnumber VARCHAR2(30),
  curr CHAR(3),
  notes VARCHAR2(4000),
  employee_id INTEGER,
  till VARCHAR2(20),
  quonumber VARCHAR2(30),
  intnotes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0
);
--
CREATE TABLE partstax (
  parts_id INTEGER,
  chart_id INTEGER
);
--
CREATE TABLE tax (
  chart_id INTEGER,
  rate FLOAT,
  taxnumber VARCHAR2(30)
);
--
CREATE TABLE customertax (
  customer_id INTEGER,
  chart_id INTEGER
);
--
CREATE TABLE vendortax (
  vendor_id INTEGER,
  chart_id INTEGER
);
--
CREATE TABLE oe (
  id INTEGER,
  ordnumber VARCHAR2(30),
  transdate DATE DEFAULT SYSDATE,
  vendor_id INTEGER,
  customer_id INTEGER,
  amount FLOAT,
  netamount FLOAT,
  reqdate DATE,
  taxincluded CHAR(1),
  shippingpoint VARCHAR2(100),
  notes VARCHAR2(4000),
  curr CHAR(3),
  employee_id INTEGER,
  closed CHAR(1) DEFAULT '0',
  quotation CHAR(1) DEFAULT '0',
  quonumber VARCHAR2(30),
  intnotes VARCHAR2(4000),
  department_id INTEGER DEFAULT 0
);
--
CREATE TABLE orderitems (
  trans_id INTEGER,
  parts_id INTEGER,
  description VARCHAR2(4000),
  qty FLOAT,
  sellprice FLOAT,
  discount FLOAT,
  unit VARCHAR2(5),
  project_id INTEGER,
  reqdate DATE
);
--
CREATE TABLE exchangerate (
  curr CHAR(3),
  transdate DATE,
  buy FLOAT,
  sell FLOAT
);
--
CREATE TABLE employee (
  id INTEGER,
  login VARCHAR2(20),
  name VARCHAR2(35),
  addr1 VARCHAR2(35),
  addr2 VARCHAR2(35),
  addr3 VARCHAR2(35),
  addr4 VARCHAR2(35),
  workphone VARCHAR2(20),
  homephone VARCHAR2(20),
  startdate DATE DEFAULT SYSDATE,
  enddate DATE,
  notes VARCHAR2(4000),
  role VARCHAR2(30)
);
--
CREATE TABLE shipto (
  trans_id INTEGER,
  shiptoname VARCHAR2(35),
  shiptoaddr1 VARCHAR2(35),
  shiptoaddr2 VARCHAR2(35),
  shiptoaddr3 VARCHAR2(35),
  shiptoaddr4 VARCHAR2(35),
  shiptocontact VARCHAR2(35),
  shiptophone VARCHAR2(20),
  shiptofax VARCHAR2(20),
  shiptoemail VARCHAR2(50)
);
--
CREATE TABLE project (
  id INTEGER,
  projectnumber VARCHAR2(50),
  description VARCHAR2(4000)
);
--
CREATE TABLE partsgroup (
  id INTEGER,
  partsgroup VARCHAR2(100)
);
--
CREATE TABLE status (
  trans_id INTEGER,
  formname VARCHAR2(30),
  printed CHAR(1) DEFAULT 0,
  emailed CHAR(1) DEFAULT 0,
  spoolfile VARCHAR2(20),
  chart_id INTEGER
);
--
CREATE TABLE department (
  id INTEGER,
  description VARCHAR2(100),
  role CHAR(1) DEFAULT 'P'
);
--
-- functions
--
CREATE OR REPLACE FUNCTION current_date RETURN date AS
BEGIN
  return(sysdate);--
END;;
--
-- triggers
--
CREATE OR REPLACE TRIGGER glid BEFORE INSERT ON gl FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER chartid BEFORE INSERT ON chart FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER invoiceid BEFORE INSERT ON invoice FOR EACH ROW
BEGIN
  SELECT invoiceid.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER vendorid BEFORE INSERT ON vendor FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER customerid BEFORE INSERT ON customer FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER partsid BEFORE INSERT ON parts FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER arid BEFORE INSERT ON ar FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER apid BEFORE INSERT ON ap FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER oeid BEFORE INSERT ON oe FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER employeeid BEFORE INSERT ON employee FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER projectid BEFORE INSERT ON project FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
  FROM DUAL;--
END;;
--
CREATE OR REPLACE TRIGGER partsgroupid BEFORE INSERT ON partsgroup FOR EACH ROW
BEGIN
  SELECT id.nextval
  INTO :new.id
FROM DUAL;--
END;;
--
