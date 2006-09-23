--
CREATE TABLE newap (
  id int DEFAULT nextval ( 'id' ),
  invnumber text,
  transdate date DEFAULT current_date,
  vendor int,
  taxincluded bool DEFAULT FALSE,
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT FALSE,
  ordnumber text
);
--
INSERT INTO newap (id, invnumber, transdate, vendor, amount, netamount, paid,
datepaid, duedate, invoice, ordnumber)
SELECT id, invnumber, transdate, vendor, amount, netamount, paid,
datepaid, duedate, invoice, ordnumber
FROM ap;
--
DROP TABLE ap;
ALTER TABLE newap RENAME TO ap;
--
CREATE TABLE newar (
  id int DEFAULT nextval ( 'id' ),
  invnumber text,
  transdate date DEFAULT current_date,
  customer int,
  taxincluded bool DEFAULT FALSE,
  amount float,
  netamount float,
  paid float,
  datepaid date,
  duedate date,
  invoice bool DEFAULT FALSE,
  shippingpoint text,
  terms int2,
  notes text
);
--
INSERT INTO newar (id, invnumber, transdate, customer, amount, netamount, paid,
datepaid, duedate, invoice, shippingpoint, terms, notes)
SELECT id, invnumber, transdate, customer, amount, netamount, paid,
datepaid, duedate, invoice, shippingpoint, terms, notes
FROM ar;
--
DROP TABLE ar;
ALTER TABLE newar RENAME TO ar;
--
CREATE TABLE newcustomer (
  id int DEFAULT nextval ( 'id' ),
  name varchar(35),
  addr1 varchar(35),
  addr2 varchar(35),
  addr3 varchar(35),
  contact varchar(35),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  ytd float,
  discount float4,
  taxincluded bool,
  creditlimit float,
  terms int2,
  shiptoname varchar(35),
  shiptoaddr1 varchar(35),
  shiptoaddr2 varchar(35),
  shiptoaddr3 varchar(35),
  shiptocontact varchar(20),
  shiptophone varchar(20),
  shiptofax varchar(20),
  shiptoemail text
);
INSERT INTO newcustomer (
id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, ytd,
discount, creditlimit, terms, shiptoname, shiptoaddr1, shiptoaddr2,
shiptoaddr3, shiptocontact, shiptophone, shiptofax, shiptoemail )
SELECT id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, ytd,
discount, creditlimit, terms, shiptoname, shiptoaddr1, shiptoaddr2,
shiptoaddr3, shiptocontact, shiptophone, shiptofax, shiptoemail
FROM customer;
--
DROP TABLE customer;
ALTER TABLE newcustomer RENAME TO customer;
--
CREATE TABLE customertax (
  customer_id int,
  chart_id int
);
--
CREATE TABLE newdefaults (
  inventory_accno int,
  income_accno int,
  expense_accno int,
  invnumber text,
  ponumber text,
  yearend varchar(5),
  nativecurr varchar(3),
  weightunit varchar(5)
);
--
INSERT INTO newdefaults (
inventory_accno, income_accno, expense_accno, invnumber, ponumber)
SELECT inventory_accno, income_accno, expense_accno, invnumber, ponumber
FROM defaults;
--
DROP TABLE defaults;
ALTER TABLE newdefaults RENAME TO defaults;
UPDATE defaults SET yearend = '1/31', nativecurr = 'CAD', weightunit = 'kg';
--
CREATE TABLE partstax (
  parts_id int,
  chart_id int
);
--
CREATE TABLE tax (
  chart_id int,
  rate float,
  number text
);
--
CREATE TABLE newvendor (
  id int DEFAULT nextval ( 'id' ),
  name varchar(35),
  addr1 varchar(35),
  addr2 varchar(35),
  addr3 varchar(35),
  contact varchar(35),
  phone varchar(20),
  fax varchar(20),
  email text,
  notes text,
  ytd float,
  discount float4,
  taxincluded bool,
  creditlimit float,
  terms int2
);
--
INSERT INTO newvendor (
id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, ytd )
SELECT id, name, addr1, addr2, addr3, contact, phone, fax, email, notes, ytd
FROM vendor;
--
DROP TABLE vendor;
ALTER TABLE newvendor RENAME TO vendor;
--
CREATE TABLE vendortax (
  vendor_id int,
  chart_id int
);
--
ALTER TABLE chart RENAME TO oldchart;
--
CREATE TABLE chart (
  id int DEFAULT nextval( 'id' ),
  accno int UNIQUE,
  description text,
  balance float,
  type char(1),
  gifi int,
  category char(1),
  link text
);
--
INSERT INTO chart SELECT * FROM oldchart;
--
DROP TABLE oldchart;
--

