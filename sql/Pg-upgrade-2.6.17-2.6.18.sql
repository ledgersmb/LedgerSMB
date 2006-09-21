ALTER TABLE chart ADD PRIMARY KEY (id);
-- linuxpoet:
-- adding primary key to acc_trans
-- We are using standard postgresql names for the sequence for consistency as we move forward
-- Do everything in a transaction in case it blows up

LOCK acc_trans in EXCLUSIVE mode;
ALTER TABLE acc_trans ADD COLUMN entry_id bigint;
CREATE SEQUENCE acctrans_entry_id_seq;
ALTER TABLE acc_trans ALTER COLUMN entry_id SET DEFAULT nextval('acctrans_entry_id_seq');
UPDATE acc_trans SET entry_id = nextval('acctrans_entry_id_seq');
ALTER TABLE acc_trans ADD PRIMARY key (entry_id);

-- We should probably add a foreign key to chart.id
ALTER TABLE acc_trans ADD FOREIGN KEY (chart_id) REFERENCES chart (id);

-- Start changing floats
ALTER TABLE acc_trans ALTER COLUMN amount TYPE NUMERIC;

-- This may break someone if they for some reason have an actual float type in the qty column
ALTER TABLE invoice ALTER COLUMN qty TYPE numeric;

ALTER TABLE invoice ALTER COLUMN allocated TYPE numeric;
ALTER TABLE invoice ALTER COLUMN sellprice TYPE NUMERIC;
ALTER TABLE invoice ALTER COLUMN fxsellprice TYPE NUMERIC;

ALTER TABLE customer ALTER COLUMN discount TYPE numeric;
ALTER TABLE customer ALTER COLUMN creditlimit TYPE NUMERIC;

ALTER TABLE parts ALTER COLUMN listprice TYPE NUMERIC;
ALTER TABLE parts ALTER COLUMN sellprice TYPE NUMERIC;
ALTER TABLE parts ALTER COLUMN lastcost TYPE NUMERIC;
ALTER TABLE parts ALTER COLUMN weight TYPE numeric;
ALTER TABLE parts ALTER COLUMN onhand TYPE numeric;
ALTER TABLE parts ALTER COLUMN avgcost TYPE NUMERIC;

ALTER TABLE assembly ALTER COLUMN qty TYPE numeric;

ALTER TABLE ar ALTER COLUMN amount TYPE NUMERIC;
ALTER TABLE ar ALTER COLUMN netamount TYPE NUMERIC;
ALTER TABLE ar ALTER COLUMN paid TYPE NUMERIC;

ALTER TABLE ap ALTER COLUMN amount TYPE NUMERIC;
ALTER TABLE ap ALTER COLUMN netamount TYPE NUMERIC;
ALTER TABLE ap ALTER COLUMN paid TYPE NUMERIC;

ALTER TABLE tax ALTER COLUMN rate TYPE numeric;

ALTER TABLE oe ALTER COLUMN amount TYPE NUMERIC;
ALTER TABLE oe ALTER COLUMN netamount TYPE NUMERIC;

ALTER TABLE orderitems ALTER COLUMN qty TYPE numeric;
ALTER TABLE orderitems ALTER COLUMN sellprice TYPE NUMERIC;
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

ALTER TABLE partsvendor ALTER COLUMN lastcost TYPE NUMERIC;

ALTER TABLE partscustomer ALTER COLUMN pricebreak TYPE numeric;
ALTER TABLE partscustomer ALTER COLUMN sellprice TYPE NUMERIC;

ALTER TABLE jcitems ALTER COLUMN qty TYPE numeric;
ALTER TABLE jcitems ALTER COLUMN allocated TYPE numeric;
ALTER TABLE jcitems ALTER COLUMN sellprice TYPE NUMERIC;
ALTER TABLE jcitems ALTER COLUMN fxsellprice TYPE NUMERIC;

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

create table transactions (
  id int PRIMARY KEY,
  table_name text
);

insert into transactions (id, table_name) SELECT id, 'ap' FROM ap;

CREATE RULE ap_id_track_i AS ON insert TO ap 
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'ap');

CREATE RULE ap_id_track_u AS ON update TO ap 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

insert into transactions (id, table_name) SELECT id, 'ar' FROM ar;

CREATE RULE ar_id_track_i AS ON insert TO ar 
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'ar');

CREATE RULE ar_id_track_u AS ON update TO ar 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'business' FROM business;

CREATE RULE business_id_track_i AS ON insert TO business 
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'business');

CREATE RULE business_id_track_u AS ON update TO business 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'chart' FROM chart;

CREATE RULE chart_id_track_i AS ON insert TO chart 
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'chart');

CREATE RULE chart_id_track_u AS ON update TO chart 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'customer' FROM customer;

CREATE RULE customer_id_track_i AS ON insert TO customer
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'customer');

CREATE RULE customer_id_track_u AS ON update TO customer 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'department' FROM department;

CREATE RULE department_id_track_i AS ON insert TO department
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'department');

CREATE RULE department_id_track_u AS ON update TO department 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'employee' FROM employee;

CREATE RULE employee_id_track_i AS ON insert TO employee
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'employee');

CREATE RULE employee_id_track_u AS ON update TO employee
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'gl' FROM gl;

CREATE RULE gl_id_track_i AS ON insert TO gl
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'gl');

CREATE RULE gl_id_track_u AS ON update TO gl 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'oe' FROM oe;

CREATE RULE oe_id_track_i AS ON insert TO oe
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'oe');

CREATE RULE oe_id_track_u AS ON update TO oe 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'parts' FROM parts;

CREATE RULE parts_id_track_i AS ON insert TO parts
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'parts');

CREATE RULE parts_id_track_u AS ON update TO parts 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'partsgroup' FROM partsgroup;

CREATE RULE partsgroup_id_track_i AS ON insert TO partsgroup
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'partsgroup');

CREATE RULE partsgroup_id_track_u AS ON update TO partsgroup 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'pricegroup' FROM pricegroup;

CREATE RULE pricegroup_id_track_i AS ON insert TO pricegroup
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'pricegroup');

CREATE RULE pricegroup_id_track_u AS ON update TO pricegroup 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'project' FROM project;

CREATE RULE project_id_track_i AS ON insert TO project
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'project');

CREATE RULE project_id_track_u AS ON update TO project 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'vendor' FROM vendor;

CREATE RULE vendor_id_track_i AS ON insert TO vendor
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'vendor');

CREATE RULE employee_id_track_u AS ON update TO vendor 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;

INSERT INTO transactions (id, table_name) SELECT id, 'warehouse' FROM warehouse;

CREATE RULE warehouse_id_track_i AS ON insert TO warehouse
DO ALSO INSERT INTO transactions (id, table_name) VALUES (new.id, 'employee');

CREATE RULE warehouse_id_track_u AS ON update TO warehouse 
DO ALSO UPDATE transactions SET id = new.id WHERE id = old.id;


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
			INSERT INTO custom_table_catalog (extends) VALUES (table_name);
			EXECUTE ''CREATE TABLE custom_''||table_name || 
				'' (row_id INT)'';
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

UPDATE defaults SET version = '2.6.18';
