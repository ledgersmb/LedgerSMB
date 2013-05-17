-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- These will be cleaned up going back no more than one beta.

-- Chris Travers

-- during 1.4m2

-- BETA 1

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

BEGIN;

ALTER TABLE file_transaction DROP CONSTRAINT  "file_transaction_ref_key_fkey";
ALTER TABLE file_transaction ADD FOREIGN KEY (ref_key) REFERENCES transactions(id);

COMMIT;

BEGIN;

ALTER TABLE country_tax_form ADD is_accrual bool not null default false;

COMMIT;

BEGIN;

DROP VIEW IF EXISTS cash_impact;
CREATE VIEW cash_impact AS
SELECT id, '1'::numeric AS portion, 'gl' as rel, gl.transdate FROM gl
UNION ALL
SELECT id, CASE WHEN gl.amount = 0 THEN 0 -- avoid div by 0
                WHEN gl.transdate = ac.transdate
                     THEN 1 + sum(ac.amount) / gl.amount
                ELSE 
                     1 - (gl.amount - sum(ac.amount)) / gl.amount
                END , 'ar' as rel, ac.transdate
  FROM ar gl
  JOIN acc_trans ac ON ac.trans_id = gl.id
  JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AR'
 GROUP BY gl.id, gl.amount, ac.transdate
UNION ALL
SELECT id, CASE WHEN gl.amount = 0 THEN 0
                WHEN gl.transdate = ac.transdate
                     THEN 1 - sum(ac.amount) / gl.amount
                ELSE 
                     1 - (gl.amount + sum(ac.amount)) / gl.amount
            END, 'ap' as rel, ac.transdate
  FROM ap gl
  JOIN acc_trans ac ON ac.trans_id = gl.id
  JOIN account_link al ON ac.chart_id = al.account_id and al.description = 'AP'
 GROUP BY gl.id, gl.amount, ac.transdate;

COMMENT ON VIEW cash_impact IS
$$ This view is used by cash basis reports to determine the fraction of a
transaction to be counted.$$;
COMMIT;

BEGIN;

ALTER TABLE payrol_deduction_class ADD stored_proc_name name not null;

COMMIT;

BEGIN; -- Timecard types

CREATE TABLE jctype (
  id int not null unique, -- hand assigned
  label text primary key,
  description text not null,
  is_service bool default true,
  is_timecard bool default true
);

INSERT INTO jctype (id, label, description, is_service, is_timecard)
VALUES (1, 'time', 'Timecards for project services', true, true);

INSERT INTO jctype (id, label, description, is_service, is_timecard)
VALUES (2, 'materials', 'Materials for projects', false, false);

INSERT INTO jctype (id, label, description, is_service, is_timecard)
VALUES (3, 'overhead', 'Time/Overhead for payroll, manufacturing, etc', false, true);

COMMIT;

-- BETA 2
BEGIN;

ALTER TABLE tax_extended DROP CONSTRAINT "tax_extended_entry_id_fkey";

ALTER TABLE tax_extended ADD FOREIGN KEY (entry_id) 
REFERENCES acc_trans(entry_id);

COMMIT;

BEGIN;

ALTER TABLE inventory_report_line add adjust_id int not null;

 alter table inventory_report_line add variance numeric not null;


COMMIT;

BEGIN;

--- EDI contact fixes


INSERT INTO contact_class (id,class) values (18,'EDI Interchange ID');
INSERT INTO contact_class (id,class) values (19,'EDI ID');

SELECT SETVAL('contact_class_id_seq',19);

COMMIT;

BEGIN;

ALTER TABLE asset_report DROP CONSTRAINT "asset_report_gl_id_fkey";
ALTER TABLE asset_report ADD FOREIGN KEY gl_id REFERENCES gl(id);

ALTER TABLE file_order_to_tx DROP CONSTRAINT "file_order_to_tx_ref_key_fkey";
ALTER TABLE file_order_to_tx ADD FOREIGN KEY ref_key REFERENCES gl(id);

COMMIT;

BEGIN;
CREATE INDEX menu_acl_node_id_idx ON menu_acl (node_id);
COMMIT;
