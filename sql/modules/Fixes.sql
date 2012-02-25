-- SQL Fixes for upgrades.  These must be safe to run repeatedly, or they must 
-- fail transactionally.  Please:  one transaction per fix.  
--
-- Chris Travers


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
UPDATE update menu_node set position = 3 where position = 2 and parent = 229;
update menu_node set parent = 229 where id = 233;
COMMIT;
