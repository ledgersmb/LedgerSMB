-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- Chris Travers

-- during 1.4m2
BEGIN; 

ALTER TABLE makemodel ADD barcode TEXT;

COMMIT;

BEGIN;
ALTER TABLE account ADD COLUMN is_temp BOOL NOT NULL DEFAULT FALSE;
COMMIT;

BEGIN;

CREATE TABLE lsmb_group (
     role_name text primary key
);

CREATE TABLE lsmb_group_grants (
     group_name text references lsmb_group(role_name),
     granted_role text,
     PRIMARY KEY (group_name, granted_role) 
);

COMMIT;
