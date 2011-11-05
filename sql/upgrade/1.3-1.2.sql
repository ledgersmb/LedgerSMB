
BEGIN;
ALTER SCHEMA public RENAME TO lsmb_13fail;
ALTER SCHEMA lsmb12 RENAME TO public;
COMMIT;


ALTER TABLE lsmb12.vendor DROP COLUMN entity_id;
ALTER TABLE lsmb12.vendor DROP COLUMN company_id;
ALTER TABLE lsmb12.vendor DROP COLUMN credit_id;

ALTER TABLE lsmb12.customer DROP COLUMN entity_id;
ALTER TABLE lsmb12.customer DROP COLUMN company_id;
ALTER TABLE lsmb12.customer DROP COLUMN credit_id;

ALTER TABLE lsmb12.employee DROP COLUMN entity_id;
