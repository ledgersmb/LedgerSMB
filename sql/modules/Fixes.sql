-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- These will be cleaned up going back no more than one beta.

-- Chris Travers

update defaults set value='yes' where setting_key='module_load_ok';

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

BEGIN;
ALTER TABLE entity_employee ADD is_manager bool DEFAULT FALSE;
UPDATE entity_employee SET is_manager = true WHERE role = 'manager';

COMMIT;

BEGIN;
update acc_trans 
   set transdate = (select transdate 
                      from (select id, transdate from ar
                             union
                            select id, transdate from ap
                             union
                            select id, transdate from gl
                            ) gl 
                     where gl.id = acc_trans.trans_id
                           and not exists (select 1 from account_checkpoint cp
                                             where end_date > gl.transdate)
                   ) 
 where transdate is null;
COMMIT;

-- Removing batch printing menu options
BEGIN;

DELETE FROM menu_acl 
 WHERE node_id IN (select node_id from menu_attribute 
                    where attribute = 'module' and value = 'bp.pl');
DELETE FROM menu_attribute 
 WHERE node_id IN (select node_id from menu_attribute 
                    where attribute = 'module' and value = 'bp.pl');
DELETE FROM menu_node 
 WHERE id NOT IN (select node_id from menu_attribute);

DELETE FROM menu_acl
 WHERE node_id IN (select node_id from menu_attribute
                    where attribute = 'menu' and node_id not in
                          (select parent from menu_node));

DELETE FROM menu_attribute
 WHERE node_id IN (select node_id from menu_attribute
                    where attribute = 'menu' and node_id not in
                          (select parent from menu_node));
DELETE FROM menu_node 
 WHERE id NOT IN (select node_id from menu_attribute);
COMMIT;
