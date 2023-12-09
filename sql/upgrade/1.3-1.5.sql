

-----------------------------------------------------------------------
--
--  1.3 FIXES.SQL: This block is intentionally without transactions,
--      it runs potentially already applied fixes to get from 1.3.X
--      to 1.3.<latest>
--
-----------------------------------------------------------------------


-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must
-- fail transactionally.  Please:  one transaction per fix.
--
-- Chris Travers

\set ON_ERROR_STOP off
\set ON_ERROR_ROLLBACK on

BEGIN; -- PRE-RC update

ALTER TABLE partscustomer RENAME customer_id TO credit_id;
ALTER TABLE partsvendor RENAME entity_id TO credit_id;

COMMIT;


BEGIN; -- 1.3.4, fix for menu-- David Bandel
update menu_attribute set value = 'receive_order' where value  =
'consolidate_sales_order' and node_id = '65';

update menu_attribute set id = '149' where value  = 'receive_order'
and node_id = '65';

update menu_attribute set value = 'consolidate_sales_order' where
value  = 'receive_order' and node_id = '64';

update menu_attribute set id = '152' where value  =
'consolidate_sales_order' and node_id = '64';

-- fix for bug 3430820
update menu_attribute set value = 'pricegroup' where node_id = '83' and attribute = 'type';
update menu_attribute set value = 'partsgroup' where node_id = '82' and attribute = 'type';

UPDATE menu_attribute SET value = 'partsgroup' WHERE node_id = 91 and attribute = 'type';
UPDATE menu_attribute SET value = 'pricegroup' WHERE node_id = 92 and attribute = 'type';

-- Very restrictive because some people still have Asset handling installed from
-- Addons and so the node_id and id values may not match.  Don't want to break
-- what is working! --CT
UPDATE menu_attribute SET value = 'begin_import' WHERE id = 631 and value = 'import' and node_id = '235';

-- Getting rid of System/Backup menu since this is broken

DELETE FROM menu_acl       WHERE node_id BETWEEN 133 AND 135;
DELETE FROM menu_attribute WHERE node_id BETWEEN 133 AND 135;
DELETE FROM menu_node      WHERE id      BETWEEN 133 AND 135;

-- bad batch type for receipt batches
update menu_attribute set value = 'receipt' where node_id = 203 and attribute='batch_type';

COMMIT;

BEGIN;
ALTER TABLE entity_credit_account drop constraint "entity_credit_account_language_code_fkey";
COMMIT;

BEGIN;
ALTER TABLE entity_credit_account ADD FOREIGN KEY (language_code) REFERENCES language(code);
COMMIT;

BEGIN;
UPDATE menu_attribute SET value = 'invoice'
   WHERE node_id = 117 AND attribute = 'type';
UPDATE menu_attribute SET value = 'sales_order'
   WHERE node_id = 118 AND attribute = 'type';
COMMIT;

BEGIN;
ALTER TABLE entity_bank_account DROP CONSTRAINT entity_bank_account_pkey;
ALTER TABLE entity_bank_account ALTER COLUMN bic DROP NOT NULL;
ALTER TABLE entity_bank_account ADD UNIQUE(bic,iban);
CREATE UNIQUE INDEX eba_iban_null_bic_u ON entity_bank_account(iban) WHERE bic IS NULL;
COMMIT;

BEGIN; -- Data fixes for 1.2-1.3 upgrade.  Will fail otherwise --Chris T
UPDATE parts
   SET income_accno_id = (SELECT account.id
                            FROM account JOIN lsmb12.chart USING (accno)
                           WHERE chart.id = income_accno_id),
       expense_accno_id = (SELECT account.id
                            FROM account JOIN lsmb12.chart USING (accno)
                           WHERE chart.id = expense_accno_id),
       inventory_accno_id = (SELECT account.id
                            FROM account JOIN lsmb12.chart USING (accno)
                           WHERE chart.id = inventory_accno_id)
 WHERE id IN (SELECT id FROM lsmb12.parts op
               WHERE op.id = parts.id
                     AND (op.income_accno_id = parts.income_accno_id
                          OR op.inventory_accno_id = parts.inventory_accno_id
                          or op.expense_accno_id = parts.expense_accno_id));
COMMIT;

BEGIN;
-- Fix menu Shipping -> Ship to actually point to the shipping interface
-- used to point to sales order consolidation
UPDATE menu_attribute
 SET value = 'ship_order'
 WHERE attribute='type'
       AND node_id = (SELECT id FROM menu_node WHERE label = 'Ship');
COMMIT;

BEGIN;
-- fix for non-existant role handling in menu_generate() and related


CREATE OR REPLACE FUNCTION menu_generate() RETURNS SETOF menu_item AS
$$
DECLARE
        item menu_item;
        arg menu_attribute%ROWTYPE;
BEGIN
        FOR item IN
                SELECT n.position, n.id, c.level, n.label, c.path,
                       to_args(array[ma.attribute, ma.value])
                FROM connectby('menu_node', 'id', 'parent', 'position', '0',
                                0, ',')
                        c(id integer, parent integer, "level" integer,
                                path text, list_order integer)
                JOIN menu_node n USING(id)
                JOIN menu_attribute ma ON (n.id = ma.node_id)
               WHERE n.id IN (select node_id
                                FROM menu_acl
                                JOIN (select rolname FROM pg_roles
                                      UNION
                                     select 'public') pgr
                                     ON pgr.rolname = role_name
                               WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public')
                                                                    = 'public'
                                                      THEN current_user
                                                      ELSE pgr.rolname
                                                   END, 'USAGE')
                            GROUP BY node_id
                              HAVING bool_and(CASE WHEN acl_type ilike 'DENY'
                                                   THEN FALSE
                                                   WHEN acl_type ilike 'ALLOW'
                                                   THEN TRUE
                                                END))
                    or exists (select cn.id, cc.path
                                 FROM connectby('menu_node', 'id', 'parent',
                                                'position', '0', 0, ',')
                                      cc(id integer, parent integer,
                                         "level" integer, path text,
                                         list_order integer)
                                 JOIN menu_node cn USING(id)
                                WHERE cn.id IN
                                      (select node_id FROM menu_acl
                                        JOIN (select rolname FROM pg_roles
                                              UNION
                                              select 'public') pgr
                                              ON pgr.rolname = role_name
                                        WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public')
                                                                    = 'public'
                                                      THEN current_user
                                                      ELSE pgr.rolname
                                                   END, 'USAGE')
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                         END))
                                       and cc.path like c.path || ',%')
            GROUP BY n.position, n.id, c.level, n.label, c.path, c.list_order
            ORDER BY c.list_order

        LOOP
                RETURN NEXT item;
        END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION menu_generate() IS
