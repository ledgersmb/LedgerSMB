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

-- Fixes after 1.4.0 below this point.  Fixes above to be deleted after 1.4.10
-- Fixes below not to be deleted

BEGIN;
CREATE TABLE fixed_acc_trans (LIKE acc_trans);
COMMIT;

BEGIN;
INSERT INTO fixed_acc_trans 
SELECT * FROM acc_trans
WHERE transdate IS NULL;

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

BEGIN;
create table location_class_to_entity_class (
  id serial unique,
  location_class int not null references location_class(id),
  entity_class int not null references entity_class(id)
);

GRANT SELECT ON location_class_to_entity_class TO PUBLIC;

COMMENT ON TABLE location_class_to_entity_class IS
$$This determines which location classes go with which entity classes$$;

INSERT INTO location_class(id,class,authoritative) VALUES ('4','Physical',TRUE);
INSERT INTO location_class(id,class,authoritative) VALUES ('5','Mailing',FALSE);

SELECT SETVAL('location_class_id_seq',5);

INSERT INTO location_class_to_entity_class
       (location_class, entity_class)
SELECT lc.id, ec.id
  FROM entity_class ec
 cross
  join location_class lc
 WHERE ec.id <> 3 and lc.id < 4;

INSERT INTO location_class_to_entity_class (location_class, entity_class)
SELECT id, 3 from location_class lc where lc.id > 3;

COMMIT;

BEGIN;
ALTER TABLE BATCH DROP CONSTRAINT "batch_locked_by_fkey";

ALTER TABLE BATCH ADD FOREIGN KEY (locked_by) references session (session_id) 
ON DELETE SET NULL;

COMMIT;

BEGIN;
UPDATE entity_credit_account
   SET curr = (select s from unnest(string_to_array((setting_get('curr')).value, ':')) s limit 1)
 WHERE curr IS NULL;
COMMIT;

BEGIN;
UPDATE menu_node set position = (position * -1) - 1 
 where parent IN (172, 156) and position > 1;
UPDATE menu_node set position = position * -1 where position < 0;
INSERT INTO menu_node (id, parent, position, label)
VALUES (90, 172, 2, 'Product Receipt'),
       (99, 156, 2, 'Product Receipt');

INSERT INTO menu_attribute 
(id, node_id, attribute, value) VALUES
(228, 90, 'module', 'template.pm'),
(229, 90, 'action', 'display'),
(230, 90, 'template_name', 'product_receipt'),
(231, 90, 'format', 'tex'),
(240, 99, 'module', 'template.pm'),
(241, 99, 'action', 'display'),
(242, 99, 'template_name', 'product_receipt'),
(245, 99, 'format', 'html');
COMMIT;

BEGIN;
ALTER TABLE person ADD COLUMN birthdate date;
ALTER TABLE person ADD COLUMN personal_id text;
COMMIT;

-- Removing batch printing menu options
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

BEGIN;
ALTER TABLE ar ADD COLUMN is_return bool default false;
COMMIT;
BEGIN; -- SEPARATE transaction due to questions of if one of the cols si there
ALTER TABLE ap ADD COLUMN is_return bool default false;
COMMIT;

BEGIN;
UPDATE menu_node SET position = position * -1 - 1 WHERE parent = 1 and position > 6;
INSERT INTO menu_node (id, parent, position, label)
VALUES (129, 1, 7, 'Add Return');
update menu_node set position = position * -1 where position < 0;
INSERT INTO menu_attribute (id, node_id, attribute, value)
VALUES (251, 129, 'module', 'is.pl'),
       (252, 129, 'action', 'add'),
       (253, 129, 'type', 'customer_return');
COMMIT;

BEGIN;
ALTER TABLE invoice ADD vendor_sku text;
UPDATE invoice SET vendor_sku = (select min(partnumber) from partsvendor
                                  where parts_id = invoice.parts_id
                                        AND credit_id = (
                                                 select entity_credit_account
                                                   from ap
                                                  where ap.id = invoice.trans_id
                                        )
                                )
 WHERE trans_id in (select id from ap);
COMMIT;

