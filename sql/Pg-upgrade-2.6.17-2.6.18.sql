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