$$
This function returns the complete menu tree.  It is used to generate nested
menus for the web interface.
$$;

CREATE OR REPLACE FUNCTION menu_children(in_parent_id int) RETURNS SETOF menu_item
AS $$
declare
        item menu_item;
        arg menu_attribute%ROWTYPE;
begin
        FOR item IN
                SELECT n.position, n.id, c.level, n.label, c.path,
                       to_args(array[ma.attribute, ma.value])
                FROM connectby('menu_node', 'id', 'parent', 'position',
                                in_parent_id, 1, ',')
                        c(id integer, parent integer, "level" integer,
                                path text, list_order integer)
                JOIN menu_node n USING(id)
                JOIN menu_attribute ma ON (n.id = ma.node_id)
               WHERE n.id IN (select node_id
                                FROM menu_acl
                                JOIN (select rolname FROM pg_roles
                                      UNION
                                      select 'public') pgr
                                      ON pgr.rolname = role_name
                                WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public')
                                                                    = 'public'
                                                               THEN current_user
                                                               ELSE pgr.rolname
                                                               END, 'USAGE')
                            GROUP BY node_id
                              HAVING bool_and(CASE WHEN acl_type ilike 'DENY'
                                                   THEN FALSE
                                                   WHEN acl_type ilike 'ALLOW'
                                                   THEN TRUE
                                                END))
                    or exists (select cn.id, cc.path
                                 FROM connectby('menu_node', 'id', 'parent',
                                                'position', '0', 0, ',')
                                      cc(id integer, parent integer,
                                         "level" integer, path text,
                                         list_order integer)
                                 JOIN menu_node cn USING(id)
                                WHERE cn.id IN
                                      (select node_id FROM menu_acl
                                         JOIN (select rolname FROM pg_roles
                                              UNION
                                              select 'public') pgr
                                              ON pgr.rolname = role_name
                                        WHERE pg_has_role(CASE WHEN coalesce(pgr.rolname,
                                                                    'public')
                                                                    = 'public'
                                                               THEN current_user
                                                               ELSE pgr.rolname
                                                               END, 'USAGE')
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                         END))
                                       and cc.path like c.path || ',%')
            GROUP BY n.position, n.id, c.level, n.label, c.path, c.list_order
            ORDER BY c.list_order
        LOOP
                return next item;
        end loop;
end;
$$ language plpgsql;
COMMIT;

BEGIN; -- Search Assets menu
update menu_node set parent = 229 where id = 233;
COMMIT;

BEGIN; -- timecard additional info
ALTER TABLE jcitems ADD total numeric NOT NULL DEFAULT 0;
ALTER TABLE jcitems ADD non_billable numeric NOT NULL DEFAULT 0;

UPDATE jcitems
   SET total = qty
 WHERE qty IS NOT NULL and total = 0;

COMMIT;

BEGIN;

-- FX RECON

ALTER TABLE cr_report ADD recon_fx bool default false;

COMMIT;

BEGIN;

-- MIN VALUE FOR TAXES

ALTER TABLE tax ADD minvalue numeric;
ALTER TABLE tax ADD maxvalue numeric;


COMMIT;

BEGIN;

ALTER TABLE mime_type ADD invoice_include bool default false;
UPDATE mime_type SET invoice_include = 'true' where mime_type like 'image/%';

COMMIT;

BEGIN;

UPDATE menu_attribute SET value = 'sales_quotation'
WHERE node_id = 169 AND attribute = 'template';

UPDATE menu_attribute SET value = 'request_quotation'
WHERE node_id = 170 AND attribute = 'template';

COMMIT;
BEGIN;

-- fixes for menu taking a long time to render when few permissions are granted

DROP TYPE IF EXISTS menu_item CASCADE;
CREATE TYPE menu_item AS (
   position int,
   id int,
   level int,
   label varchar,
   path varchar,
   parent int,
   args varchar[]
);



CREATE OR REPLACE FUNCTION menu_generate() RETURNS SETOF menu_item AS
$$
DECLARE
        item menu_item;
        arg menu_attribute%ROWTYPE;
