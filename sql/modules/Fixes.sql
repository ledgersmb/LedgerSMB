-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- These will be cleaned up going back no more than one beta.

-- Chris Travers

-- BETA 1-3 (delete a month after Beta 4)


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

ALTER TABLE payroll_deduction_class ADD stored_proc_name name not null;

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
