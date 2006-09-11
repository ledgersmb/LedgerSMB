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
COMMIT;