BEGIN
        FOR item IN
               WITH RECURSIVE tree (path, id, parent, level, positions)
                               AS (select id::text as path, id, parent,
                                           0 as level, position::text
                                      FROM menu_node where parent is null
                                     UNION
                                    select path || ',' || n.id::text, n.id,
                                           n.parent,
                                           t.level + 1,
                                           t.positions || ',' || n.position
                                      FROM menu_node n
                                      JOIN tree t ON t.id = n.parent)
                SELECT n.position, n.id, c.level, n.label, c.path, n.parent,
                       to_args(array[ma.attribute, ma.value])
                FROM tree c
                JOIN menu_node n USING(id)
                JOIN menu_attribute ma ON (n.id = ma.node_id)
               WHERE n.id IN (select node_id
                                FROM menu_acl acl
                          LEFT JOIN pg_roles pr on pr.rolname = acl.role_name
                               WHERE CASE WHEN role_name
                                                           ilike 'public'
                                                      THEN true
                                                      WHEN rolname IS NULL
                                                      THEN FALSE
                                                      ELSE pg_has_role(rolname,
                                                                       'USAGE')
                                      END
                            GROUP BY node_id
                              HAVING bool_and(CASE WHEN acl_type ilike 'DENY'
                                                   THEN FALSE
                                                   WHEN acl_type ilike 'ALLOW'
                                                   THEN TRUE
                                                END))
                    or exists (select cn.id, cc.path
                                 FROM tree cc
                                 JOIN menu_node cn USING(id)
                                WHERE cn.id IN
                                      (select node_id
                                         FROM menu_acl acl
                                    LEFT JOIN pg_roles pr
                                              on pr.rolname = acl.role_name
                                        WHERE CASE WHEN rolname
                                                           ilike 'public'
                                                      THEN true
                                                      WHEN rolname IS NULL
                                                      THEN FALSE
                                                      ELSE pg_has_role(rolname,
                                                                       'USAGE')
                                                END
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                         END))
                                       and cc.path::text
                                           like c.path::text || ',%')
            GROUP BY n.position, n.id, c.level, n.label, c.path, c.positions,
                     n.parent
            ORDER BY string_to_array(c.positions, ',')::int[]
        LOOP
                RETURN NEXT item;
        END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION menu_generate() IS
$$
This function returns the complete menu tree.  It is used to generate nested
menus for the web interface.
$$;

CREATE OR REPLACE FUNCTION menu_children(in_parent_id int) RETURNS SETOF menu_item
AS $$
SELECT * FROM menu_generate() where parent = $1;
$$ language sql;

COMMENT ON FUNCTION menu_children(int) IS
$$ This function returns all menu  items which are children of in_parent_id
(the only input parameter).

It is thus similar to menu_generate() but it only returns the menu items
associated with nodes directly descendant from the parent.  It is used for
menues for frameless browsers.$$;

CREATE OR REPLACE FUNCTION
menu_insert(in_parent_id int, in_position int, in_label text)
returns int
AS $$
DECLARE
        new_id int;
BEGIN
        UPDATE menu_node
        SET position = position * -1
        WHERE parent = in_parent_id
                AND position >= in_position;

        INSERT INTO menu_node (parent, position, label)
        VALUES (in_parent_id, in_position, in_label);

        SELECT INTO new_id currval('menu_node_id_seq');

        UPDATE menu_node
        SET position = (position * -1) + 1
        WHERE parent = in_parent_id
                AND position < 0;

        RETURN new_id;
END;
$$ language plpgsql;

comment on function menu_insert(int, int, text) is $$
This function inserts menu items at arbitrary positions.  The arguments are, in
order:  parent, position, label.  The return value is the id number of the menu
item created. $$;

DROP VIEW menu_friendly;
CREATE VIEW menu_friendly AS
WITH RECURSIVE tree (path, id, parent, level, positions)
                               AS (select id::text as path, id, parent,
                                           0 as level, position::text
                                      FROM menu_node where parent is null
                                     UNION
                                    select path || ',' || n.id::text, n.id,
                                           n.parent,
                                           t.level + 1,
                                           t.positions || ',' || n.position
                                      FROM menu_node n
                                      JOIN tree t ON t.id = n.parent)
SELECT t."level", t.path,
       (repeat(' '::text, (2 * t."level")) || (n.label)::text) AS label,
        n.id, n."position"
   FROM tree t
   JOIN menu_node n USING (id)
  ORDER BY string_to_array(t.positions, ',')::int[];

COMMENT ON VIEW menu_friendly IS
$$ A nice human-readable view for investigating the menu tree.  Does not
show menu attributes or acls.$$;

COMMIT;

BEGIN;
-- Fix for menu anomilies
DELETE FROM menu_acl
 where node_id in (select node_id from menu_attribute where attribute = 'menu');

COMMIT;

BEGIN;
-- fix primary key for make/model
ALTER TABLE makemodel DROP CONSTRAINT makemodel_pkey;
ALTER TABLE makemodel ADD PRIMARY KEY(parts_id, make, model);
COMMIT;

BEGIN;
-- performance fix for all years list  functions

create index ac_transdate_year_idx on acc_trans(EXTRACT ('YEAR' FROM transdate));

COMMIT;

BEGIN;
-- RECEIPT REVERSAL broken:

insert into batch_class (id,class) values (7,'receipt_reversal');

COMMIT;

BEGIN;

-- FIXING AP MENU

 update menu_attribute set value = 'tax_paid' where node_id = 28 and attribute = 'report';

update menu_attribute set value = 'ap_aging' where node_id = 27 and attribute = 'report';

COMMIT;

BEGIN;

-- inventory from 1.3.30 and lower

UPDATE parts
   SET onhand = onhand + coalesce((select sum(qty)
                            from inventory
                           where orderitems_id
                                 IN (select id
                                       from orderitems oi
                                       join oe on oi.trans_id = oe.id
                                      where closed is not true)
                                 and parts_id = parts.id), 0)
 WHERE string_to_array((setting_get('version')).value::text, '.')::int[]
       < '{1,3,31}';

COMMIT;

BEGIN;
delete from menu_attribute where node_id = 192 and attribute = 'menu';

DELETE FROM menu_acl WHERE node_id = 60 AND exists (select 1 from menu_attribute where node_id = 60 and attribute = 'menu');

COMMIT;

BEGIN;
ALTER FUNCTION admin__save_user(int, int, text, text, bool) SET datestyle = 'ISO,YMD';
ALTER FUNCTION user__change_password(text) SET datestyle = 'ISO,YMD';
COMMIT;

BEGIN;
ALTER TABLE ar DISABLE TRIGGER ALL;
ALTER TABLE ap DISABLE TRIGGER ALL;

ALTER TABLE ap ADD COLUMN crdate date;
ALTER TABLE ar ADD COLUMN crdate date;

UPDATE ap SET crdate=transdate;
UPDATE ar SET crdate=transdate;

