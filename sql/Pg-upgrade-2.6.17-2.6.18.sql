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
COMMIT;

