
BEGIN;
ALTER SCHEMA public RENAME TO lsmb_14fail;
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

\echo Note that this creates a lsmb_14fail schema with the failed migration data.
\echo You must drop that schema when you are done troubleshooting why this failed.
\echo Otherwise you will be unable to roll back after then next upgrade attempt.