COMMENT ON COLUMN ap.crdate IS
$$ This is for recording the AR/AP creation date, which is always that date, when the invoice created. This is different, than transdate or duedate.
This kind of date does not effect on ledger/financial data, but for administrative purposes in Hungary, probably in other countries, too.
Use case:
if somebody pay in cash, crdate=transdate=duedate
if somebody will receive goods T+5 days and have 15 days term, the dates are the following:  crdate: now,  transdate=crdate+5,  duedate=transdate+15.
There are rules in Hungary, how to fill out a correct invoice, where the crdate and transdate should be important.$$;

COMMENT ON COLUMN ar.crdate IS
$$ This is for recording the AR/AP creation date, which is always that date, when the invoice created. This is different, than transdate or duedate.
This kind of date does not effect on ledger/financial data, but for administrative purposes in Hungary, probably in other countries, too.
Use case:
if somebody pay in cash, crdate=transdate=duedate
if somebody will receive goods T+5 days and have 15 days term, the dates are the following:  crdate: now,  transdate=crdate+5,  duedate=transdate+15.
There are rules in Hungary, how to fill out a correct invoice, where the crdate and transdate should be important.$$;

ALTER TABLE ar ENABLE TRIGGER ALL;
ALTER TABLE ap ENABLE TRIGGER ALL;

COMMIT;

BEGIN;
        ALTER TABLE entity_bank_account ADD COLUMN remark varchar;
        COMMENT ON COLUMN entity_bank_account.remark IS
$$ This field contains the notes for an account, like: This is USD account, this one is HUF account, this one is the default account, this account for paying specific taxes. If a partner has more than one account, now you are able to write remarks for them.
$$;

DROP FUNCTION eca__save_bank_account (int, int, text, text, int);
DROP FUNCTION entity__save_bank_account (int, text, text, int);

CREATE OR REPLACE FUNCTION eca__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text, in_remark text,
in_bank_account_id int)
RETURNS int AS
$$
DECLARE out_id int;
BEGIN
        UPDATE entity_bank_account
           SET bic = in_bic,
               iban = in_iban,
               remark = in_remark
         WHERE id = in_bank_account_id;

        IF FOUND THEN
                out_id = in_bank_account_id;
        ELSE
                INSERT INTO entity_bank_account(entity_id, bic, iban, remark)
                VALUES(in_entity_id, in_bic, in_iban, in_remark);
                SELECT CURRVAL('entity_bank_account_id_seq') INTO out_id ;
        END IF;

        IF in_credit_id IS NOT NULL THEN
                UPDATE entity_credit_account SET bank_account = out_id
                WHERE id = in_credit_id;
        END IF;

        RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON  FUNCTION eca__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text, in_remark text,
in_bank_account_id int) IS
$$ Saves bank account to the credit account.$$;

CREATE OR REPLACE FUNCTION entity__save_bank_account
(in_entity_id int, in_bic text, in_iban text, in_remark text, in_bank_account_id int)
RETURNS int AS
$$
DECLARE out_id int;
BEGIN
        UPDATE entity_bank_account
           SET bic = in_bic,
               iban = in_iban,
               remark = in_remark
         WHERE id = in_bank_account_id;

        IF FOUND THEN
                out_id = in_bank_account_id;
        ELSE
                INSERT INTO entity_bank_account(entity_id, bic, iban, remark)
                VALUES(in_entity_id, in_bic, in_iban, in_remark);
                SELECT CURRVAL('entity_bank_account_id_seq') INTO out_id ;
        END IF;

        RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION entity__save_bank_account
(in_entity_id int, in_bic text, in_iban text, in_remark text, in_bank_account_id int) IS
$$Saves a bank account to the entity.$$;

COMMIT;

BEGIN;
ALTER TABLE location ALTER COLUMN mail_code DROP NOT NULL;
COMMIT;

BEGIN;
UPDATE menu_attribute
   SET value = 'sales_quotation'
 where value = 'quotation' AND attribute='template';
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
INSERT INTO defaults VALUES ('disable_back', '0');
COMMIT;

BEGIN;
ALTER TABLE batch DROP CONSTRAINT "batch_locked_by_fkey";
ALTER TABLE batch ADD FOREIGN KEY (locked_by) REFERENCES session(session_id)
ON DELETE SET NULL;
COMMIT;

BEGIN;

ALTER TABLE invoice ALTER COLUMN allocated TYPE NUMERIC;

COMMIT;

BEGIN;
ALTER TABLE entity_employee ADD is_manager bool DEFAULT FALSE;
UPDATE entity_employee SET is_manager = true WHERE role = 'manager';

COMMIT;

BEGIN;
ALTER TABLE BATCH DROP CONSTRAINT "batch_locked_by_fkey";

ALTER TABLE BATCH ADD FOREIGN KEY (locked_by) references session (session_id)
ON DELETE SET NULL;

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




------------------------------------------------------------------------
--
--  END OF FIXES.SQL
--
------------------------------------------------------------------------

\set ON_ERROR_STOP on

BEGIN;

DELETE FROM entity_credit_account;
DELETE FROM person;
DELETE FROM company;
DELETE FROM entity;

--to preserve user modifications tshvr4
DELETE FROM country;
INSERT INTO country (id, name, short_name, itu)
SELECT id, name, short_name, itu FROM lsmb13.country;

INSERT INTO language SELECT * FROM lsmb13.language where code not in (select code from language);

INSERT INTO account_heading SELECT * FROM lsmb13.account_heading;
INSERT INTO account(
       id, accno, description, category, gifi_accno, heading, contra, tax
)
SELECT
       id, accno, description, category, gifi_accno, heading, contra, tax
FROM lsmb13.account;

INSERT INTO account_checkpoint SELECT * FROM lsmb13.account_checkpoint;
INSERT INTO account_link_description SELECT * FROM lsmb13.account_link_description WHERE lsmb13.account_link_description.description NOT IN (SELECT description FROM account_link_description);
INSERT INTO account_link SELECT * FROM lsmb13.account_link;
INSERT INTO pricegroup SELECT * FROM lsmb13.pricegroup;

