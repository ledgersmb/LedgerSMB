-- linuxpoet:
-- adding primary key to acc_trans
-- We are using standard postgresql names for the sequence for consistency as we move forward
-- Do everything in a transaction in case it blows up

BEGIN;
LOCK acc_trans in EXCLUSIVE mode;
ALTER TABLE acc_trans ADD COLUMN entry_id bigint;
CREATE SEQUENCE acctrans_entry_id_seq;
ALTER TABLE acc_trans ALTER COLUMN entry_id SET DEFAULT nextval('acctrans_entry_id_seq');
UPDATE acc_trans SET entry_id = nextval('acctrans_entry_id_seq');
ALTER TABLE acc_trans ADD PRIMARY key (entry_id);

-- Start changing floats
ALTER TABLE acc_trans ALTER COLUMN amount TYPE numeric(10,2);

-- This may break someone if they for some reason have an actual float type in the qty column
ALTER TABLE invoice ALTER COLUMN qty TYPE numeric;

ALTER TABLE invoice ALTER COLUMN allocated TYPE numeric;
ALTER TABLE invoice ALTER COLUMN sellprice TYPE numeric(10,2);
ALTER TABLE invoice ALTER COLUMN fxsellprice TYPE numeric(10,2);

ALTER TABLE customer ALTER COLUMN discount TYPE numeric;
ALTER TABLE customer ALTER COLUMN creditlimit TYPE numeric(10,2);

ALTER TABLE parts ALTER COLUMN listprice TYPE numeric(10,2);
ALTER TABLE parts ALTER COLUMN sellprice TYPE numeric(10,2);
ALTER TABLE parts ALTER COLUMN lastcost TYPE numeric(10,2);
ALTER TABLE parts ALTER COLUMN weight TYPE numeric;
ALTER TABLE parts ALTER COLUMN onhand TYPE numeric;
ALTER TABLE parts ALTER COLUMN avgcost TYPE numeric(10,2);

ALTER TABLE assembly ALTER COLUMN qty TYPE numeric;

ALTER TABLE ar ALTER COLUMN amount TYPE numeric(10,2);
ALTER TABLE ar ALTER COLUMN netamount TYPE numeric(10,2);
ALTER TABLE ar ALTER COLUMN paid TYPE numeric(10,2);

ALTER TABLE ap ALTER COLUMN amount TYPE numeric(10,2);
ALTER TABLE ap ALTER COLUMN netamount TYPE numeric(10,2);
ALTER TABLE ap ALTER COLUMN paid TYPE numeric(10,2);

ALTER TABLE tax ALTER COLUMN rate TYPE numeric;

ALTER TABLE oe ALTER COLUMN amount TYPE numeric(10,2);
ALTER TABLE oe ALTER COLUMN netamount TYPE numeric(10,2);

ALTER TABLE orderitems ALTER COLUMN qty TYPE numeric;
ALTER TABLE orderitems ALTER COLUMN sellprice TYPE numeric(10,2);
ALTER TABLE orderitems ALTER COLUMN discount TYPE numeric;
ALTER TABLE orderitems ALTER COLUMN ship TYPE numeric;

ALTER TABLE exchangerate ALTER COLUMN buy TYPE numeric;
ALTER TABLE exchangerate ALTER COLUMN sell TYPE numeric;

ALTER TABLE vendor ALTER COLUMN discount TYPE numeric;
ALTER TABLE vendor ALTER COLUMN creditlimit TYPE numeric; 

ALTER TABLE project ALTER COLUMN production TYPE numeric; 
ALTER TABLE project ALTER COLUMN completed TYPE numeric;

ALTER TABLE business ALTER COLUMN discount TYPE numeric;

ALTER TABLE inventory ALTER COLUMN qty TYPE numeric;

ALTER TABLE partsvendor ALTER COLUMN lastcost TYPE numeric(10,2);

ALTER TABLE partscustomer ALTER COLUMN pricebreak TYPE numeric;
ALTER TABLE partscustomer ALTER COLUMN sellprice TYPE numeric(10,2);

ALTER TABLE jcitems ALTER COLUMN qty TYPE numeric;
ALTER TABLE jcitems ALTER COLUMN allocated TYPE numeric;
ALTER TABLE jcitems ALTER COLUMN sellprice TYPE numeric(10,2);
ALTER TABLE jcitems ALTER COLUMN fxsellprice TYPE numeric(10,2);

-- The query rewrite rule necessary to notify the email app that a new report
-- needs to be sent to the designated administrator.
-- By Chris Travers
-- chris@metatrontech.com
-- Licensed under the GNU GPL 2.0 or later at your option.  See accompanying
-- GPL.txt

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

CREATE TRIGGER parts_short AFTER UPDATE ON parts 
FOR EACH ROW EXECUTE PROCEDURE trigger_parts_short();

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

COMMIT;

