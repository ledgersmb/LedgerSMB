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