INSERT INTO parts (
  id,
  partnumber,
  description,
  unit,
  listprice,
  sellprice,
  lastcost,
  priceupdate,
  weight,
  onhand,
  notes,
  makemodel,
  assembly,
  alternate,
  rop,
  inventory_accno_id,
  income_accno_id ,
  expense_accno_id,
  bin,
  obsolete,
  bom,
  image,
  drawing,
  microfiche,
  partsgroup_id,
  avgcost
)
SELECT
  p.id,
  partnumber,
  p.description,
  unit,
  listprice,
  sellprice,
  lastcost,
  priceupdate,
  weight,
  onhand,
  notes,
  makemodel,
  assembly,
  alternate,
  rop,
  inventory_accno_id,
  income_accno_id ,
  expense_accno_id,
  bin,
  p.obsolete,
  bom,
  image,
  drawing,
  microfiche,
  partsgroup_id,
  avgcost
 FROM lsmb13.parts p;

INSERT INTO country_tax_form SELECT * FROM lsmb13.country_tax_form;

INSERT INTO entity (id, name, entity_class, control_code, created, country_id)
SELECT id, name, entity_class, control_code, created, country_id
  FROM lsmb13.entity;

INSERT INTO users SELECT * FROM lsmb13.users;

UPDATE lsmb13.location
   SET line_one = case
        when line_one = '' then 'Null'
        when line_one is null then 'Null'
        else line_one
    end,
    city = case
        when city !~ '[[:alnum:]_]' then 'Invalid'
        when city is null then 'Null'
        else city
    end,
    mail_code = case
        when mail_code !~ '[[:alnum:]_]' then 'Invalid'
        when mail_code is null then 'Null'
        else mail_code
    end;


INSERT INTO location SELECT * FROM lsmb13.location;
INSERT INTO company SELECT * FROM lsmb13.company;

INSERT INTO entity_to_location (entity_id, location_id, location_class)
SELECT c.entity_id, l.location_id, l.location_class
FROM lsmb13.company_to_location l
JOIN lsmb13.company c ON c.id = l.company_id;

INSERT INTO entity_to_location (entity_id, location_id, location_class)
SELECT p.entity_id, l.location_id, l.location_class
FROM lsmb13.person_to_location l
JOIN lsmb13.person p ON p.id = l.person_id AND p.entity_id IS NOT NULL;

INSERT INTO person SELECT * FROM lsmb13.person;
INSERT INTO entity_employee SELECT * FROM lsmb13.entity_employee;
UPDATE entity_employee
   SET ssn = 'invalid-' || entity_id::text
 WHERE ssn = '' or ssn is null;
UPDATE entity_employee
   SET employeenumber = 'invalid-' || entity_id::text
 WHERE employeenumber = '' or employeenumber is null;

INSERT INTO person_to_company SELECT * FROM lsmb13.person_to_company;
INSERT INTO entity_other_name SELECT * FROM lsmb13.entity_other_name;
INSERT INTO entity_to_contact
       (entity_id, contact_class_id, contact, description)
SELECT e.id, cc.contact_class_id, cc.contact, cc.description
   FROM lsmb13.company_to_contact cc
   JOIN lsmb13.company c ON c.id = cc.company_id
   JOIN lsmb13.entity e ON e.id = c.entity_id;
INSERT INTO entity_to_contact
       (entity_id, contact_class_id, contact, description)
SELECT e.id, pc.contact_class_id, pc.contact, pc.description
   FROM lsmb13.person_to_contact pc
   JOIN lsmb13.person p ON p.id = pc.person_id
   JOIN lsmb13.entity e ON e.id = p.entity_id;
INSERT INTO entity_bank_account (id, entity_id, bic, iban, remark)
SELECT id, entity_id, coalesce(bic,''), iban, remark FROM lsmb13.entity_bank_account;
INSERT INTO entity_credit_account SELECT * FROM lsmb13.entity_credit_account;
UPDATE entity_credit_account SET curr = (select curr from lsmb13.defaults_get_defaultcurrency() as c(curr) limit 1)
 WHERE curr IS NULL;
INSERT INTO eca_to_contact SELECT * FROM lsmb13.eca_to_contact;
INSERT INTO eca_to_location SELECT * FROM lsmb13.eca_to_location;
INSERT INTO entity_note SELECT * FROM lsmb13.entity_note;
INSERT INTO invoice_note SELECT * FROM lsmb13.invoice_note;
INSERT INTO eca_note SELECT * FROM lsmb13.eca_note;

INSERT INTO makemodel(parts_id, make, model)
SELECT parts_id, coalesce(make, ''), coalesce(model, '')
FROM lsmb13.makemodel;

INSERT INTO transactions (id, table_name, locked_by)
SELECT id, table_name, locked_by FROM lsmb13.transactions;

INSERT INTO transactions (id, table_name)
SELECT id, 'ar' FROM ar WHERE id not in (select id from transactions);
INSERT INTO transactions (id, table_name)
SELECT id, 'ap' FROM ap WHERE id not in (select id from transactions);
INSERT INTO transactions (id, table_name)
SELECT id, 'gl' FROM gl WHERE id not in (select id from transactions);


ALTER TABLE gl DISABLE TRIGGER gl_track_global_sequence;
ALTER TABLE gl DISABLE TRIGGER gl_prevent_closed;
ALTER TABLE gl DISABLE TRIGGER gl_audit_trail;
INSERT INTO gl (
 id, reference, description, transdate, person_id, notes, approved
)
SELECT id, reference, description, transdate,
       coalesce(person_id, (select id from person
                            where id = (select min(entity_id) from users))),
       notes, approved
  FROM lsmb13.gl;
ALTER TABLE gl ENABLE TRIGGER gl_track_global_sequence;
ALTER TABLE gl ENABLE TRIGGER gl_prevent_closed;
ALTER TABLE gl ENABLE TRIGGER gl_audit_trail;


