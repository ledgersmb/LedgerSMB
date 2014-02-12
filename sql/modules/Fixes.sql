-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- These will be cleaned up going back no more than one beta.

-- Chris Travers

BEGIN;

ALTER TABLE asset_report DROP CONSTRAINT "asset_report_gl_id_fkey";
ALTER TABLE asset_report ADD  CONSTRAINT "asset_report_gl_id_fkey" FOREIGN KEY (gl_id) REFERENCES gl(id);

ALTER TABLE file_order_to_tx DROP CONSTRAINT "file_order_to_tx_ref_key_fkey";
ALTER TABLE file_order_to_tx ADD CONSTRAINT "file_order_to_tx_ref_key_fkey" FOREIGN KEY (ref_key) REFERENCES gl(id);

COMMIT;

BEGIN;
CREATE INDEX menu_acl_node_id_idx ON menu_acl (node_id);
COMMIT;

BEGIN;

alter table business_unit_oitem 
drop constraint business_unit_oitem_entry_id_fkey;

alter table business_unit_oitem 
add foreign key (entry_id) references orderitems(id) on delete cascade;

COMMIT;

-- Required for parameter rename
DROP FUNCTION pricelist__delete(int,int);

BEGIN;
ALTER TABLE location ALTER COLUMN mail_code DROP NOT NULL;
COMMIT;

BEGIN;
INSERT INTO lsmb_module(id, label) values (7, 'Timecards');
COMMIT;

BEGIN;
INSERT INTO defaults (setting_key, value) values ('dojo_theme', 'claro');
COMMIT;

BEGIN;
CREATE FUNCTION prevent_closed_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE t_end_date date;
BEGIN
SELECT max(end_date) into t_end_date FROM account_checkpoint;
IF new.transdate <= t_end_date THEN
    RAISE EXCEPTION 'Transaction entered into closed period.  Transdate: %',
                   new.transdate;
END IF;
RETURN new;
END;
$$;


CREATE TRIGGER acc_trans_prevent_closed BEFORE INSERT ON acc_trans 
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();
CREATE TRIGGER ap_prevent_closed BEFORE INSERT ON ap 
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();
CREATE TRIGGER ar_prevent_closed BEFORE INSERT ON ar 
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();
CREATE TRIGGER gl_prevent_closed BEFORE INSERT ON gl 
FOR EACH ROW EXECUTE PROCEDURE prevent_closed_transactions();
COMMIT;

BEGIN;

CREATE TABLE lsmb_sequence (
   label text primary key,
   setting_key text not null references defaults(setting_key),
   prefix text,
   suffix text,
   sequence text not null default '1',
   accept_input bool default true
);

COMMIT;


BEGIN;

ALTER TABLE jcitems DROP CONSTRAINT "jcitems_person_id_fkey";
ALTER TABLE jcitems ADD FOREIGN KEY (person_id) REFERENCES entity(id);

COMMIT;

BEGIN;
ALTER TABLE entity_class DROP COLUMN IF EXISTS country_id;
COMMIT;

BEGIN;
ALTER TABLE audittrail DROP CONSTRAINT IF EXISTS "audittrail_person_id_fkey";
ALTER TABLE audittrail ADD CONSTRAINT "audittrail_person_id_fkey" FOREIGN KEY(person_id) REFERENCES entity(id);

CREATE OR REPLACE FUNCTION gl_audit_trail_append()
RETURNS TRIGGER AS
$$
DECLARE
   t_reference text;
   t_row RECORD;
BEGIN

IF TG_OP = 'INSERT' then
   t_row := NEW;
ELSE
   t_row := OLD;
END IF;

IF TG_RELNAME IN ('ar', 'ap') THEN
    t_reference := t_row.invnumber;
ELSE 
    t_reference := t_row.reference;
END IF;

INSERT INTO audittrail (trans_id,tablename,reference, action, person_id)
values (t_row.id,TG_RELNAME,t_reference, TG_OP, person__get_my_entity_id());

return null; -- AFTER TRIGGER ONLY, SAFE
END;
$$ language plpgsql security definer;

COMMIT;

BEGIN;
ALTER TABLE ar ADD COLUMN crdate date;
ALTER TABLE ap ADD COLUMN crdate date;
ALTER TABLE entity_bank_account ADD COLUMN  remark text;

COMMIT;

BEGIN;

CREATE TABLE template ( -- not for UI templates
    id serial not null unique,
    template_name text not null,
    language_code varchar(6) references language(code),
    template text not null,
    format text not null,
    unique(template_name, language_code, format)
);

CREATE UNIQUE INDEX template_name_idx_u ON template(template_name, format) 
WHERE language_code is null; -- Pseudo-Pkey

commit;

-- ### not a real check, but we rely on failing transactions above
-- for the purpose of rejecting bits of script which might have already
-- been executed before.

update defaults set value='yes' where setting_key='module_load_ok';

BEGIN;
SELECT admin__add_user_to_role(username, lsmb__role_prefix() || 'base_user')
  from users;
COMMIT;

BEGIN;
INSERT INTO taxmodule (taxmodule_id, taxmodulename) values (2, 'Rounded');
COMMIT;

BEGIN;
ALTER TABLE new_shipto DROP CONSTRAINT new_shipto_trans_id_fkey;
ALTER TABLE new_shipto ADD FOREIGN KEY (trans_id) REFERENCES transactions(id);
COMMIT;
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