BEGIN;
ALTER TABLE ar DROP CONSTRAINT ar_invnumber_key;
ALTER TABLE ar ADD CHECK(invnumber is not null OR not approved);
CREATE UNIQUE INDEX ar_invnumber_key_p ON ar(invnumber) where invnumber is not null;
COMMIT;
ALTER TABLE ar ADD setting_sequence TEXT;

BEGIN;
UPDATE menu_attribute SET value = 'contact.pl'
 WHERE node_id = 48 AND attribute = 'module';
COMMIT;

BEGIN;
UPDATE menu_attribute SET value = 'template.pl' WHERE value = 'template.pm';
COMMIT;

-- Add parent of the header as its "heading"
CREATE OR REPLACE VIEW chart AS
SELECT id, accno, description,
       'H' as charttype, NULL as category, NULL as link,
       parent_id as account_heading,
       null as gifi_accno, false as contra,
       false as tax
  from account_heading
UNION
select c.id, c.accno, c.description,
       'A' as charttype, c.category, concat_colon(l.description) as link,
       heading, gifi_accno, contra,
       tax
  from account c
  left join account_link l
    ON (c.id = l.account_id)
group by c.id, c.accno, c.description, c.category, c.heading,
         c.gifi_accno, c.contra, c.tax;

BEGIN;
ALTER TABLE account_heading ADD COLUMN category CHAR(1);
END;

BEGIN;
UPDATE language SET code = 'ms_MY' WHERE code = 'my';
COMMIT;


BEGIN;
ALTER TABLE business_unit_ac
  DROP CONSTRAINT business_unit_ac_entry_id_fkey,
  ADD CONSTRAINT business_unit_ac_entry_id_fkey
     FOREIGN KEY (entry_id)
     REFERENCES acc_trans(entry_id)
     ON DELETE CASCADE;
ALTER TABLE business_unit_inv
  DROP CONSTRAINT business_unit_inv_entry_id_fkey,
  ADD CONSTRAINT business_unit_inv_entry_id_fkey
     FOREIGN KEY (entry_id)
     REFERENCES invoice(id)
     ON DELETE CASCADE;
CREATE INDEX business_unit_ac_entry_id_idx ON business_unit_ac (entry_id);
CREATE INDEX business_unit_inv_entry_id_idx ON business_unit_inv(entry_id);
CREATE INDEX business_unit_oitem_entry_id_idx ON business_unit_oitem(entry_id);
COMMIT;


BEGIN;
CREATE TABLE account_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE account_translation
ADD foreign key (trans_id) REFERENCES account(id);

COMMENT ON TABLE account_translation IS
$$Translations for account descriptions.$$;

CREATE TABLE account_heading_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE account_heading_translation
ADD foreign key (trans_id) REFERENCES account_heading(id);

COMMENT ON TABLE account_heading_translation IS
$$Translations for account heading descriptions.$$;

COMMIT;

BEGIN;

CREATE OR REPLACE VIEW chart AS
SELECT ah.id, ah.accno, coalesce(ht.description, ah.description) as description,
       'H' as charttype, NULL as category, NULL as link,
       ah.parent_id as account_heading,
       null as gifi_accno, false as contra,
       false as tax
  from account_heading ah
  LEFT JOIN (SELECT ht.trans_id, ht.description FROM account_heading_translation ht
                                    INNER JOIN user_preference up ON
                                          up.language = ht.language_code
                                    INNER JOIN users ON up.id = users.id
                                    WHERE users.username = SESSION_USER) ht
         ON ah.id = ht.trans_id
UNION
select c.id, c.accno, coalesce(at.description, c.description),
       'A' as charttype, c.category, concat_colon(l.description) as link,
       heading, gifi_accno, contra,
       tax
  from account c
  left join account_link l
    ON (c.id = l.account_id)
  LEFT JOIN (SELECT at.trans_id, at.description FROM account_translation at
                                    INNER JOIN user_preference up ON
                                          up.language = at.language_code
                                    INNER JOIN users ON up.id = users.id
                                    WHERE users.username = SESSION_USER) at
         ON c.id = at.trans_id
group by c.id, c.accno, coalesce(at.description, c.description), c.category,
         c.heading, c.gifi_accno, c.contra, c.tax;

COMMIT;