INSERT INTO gifi SELECT * FROM lsmb13.gifi;

UPDATE defaults d
   SET value = (select value from lsmb13.defaults od
                where d.setting_key = od.setting_key)
 WHERE setting_key <> 'version';
INSERT INTO defaults (setting_key, value)
SELECT setting_key, value FROM lsmb13.defaults
 WHERE setting_key NOT IN (select setting_key from defaults);

UPDATE lsmb13.batch SET locked_by = NULL;
INSERT INTO batch SELECT * FROM lsmb13.batch;

ALTER TABLE ar DISABLE TRIGGER ar_track_global_sequence;
ALTER TABLE ar DISABLE TRIGGER ar_prevent_closed;
ALTER TABLE ar DISABLE TRIGGER ar_audit_trail;
INSERT INTO ar (
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 shippingpoint,
 terms,
 notes,
 curr,
 ordnumber,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 on_hold,
 reverse,
 approved,
 entity_credit_account,
 force_closed,
 description,
 crdate
)
SELECT
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 shippingpoint,
 terms,
 notes,
 curr,
 ordnumber,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 on_hold,
 reverse,
 approved,
 entity_credit_account,
 force_closed,
 description,
 crdate
  FROM lsmb13.ar;
ALTER TABLE ar ENABLE TRIGGER ar_track_global_sequence;
ALTER TABLE ar ENABLE TRIGGER ar_prevent_closed;
ALTER TABLE ar ENABLE TRIGGER ar_audit_trail;

ALTER TABLE ap DISABLE TRIGGER ap_track_global_sequence;
ALTER TABLE ap DISABLE TRIGGER ap_prevent_closed;
ALTER TABLE ap DISABLE TRIGGER ap_audit_trail;
INSERT INTO ap (
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded ,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 ordnumber,
 curr,
 notes,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 shippingpoint,
 on_hold,
 approved,
 reverse,
 terms,
 description,
 force_closed,
 entity_credit_account,
 crdate
)
SELECT
 id,
 invnumber,
 transdate,
 --entity_id, --tshvr4 might may be dropped
 taxincluded ,
 amount,
 netamount,
 paid,
 datepaid,
 duedate,
 invoice,
 ordnumber,
 curr,
 notes,
 person_id,
 till,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 shippingpoint,
 on_hold,
 approved,
 reverse,
 terms,
 description,
 force_closed,
 entity_credit_account,
 crdate
  FROM lsmb13.ap;
ALTER TABLE ap ENABLE TRIGGER ap_track_global_sequence;
ALTER TABLE ap ENABLE TRIGGER ap_prevent_closed;
ALTER TABLE ap ENABLE TRIGGER ap_audit_trail;

INSERT INTO voucher SELECT * FROM lsmb13.voucher;

ALTER TABLE acc_trans DISABLE TRIGGER acc_trans_prevent_closed;
INSERT INTO acc_trans (
 trans_id,
 chart_id,
 amount,
 transdate,
 source,
 cleared,
 fx_transaction,
 memo,
 approved,
 cleared_on,
 reconciled_on,
 voucher_id,
 entry_id
) SELECT
 trans_id,
 chart_id,
 amount,
 transdate,
 source,
 cleared,
 fx_transaction,
 memo,
 approved,
 cleared_on,
 reconciled_on,
 voucher_id,
 entry_id
   FROM lsmb13.acc_trans;
ALTER TABLE acc_trans ENABLE TRIGGER acc_trans_prevent_closed;

UPDATE lsmb13.invoice i SET parts_id = null
 WHERE NOT EXISTS (select 1 from lsmb13.parts p where i.parts_id = p.id);
INSERT INTO invoice (
 id,
 trans_id,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 precision,
 fxsellprice,
 discount,
 assemblyitem,
 unit,
 deliverydate,
 serialnumber,
 notes
)
SELECT
 id,
 trans_id,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 precision,
 fxsellprice,
 discount,
 assemblyitem,
 unit,
 deliverydate,
 serialnumber,
 notes
  FROM lsmb13.invoice;

UPDATE acc_trans ac
   SET invoice_id = (select invoice_id from lsmb13.acc_trans a where a.entry_id = ac.entry_id);

--INSERT INTO payment_map SELECT * FROM lsmb13.payment_map;
INSERT INTO assembly SELECT * FROM lsmb13.assembly;
INSERT INTO taxcategory SELECT * FROM lsmb13.taxcategory;
INSERT INTO partstax SELECT * FROM lsmb13.partstax;
INSERT INTO tax (
 chart_id,
 rate,
 taxnumber,
 validto,
 pass,
 taxmodule_id,
 minvalue,
 maxvalue
)
SELECT
 chart_id,
 rate,
 taxnumber,
 validto,
 pass,
 taxmodule_id,
 minvalue,
 maxvalue
  FROM lsmb13.tax;

INSERT INTO eca_tax SELECT * FROM lsmb13.customertax
UNION SELECT * FROM lsmb13.vendortax;
INSERT INTO oe (
 id,
 ordnumber,
 transdate,
 entity_id,
 amount,
 netamount,
 reqdate,
 taxincluded,
 shippingpoint,
 notes,
 curr,
 person_id,
 closed,
 quotation,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 terms,
 entity_credit_account,
 oe_class_id
)
SELECT
 id,
 ordnumber,
 transdate,
 entity_id,
 amount,
 netamount,
 reqdate,
 taxincluded,
 shippingpoint,
 notes,
 curr,
 person_id,
 closed,
 quotation,
 quonumber,
 intnotes,
 shipvia,
 language_code,
 ponumber,
 terms,
 entity_credit_account,
 oe_class_id
  FROM lsmb13.oe;


UPDATE lsmb13.orderitems o SET parts_id = null
 WHERE NOT EXISTS (select 1 from lsmb13.parts p where o.parts_id = p.id);
