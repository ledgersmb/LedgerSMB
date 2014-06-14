-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- These will be cleaned up going back no more than one beta.

-- Chris Travers

update defaults set value='yes' where setting_key='module_load_ok';

-- THIS MUST ALWAYS RUN FOR WEB SERVICES TO WORK. IT IS NOT A FIX

update entity_credit_account set ar_ap_account_id = (select min(account_id) from account_link where description='AP' where ar_ap_account_id is null AND entity_class=1;
update entity_credit_account set ar_ap_account_id = (select min(account_id) from account_link where description='AR' where ar_ap_account_id is null AND entity_class=2;

-- Beta 4 fixes below

BEGIN;
INSERT INTO defaults VALUES ('show_creditlimit', '1');
COMMIT;

BEGIN;
ALTER TABLE cr_report ADD max_ac_id int references acc_trans(entry_id);
COMMIT;

BEGIN;
INSERT INTO defaults VALUES ('disable_back', '0');
COMMIT;

BEGIN;
UPDATE voucher SET batch_class = 2 WHERE batch_class = 1 AND trans_id IN
(SELECT id FROM ar);
COMMIT;

BEGIN;
ALTER TABLE batch DROP CONSTRAINT "batch_locked_by_fkey";
ALTER TABLE batch ADD FOREIGN KEY (locked_by) REFERENCES session(session_id)
ON DELETE SET NULL;
COMMIT;

-- POST-BETA-5 FIXES

BEGIN;
INSERT INTO file_class (id, class) values (6, 'internal'), (7, 'incoming');
COMMIT;

BEGIN;
CREATE TABLE file_internal (
   check (file_class = 6),
   unique(id),
   primary key (ref_key, file_name, file_class),
   check (ref_key = 0)
) inherits (file_base);

COMMENT ON COLUMN file_internal.ref_key IS
$$ Always must be 0, and we have no primary key since these files all
are for internal use and against the company, not categorized.$$;

COMMENT ON TABLE file_internal IS
$$ This is for internal files used operationally by LedgerSMB.  For example,
company logos would be here.$$;

CREATE TABLE file_incoming (
   check (file_class = 7),
   unique(id),
   primary key (ref_key, file_name, file_class),
   check (ref_key = 0) 
) inherits (file_base);


COMMENT ON COLUMN file_incoming.ref_key IS
$$ Always must be 0, and we have no primary key since these files all
are for interal incoming use, not categorized.$$;

COMMENT ON TABLE file_incoming IS
$$ This is essentially a spool for files to be reviewed and attached.  It is 
important that the names are somehow guaranteed to be unique, so one may want to prepend them with an email equivalent or the like.$$;

COMMIT;
BEGIN;
CREATE SEQUENCE lot_tracking_number;
CREATE TABLE mfg_lot (
    id serial not null unique,
    lot_number text not null unique default nextval('lot_tracking_number')::text,
    parts_id int not null references parts(id),
    qty numeric not null,
    stock_date date not null default now()::date
);

COMMENT ON TABLE mfg_lot IS 
$$ This tracks assembly restocks.  This is designed to work with old code and
may change as we refactor the parts.$$;
    
CREATE TABLE mfg_lot_item (
    id serial not null unique,
    mfg_lot_id int not null references mfg_lot(id),
    parts_id int not null references parts(id),
    qty numeric not null
);

COMMENT ON TABLE mfg_lot_item IS
$$ This tracks items used in assembly restocking.$$;

COMMIT;

BEGIN;

ALTER TABLE invoice ALTER COLUMN allocated TYPE NUMERIC;

COMMIT;
