
BEGIN;
ALTER SCHEMA public RENAME TO lsmb_13fail;
ALTER SCHEMA lsmb12 RENAME TO public;
COMMIT;

BEGIN;
ALTER TABLE vendor DROP COLUMN entity_id;
ALTER TABLE vendor DROP COLUMN company_id;
ALTER TABLE vendor DROP COLUMN credit_id;

ALTER TABLE customer DROP COLUMN entity_id;
ALTER TABLE customer DROP COLUMN company_id;
ALTER TABLE customer DROP COLUMN credit_id;

ALTER TABLE employee DROP COLUMN entity_id;
COMMIT;