INSERT INTO orderitems(
 id,
 trans_id,
 parts_id,
 description,
 qty,
 sellprice,
 precision,
 discount,
 unit,
 reqdate,
 ship,
 serialnumber,
 notes
)
SELECT
 id,
 trans_id,
 parts_id,
 description,
 qty,
 sellprice,
 precision,
 discount,
 unit,
 reqdate,
 ship,
 serialnumber,
 notes
  FROM lsmb13.orderitems;

INSERT INTO exchangerate SELECT * FROM lsmb13.exchangerate;

INSERT INTO business_unit (id, class_id, control_code, description)
SELECT id, 1, description, description
  FROM lsmb13.department;
UPDATE business_unit_class
   SET active = true
 WHERE id = 1
   AND EXISTS (select 1 from lsmb13.department);

INSERT INTO business_unit
       (id, class_id, control_code, description, start_date, end_date,
       credit_id)
SELECT id + 1000, 2, projectnumber, description, startdate, enddate,
        credit_id from lsmb13.project;
UPDATE business_unit_class
   SET active = true
 WHERE id = 2
   AND EXISTS (select 1 from lsmb13.project);

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT ac.entry_id, 1, gl.department_id
  FROM acc_trans ac
  JOIN (SELECT id, department_id FROM lsmb13.ar UNION ALL
        SELECT id, department_id FROM lsmb13.ap UNION ALL
        SELECT id, department_id FROM lsmb13.gl) gl ON gl.id = ac.trans_id
 WHERE department_id > 0;

INSERT INTO business_unit_ac (entry_id, class_id, bu_id)
SELECT entry_id, 2, project_id + 1000 FROM lsmb13.acc_trans
 WHERE project_id > 0 and project_id in (select id from lsmb13.project);

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT inv.id, 1, gl.department_id
  FROM invoice inv
  JOIN (SELECT id, department_id FROM lsmb13.ar UNION ALL
        SELECT id, department_id FROM lsmb13.ap UNION ALL
        SELECT id, department_id FROM lsmb13.gl) gl ON gl.id = inv.trans_id
 WHERE department_id > 0;

