-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- Chris Travers

-- during 1.4m2
BEGIN; 

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

BEGIN;
CREATE TABLE trial_balance__yearend_types (
    type text primary key
);
INSERT INTO trial_balance__yearend_types (type) 
     VALUES ('none'), ('all'), ('last');


CREATE TABLE trial_balance (
    id serial primary key,
    date_from date, 
    date_to date,
    description text NOT NULL,
    yearend text not null references trial_balance__yearend_types(type)
);

CREATE TABLE trial_balance__account_to_report (
    report_id int not null references trial_balance(id),
    account_id int not null references account(id)
);

CREATE TABLE trial_balance__heading_to_report (
    report_id int not null references trial_balance(id),
    heading_id int not null references account_heading(id)
);

CREATE TYPE trial_balance__entry AS (
    id int,
    date_from date,
    date_to date,
    description text,
    yearend text,
    heading_id int,
    accounts int[]
);

ALTER TABLE cr_report_line ADD FOREIGN KEY(ledger_id) REFERENCES acc_trans(entry_id);

COMMIT;