INSERT INTO business_unit_inv (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM lsmb13.invoice
 WHERE project_id > 0 and  project_id in (select id from lsmb13.project);

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT oi.id, 1, oe.department_id
  FROM orderitems oi
  JOIN lsmb13.oe ON oi.trans_id = oe.id AND department_id > 0;

INSERT INTO business_unit_oitem (entry_id, class_id, bu_id)
SELECT id, 2, project_id + 1000 FROM lsmb13.orderitems
 WHERE project_id > 0  and  project_id in (select id from lsmb13.project);

INSERT INTO partsgroup SELECT * FROM lsmb13.partsgroup;
INSERT INTO status SELECT * FROM lsmb13.status;
INSERT INTO business SELECT * FROM lsmb13.business;
INSERT INTO sic SELECT * FROM lsmb13.sic;
INSERT INTO warehouse SELECT * FROM lsmb13.warehouse;
INSERT INTO warehouse_inventory SELECT * FROM lsmb13.inventory;
INSERT INTO yearend SELECT * FROM lsmb13.yearend;
INSERT INTO partsvendor SELECT * FROM lsmb13.partsvendor;
INSERT INTO partscustomer SELECT * FROM lsmb13.partscustomer;

INSERT INTO audittrail SELECT * FROM lsmb13.audittrail where person_id is not null;
INSERT INTO translation SELECT * FROM lsmb13.translation;
INSERT INTO parts_translation SELECT * FROM lsmb13.parts_translation;
INSERT INTO user_preference
SELECT id, language, stylesheet, printer, dateformat, numberformat
  FROM lsmb13.user_preference;
update user_preference set dateformat = dateformat || 'yy' where length(dateformat) = 8;

INSERT INTO recurring (id, reference, startdate, nextdate,
                       enddate, howmany, payment, recurring_interval)
 SELECT id, reference, startdate, nextdate, enddate, howmany, payment,
        (repeat || ' ' || unit)::interval as recurring_interval
   FROM lsmb13.recurring;
INSERT INTO payment_type SELECT * FROM lsmb13.payment_type;
INSERT INTO recurringemail SELECT * FROM lsmb13.recurringemail;
INSERT INTO recurringprint SELECT * FROM lsmb13.recurringprint;


UPDATE lsmb13.jcitems j SET parts_id = null
 WHERE NOT EXISTS (select 1 from lsmb13.parts p where j.parts_id = p.id);
INSERT INTO jcitems (
 id,
 business_unit_id,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 fxsellprice,
 serialnumber,
 checkedin,
 checkedout,
 person_id,
 notes,
 total,
 non_billable,
 jctype,
 curr
)
SELECT
 id,
 project_id + 1000,
 parts_id,
 description,
 qty,
 allocated,
 sellprice,
 fxsellprice,
 serialnumber,
 checkedin,
 checkedout,
 person_id,
 notes,
 total,
 non_billable,
 1,
  (SELECT (string_to_array(value, ':'))[1]
     FROM lsmb13.defaults WHERE setting_key = 'curr')
  FROM lsmb13.jcitems
 WHERE project_id IN (select id from lsmb13.project);
INSERT INTO ac_tax_form SELECT * FROM lsmb13.ac_tax_form;
INSERT INTO invoice_tax_form SELECT * FROM lsmb13.invoice_tax_form;
INSERT INTO new_shipto SELECT * FROM lsmb13.new_shipto;
INSERT INTO tax_extended SELECT * FROM lsmb13.tax_extended;
INSERT INTO asset_class SELECT * FROM lsmb13.asset_class;
INSERT INTO asset_item SELECT * FROM lsmb13.asset_item;
INSERT INTO asset_note SELECT * FROM lsmb13.asset_note;
INSERT INTO asset_report SELECT * FROM lsmb13.asset_report;
INSERT INTO asset_report_line SELECT * FROM lsmb13.asset_report_line;
INSERT INTO asset_rl_to_disposal_method SELECT * FROM lsmb13.asset_rl_to_disposal_method;
DELETE FROM mime_type;
INSERT INTO mime_type SELECT * FROM lsmb13.mime_type;
INSERT INTO file_base SELECT * FROM ONLY lsmb13.file_base;
INSERT INTO file_transaction SELECT * FROM lsmb13.file_transaction;
INSERT INTO file_order SELECT * FROM lsmb13.file_order;
INSERT INTO file_secondary_attachment SELECT * FROM lsmb13.file_secondary_attachment;
INSERT INTO file_tx_to_order SELECT * FROM lsmb13.file_tx_to_order;
INSERT INTO file_order_to_order SELECT * FROM lsmb13.file_order_to_order;
INSERT INTO file_order_to_tx SELECT * FROM lsmb13.file_order_to_tx;
INSERT INTO payment (
 id,
 reference,
 gl_id,
 payment_class,
 payment_date,
 closed,
 entity_credit_id,
 employee_id,
 currency,
 notes
)
SELECT
 id,
 reference,
 gl_id,
 payment_class,
 payment_date,
 closed,
 entity_credit_id,
 employee_id,
 currency,
 notes
  FROM lsmb13.payment;

INSERT INTO payment_links SELECT * FROM lsmb13.payment_links;
INSERT INTO cr_report SELECT * FROM lsmb13.cr_report;
INSERT INTO cr_report_line SELECT * FROM lsmb13.cr_report_line;
INSERT INTO cr_coa_to_account SELECT * FROM lsmb13.cr_coa_to_account;

SELECT setval('id', max(id)) FROM transactions;

 SELECT setval('acc_trans_entry_id_seq', max(entry_id)) FROM acc_trans;
 SELECT setval('partsvendor_entry_id_seq', max(entry_id)) FROM partsvendor;
 SELECT setval('warehouse_inventory_entry_id_seq', max(entry_id))
        FROM warehouse_inventory;
 SELECT setval('partscustomer_entry_id_seq', max(entry_id)) FROM partscustomer;
 SELECT setval('audittrail_entry_id_seq', max(entry_id)) FROM audittrail;
 SELECT setval('account_id_seq', max(id)) FROM account;
 SELECT setval('account_heading_id_seq', max(id)) FROM account_heading;
 SELECT setval('account_checkpoint_id_seq', max(id)) FROM account_checkpoint;
 SELECT setval('pricegroup_id_seq', max(id)) FROM pricegroup;
 SELECT setval('country_id_seq', max(id)) FROM country;
 SELECT setval('country_tax_form_id_seq', max(id)) FROM country_tax_form;
 SELECT setval('asset_dep_method_id_seq', max(id)) FROM asset_dep_method;
 SELECT setval('asset_class_id_seq', max(id)) FROM asset_class;
 SELECT setval('entity_class_id_seq', max(id)) FROM entity_class;
 SELECT setval('asset_item_id_seq', max(id)) FROM asset_item;
 SELECT setval('asset_disposal_method_id_seq', max(id)) FROM asset_disposal_method;
 SELECT setval('users_id_seq', max(id)) FROM users;
 SELECT setval('entity_id_seq', max(id)) FROM entity;
 SELECT setval('company_id_seq', max(id)) FROM company;
 SELECT setval('location_id_seq', max(id)) FROM location;
 SELECT setval('location_class_id_seq', max(id)) FROM location_class;
 SELECT setval('asset_report_id_seq', max(id)) FROM asset_report;
 SELECT setval('salutation_id_seq', max(id)) FROM salutation;
 SELECT setval('person_id_seq', max(id)) FROM person;
 SELECT setval('contact_class_id_seq', max(id)) FROM contact_class;
 SELECT setval('entity_credit_account_id_seq', max(id)) FROM entity_credit_account;
 SELECT setval('entity_bank_account_id_seq', max(id)) FROM entity_bank_account;
 SELECT setval('note_class_id_seq', max(id)) FROM note_class;
 SELECT setval('note_id_seq', max(id)) FROM note;
 SELECT setval('batch_class_id_seq', max(id)) FROM batch_class;
 SELECT setval('file_base_id_seq', max(id)) FROM file_base;
 SELECT setval('batch_id_seq', max(id)) FROM batch;
 SELECT setval('invoice_id_seq', max(id)) FROM invoice;
 SELECT setval('voucher_id_seq', max(id)) FROM voucher;
 SELECT setval('parts_id_seq', max(id)) FROM parts;
 SELECT setval('taxmodule_taxmodule_id_seq', max(taxmodule_id)) FROM taxmodule;
 SELECT setval('taxcategory_taxcategory_id_seq', max(taxcategory_id)) FROM taxcategory;
 SELECT setval('oe_id_seq', max(id)) FROM oe;
 SELECT setval('orderitems_id_seq', max(id)) FROM orderitems;
 SELECT setval('business_id_seq', max(id)) FROM business;
 SELECT setval('warehouse_id_seq', max(id)) FROM warehouse;
 SELECT setval('partsgroup_id_seq', max(id)) FROM partsgroup;
 SELECT setval('jcitems_id_seq', max(id)) FROM jcitems;
 SELECT setval('payment_type_id_seq', max(id)) FROM payment_type;
 SELECT setval('menu_node_id_seq', max(id)) FROM menu_node;
 SELECT setval('menu_attribute_id_seq', max(id)) FROM menu_attribute;
 SELECT setval('menu_acl_id_seq', max(id)) FROM menu_acl;
 SELECT setval('new_shipto_id_seq', max(id)) FROM new_shipto;
 SELECT setval('payment_id_seq', max(id)) FROM payment;
 SELECT setval('cr_report_id_seq', max(id)) FROM cr_report;
 SELECT setval('cr_report_line_id_seq', max(id)) FROM cr_report_line;

update defaults set value = 'yes' where setting_key = 'migration_ok';

COMMIT;
