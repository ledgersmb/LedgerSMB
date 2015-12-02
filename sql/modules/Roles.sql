BEGIN;

DELETE FROM menu_acl WHERE node_id in (206, 210);

DROP FUNCTION IF EXISTS lsmb__create_role(text);
CREATE OR REPLACE FUNCTION lsmb__create_role(in_role text) RETURNS bool
LANGUAGE PLPGSQL AS
$$
BEGIN
  PERFORM * FROM pg_roles WHERE rolname = lsmb__role(in_role);
  IF FOUND THEN
     RETURN TRUE;
  END IF;

  EXECUTE 'CREATE ROLE ' || quote_ident(lsmb__role(in_role))
  || ' WITH INHERIT NOLOGIN';

  RETURN TRUE;
END;
$$ SECURITY INVOKER; -- intended only to be used for setup scripts

DROP FUNCTION IF EXISTS lsmb__grant_role(text, text);
CREATE OR REPLACE FUNCTION lsmb__grant_role(in_child text, in_parent text)
RETURNS BOOL LANGUAGE PLPGSQL SECURITY INVOKER AS
$$
BEGIN
   EXECUTE 'GRANT ' || quote_ident(lsmb__role(in_parent)) || ' TO '
   || quote_ident(lsmb__role(in_child));
   RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION lsmb__grant_exec(in_role text, in_func text)
RETURNS BOOL LANGUAGE PLPGSQL SECURITY INVOKER AS
$$
BEGIN
   EXECUTE 'GRANT EXECUTE ON FUNCTION ' || in_func || ' TO '
   || quote_ident(lsmb__role(in_role));
   RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION lsmb__grant_perms
(in_role text, in_table text, in_perms text) RETURNS BOOL
SECURITY INVOKER
LANGUAGE PLPGSQL AS
$$
BEGIN
   IF upper(in_perms) NOT IN ('ALL', 'INSERT', 'UPDATE', 'SELECT', 'DELETE') THEN
      RAISE EXCEPTION 'Invalid permission';
   END IF;
   EXECUTE 'GRANT ' || in_perms || ' ON ' || quote_ident(in_table)
   || ' TO ' ||  quote_ident(lsmb__role(in_role));

   RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION quote_ident_array(text[]) returns text[]
language sql as $$
   SELECT array_agg(quote_ident(e))
     FROM unnest($1) e;
$$;

CREATE OR REPLACE FUNCTION lsmb__grant_perms
(in_role text, in_table text, in_perms text, in_cols text[]) RETURNS BOOL
SECURITY INVOKER
LANGUAGE PLPGSQL AS
$$
BEGIN
   IF upper(in_perms) NOT IN ('ALL', 'INSERT', 'UPDATE', 'SELECT', 'DELETE') THEN
      RAISE EXCEPTION 'Invalid permission';
   END IF;
   EXECUTE 'GRANT ' || in_perms
   || '(' || array_to_string(quote_ident_array(in_cols), ', ')
   || ') ON ' || quote_ident(in_table)|| ' TO '
   ||  quote_ident(lsmb__role(in_role));
   RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION lsmb__grant_menu
(in_role text, in_node_id int, in_perm_type text)
RETURNS BOOL
LANGUAGE PLPGSQL SECURITY INVOKER AS
$$
BEGIN
   PERFORM * FROM pg_roles WHERE rolname = lsmb__role(in_role);
   IF NOT FOUND THEN
      RAISE EXCEPTION 'Role not found';
   END IF;
   PERFORM * FROM menu_attribute
     WHERE attribute = 'menu' AND node_id = in_node_id;
   IF FOUND THEN
      RAISE EXCEPTION 'Cannot grant to submenu';
   END IF;
   IF in_perm_type NOT IN ('allow', 'deny') THEN
      RAISE EXCEPTION 'Invalid perm type';
   END IF;
   PERFORM * FROM menu_acl
     WHERE node_id = in_node_id AND role_name = lsmb__role(in_role)
           AND acl_type = in_perm_type;
   IF FOUND THEN RETURN TRUE;
   END IF;
   INSERT INTO menu_acl (node_id, role_name, acl_type)
   VALUES (in_node_id, lsmb__role(in_role), in_perm_type);
   RETURN TRUE;
END;
$$;

GRANT ALL ON SCHEMA public TO public;

\echo BASE ROLES
SELECT lsmb__create_role('base_user');

\echo BUDGETS
SELECT lsmb__create_role('budget_enter');
SELECT lsmb__create_role('budget_view');
SELECT lsmb__create_role('budget_approve');
SELECT lsmb__grant_role('budget_approve', 'budget_view');
SELECT lsmb__create_role('budget_obsolete');

SELECT lsmb__grant_role('budget_obsolete', 'budget_view');
SELECT lsmb__grant_perms('budget_view', 'budget_info', 'SELECT');
SELECT lsmb__grant_perms('budget_view', 'budget_line', 'SELECT');
SELECT lsmb__grant_perms('budget_enter', 'budget_info', 'INSERT');
SELECT lsmb__grant_perms('budget_enter', 'budget_to_business_unit', 'INSERT');
SELECT lsmb__grant_perms('budget_enter', 'budget_line', 'INSERT');
SELECT lsmb__grant_perms('budget_enter', 'budget_note', 'INSERT');
SELECT lsmb__grant_exec('budget_enter', ' budget__save_info(integer,date,date,text,text,integer[])');
SELECT lsmb__grant_perms('budget_approve', 'budget_info', 'UPDATE',
       array['approved_at'::text, 'approved_by']);
SELECT lsmb__grant_perms('budget_obsolete', 'budget_info', 'UPDATE',
       array['approved_at'::text, 'approved_by']);

SELECT lsmb__grant_menu('budget_enter', 252, 'allow');
SELECT lsmb__grant_menu('budget_view', 253, 'allow');

SELECT lsmb__grant_exec('budget_approve', 'budget__reject(in_id int)');

\echo BUSINESS UNITS
SELECT lsmb__create_role('business_units_manage');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit_class',
       'INSERT');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit_class',
       'UPDATE');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit_class',
       'DELETE');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit', 'INSERT');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit', 'UPDATE');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit', 'DELETE');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit_id_seq', 'ALL');
SELECT lsmb__grant_perms('business_units_manage', 'business_unit_class_id_seq', 'ALL');
SELECT lsmb__grant_perms('business_units_manage', 'bu_class_to_module',
       'INSERT');
SELECT lsmb__grant_perms('business_units_manage', 'bu_class_to_module',
       'UPDATE');
SELECT lsmb__grant_perms('business_units_manage', 'bu_class_to_module',
       'DELETE');
SELECT lsmb__grant_menu('business_units_manage', 144, 'allow');

GRANT SELECT ON business_unit_class, business_unit, bu_class_to_module
   TO PUBLIC;

\echo Exchange rate creation (requires insert/update on exchangerate table)
SELECT lsmb__create_role('exchangerate_edit');
SELECT lsmb__grant_perms('exchangerate_edit', 'exchangerate', 'INSERT');
SELECT lsmb__grant_perms('exchangerate_edit', 'exchangerate', 'UPDATE');

\echo Basic file attachments
SELECT lsmb__create_role('file_read');
SELECT lsmb__grant_perms('file_read', 'file_base', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_eca', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_entity', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_incoming', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_internal', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_links', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_order', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_part', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_secondary_attachment', 'SELECT');
SELECT lsmb__grant_perms('file_read', 'file_transaction', 'SELECT');


SELECT lsmb__create_role('file_attach_tx');
SELECT lsmb__grant_perms('file_attach_tx', 'file_transaction', 'INSERT');
SELECT lsmb__grant_perms('file_attach_tx', 'file_transaction', 'UPDATE');
SELECT lsmb__grant_perms('file_attach_tx', 'file_order_to_tx', 'INSERT');
SELECT lsmb__grant_perms('file_attach_tx', 'file_order_to_tx', 'UPDATE');

SELECT lsmb__create_role('file_attach_order');
SELECT lsmb__grant_perms('file_attach_order', 'file_order', 'INSERT');
SELECT lsmb__grant_perms('file_attach_order', 'file_order', 'UPDATE');
SELECT lsmb__grant_perms('file_attach_order', 'file_order_to_order', 'INSERT');
SELECT lsmb__grant_perms('file_attach_order', 'file_order_to_order', 'UPDATE');
SELECT lsmb__grant_perms('file_attach_order', 'file_tx_to_order', 'INSERT');
SELECT lsmb__grant_perms('file_attach_order', 'file_tx_to_order', 'UPDATE');

SELECT lsmb__create_role('file_attach_part');
SELECT lsmb__grant_perms('file_attach_part', 'file_part', 'INSERT');
SELECT lsmb__grant_perms('file_attach_part', 'file_part', 'UPDATE');

SELECT lsmb__create_role('file_attach_eca');
SELECT lsmb__grant_perms('file_attach_eca', 'file_eca', 'INSERT');
SELECT lsmb__grant_perms('file_attach_eca', 'file_eca', 'UPDATE');

SELECT lsmb__create_role('file_attach_entity');
SELECT lsmb__grant_perms('file_attach_entity', 'file_entity', 'INSERT');
SELECT lsmb__grant_perms('file_attach_entity', 'file_entity', 'UPDATE');

SELECT lsmb__grant_perms(role, 'file_incoming', 'DELETE'),
       lsmb__grant_perms(role, 'file_base_id_seq', 'ALL')
  FROM unnest(ARRAY['file_attach_tx'::text, 'file_attach_order',
                    'file_attach_part', 'file_attach_eca']) role;

\echo Contact Management
SELECT lsmb__create_role('contact_read');
SELECT lsmb__grant_perms('contact_read', 'partsvendor', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'partscustomer', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'taxcategory', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'company', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'location', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'person', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_credit_account', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_to_location', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'eca_tax', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'contact_class', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_class', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_bank_account', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_note', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_other_name', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'location_class', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'person_to_company', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_to_contact', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'entity_to_location', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'eca_to_location', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'eca_to_contact', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'eca_note', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'pricegroup', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'file_eca', 'SELECT');
SELECT lsmb__grant_perms('contact_read', 'file_entity', 'SELECT');
SELECT lsmb__grant_exec('contact_read', 'eca__list_notes(int)');
SELECT lsmb__grant_menu('contact_read', 14, 'allow');

SELECT lsmb__create_role('contact_class_vendor');
SELECT lsmb__create_role('contact_class_customer');
SELECT lsmb__create_role('contact_class_employee');
SELECT lsmb__create_role('contact_class_contact');
SELECT lsmb__create_role('contact_class_referral');
SELECT lsmb__create_role('contact_class_lead');
SELECT lsmb__create_role('contact_class_hot_lead');
SELECT lsmb__create_role('contact_class_cold_lead');

SELECT lsmb__create_role('contact_create');
SELECT lsmb__grant_role('contact_create', 'contact_read');
SELECT lsmb__grant_perms('contact_create', 'entity', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'entity_id_seq', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'company', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'company_id_seq', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'location', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'location_id_seq', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'person', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'person_id_seq', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'entity_credit_account', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'entity_credit_account_id_seq', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'note_id_seq', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'entity_bank_account', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'entity_bank_account_id_seq', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'entity_to_location', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'eca_tax', 'ALL');
SELECT lsmb__grant_perms('contact_create', 'entity_note', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'entity_other_name', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'person_to_company', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'entity_to_contact', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'entity_to_location', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'entity_to_location', 'DELETE');
SELECT lsmb__grant_perms('contact_create', 'eca_to_location', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'eca_to_location', 'DELETE');
SELECT lsmb__grant_perms('contact_create', 'eca_to_contact', 'INSERT');
SELECT lsmb__grant_perms('contact_create', 'eca_note', 'INSERT');
SELECT lsmb__grant_perms('contact_create', obj, 'ALL')
  FROM unnest(array['partsvendor_entry_id_seq'::text,
                    'partscustomer_entry_id_seq']) obj;

SELECT lsmb__grant_menu('contact_create', 12, 'allow');

SELECT lsmb__create_role('employees_manage');
SELECT lsmb__grant_role('employees_manage', 'contact_read');
SELECT lsmb__grant_perms('employees_manage', 'entity_employee', 'ALL');
SELECT lsmb__grant_perms('employees_manage', 'person', 'ALL');
SELECT lsmb__grant_perms('employees_manage', 'entity', 'ALL');
SELECT lsmb__grant_perms('employees_manage', 'entity_id_seq', 'ALL');
SELECT lsmb__grant_perms('employees_manage', 'payroll_income_type', 'ALL');
SELECT lsmb__grant_perms('employees_manage', 'payroll_deduction_type', 'ALL');
SELECT lsmb__grant_perms('employees_manage', 'payroll_wage', 'ALL');
SELECT lsmb__grant_perms('employees_manage', 'payroll_deduction', 'ALL');
SELECT lsmb__grant_menu('employees_manage', 48, 'allow');
SELECT lsmb__grant_menu('employees_manage', 49, 'allow');

SELECT lsmb__create_role('contact_edit');
SELECT lsmb__grant_role('contact_edit', 'contact_read');
SELECT lsmb__grant_perms('contact_edit', 'entity', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'company', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'location', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'person', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'entity_credit_account', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'entity_to_location', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'eca_tax', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'entity_bank_account', 'ALL');
SELECT lsmb__grant_perms('contact_edit', 'entity_note', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'entity_other_name', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'person_to_company', 'UPDATE');
SELECT lsmb__grant_perms('contact_edit', 'entity_to_contact', 'ALL');
SELECT lsmb__grant_perms('contact_edit', 'eca_to_contact', 'ALL');
SELECT lsmb__grant_perms('contact_edit', 'eca_to_location', 'ALL');
SELECT lsmb__grant_perms('contact_edit', 'eca_tax', 'ALL');

SELECT lsmb__create_role('contact_delete');
SELECT lsmb__grant_perms('contact_delete', obj, 'DELETE')
  FROM unnest(ARRAY['entity'::text, 'company', 'person', 'location',
                    'entity_credit_account', 'eca_tax', 'entity_note',
                    'eca_note', 'entity_to_location', 'eca_to_location',
                    'eca_to_contact', 'entity_to_contact', 'entity_other_name',
                    'entity_bank_account', 'person_to_company']) obj;

SELECT lsmb__create_role('contact_all_rights');
SELECT lsmb__grant_role('contact_all_rights', 'contact_create');
SELECT lsmb__grant_role('contact_all_rights', 'contact_edit');
SELECT lsmb__grant_role('contact_all_rights', 'contact_read');
SELECT lsmb__grant_role('contact_all_rights', 'contact_delete');

\echo Batches and Vouchers
SELECT lsmb__create_role('batch_create');
SELECT lsmb__grant_perms('batch_create', 'batch', 'INSERT');
SELECT lsmb__grant_perms('batch_create', 'batch_id_seq', 'ALL');
SELECT lsmb__grant_perms('batch_create', 'batch_class', 'SELECT');
SELECT lsmb__grant_perms('batch_create', 'voucher', 'INSERT');
SELECT lsmb__grant_perms('batch_create', 'voucher_id_seq', 'ALL');
SELECT lsmb__grant_exec('batch_create', 'batch__lock_for_update(int)');

SELECT lsmb__create_role('batch_post');
SELECT lsmb__grant_exec('batch_post', 'batch_post(int)');
SELECT lsmb__grant_menu('batch_post', 206, 'allow');
SELECT lsmb__grant_menu('batch_post', 210, 'allow');

SELECT lsmb__create_role('voucher_delete');
SELECT lsmb__grant_exec('voucher_delete', 'voucher__delete(int)');
SELECT lsmb__grant_exec('voucher_delete', 'batch_delete(int)');

SELECT lsmb__create_role('draft_modify');
SELECT lsmb__create_role('draft_post');
SELECT lsmb__grant_menu('draft_post', 210, 'allow');


\echo AR
SELECT lsmb__create_role('ar_transaction_create');
SELECT lsmb__grant_role('ar_transaction_create', 'contact_read');
SELECT lsmb__grant_role('ar_transaction_create', 'exchangerate_edit');
SELECT lsmb__grant_perms('ar_transaction_create', 'ar', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'invoice_note', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'business_unit_ac', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'journal_entry', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'journal_entry', 'SELECT');
SELECT lsmb__grant_perms('ar_transaction_create', 'eca_invoice', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'eca_invoice', 'SELECT');
SELECT lsmb__grant_perms('ar_transaction_create', 'journal_line', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'journal_line', 'SELECT');
SELECT lsmb__grant_perms('ar_transaction_create', 'business_unit_jl', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'oe', 'SELECT');
SELECT lsmb__grant_perms('ar_transaction_create', 'id', 'ALL');
SELECT lsmb__grant_perms('ar_transaction_create', 'acc_trans', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create', 'acc_trans_entry_id_seq', 'ALL');
SELECT lsmb__grant_perms('ar_transaction_create', 'journal_entry_id_seq', 'ALL');
SELECT lsmb__grant_perms('ar_transaction_create', 'journal_line_id_seq', 'ALL');
SELECT lsmb__grant_menu('ar_transaction_create', 2, 'allow');
SELECT lsmb__grant_menu('ar_transaction_create', 129, 'allow');
SELECT lsmb__grant_menu('ar_transaction_create', 194, 'allow');

SELECT lsmb__create_role('ar_transaction_create_voucher');
SELECT lsmb__grant_role('ar_transaction_create_voucher', 'contact_read');
SELECT lsmb__grant_role('ar_transaction_create_voucher', 'batch_create');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'ar', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'warehouse_inventory', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'acc_trans', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'tax_extended', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'business_unit_ac', 'INSERT');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'id', 'all');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'invoice_id_seq', 'all');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'acc_trans_entry_id_seq', 'all');
SELECT lsmb__grant_perms('ar_transaction_create_voucher', 'warehouse_inventory_entry_id_seq', 'all');
SELECT lsmb__grant_menu('ar_transaction_create_voucher',198,'allow');
SELECT lsmb__grant_menu('ar_transaction_create_voucher',20,'allow');
SELECT lsmb__grant_menu('ar_transaction_create_voucher',11,'allow');
SELECT lsmb__grant_menu('ar_transaction_create_voucher',244,'allow');

SELECT lsmb__create_role('ar_invoice_create');
SELECT lsmb__grant_role('ar_invoice_create', 'ar_transaction_create');
-- ### old code needs update
SELECT lsmb__grant_perms('ar_invoice_create', tname, ptype)
  FROM unnest('{invoice,new_shipto,business_unit_inv}'::text[]) tname
 CROSS JOIN unnest('{SELECT,INSERT,UPDATE}'::text[]) ptype;
SELECT lsmb__grant_menu('ar_invoice_create', 3, 'allow');
SELECT lsmb__grant_menu('ar_invoice_create', 195, 'allow');

SELECT lsmb__create_role('ar_invoice_create_voucher');
SELECT lsmb__grant_role('ar_invoice_create_voucher', 'contact_read');
SELECT lsmb__grant_role('ar_invoice_create_voucher', 'batch_create');
SELECT lsmb__grant_role('ar_invoice_create_voucher', 'ar_transaction_create_voucher');
SELECT lsmb__grant_perms('ar_invoice_create_voucher', 'invoice', 'INSERT');
SELECT lsmb__grant_perms('ar_invoice_create_voucher', 'warehouse_inventory', 'INSERT');
SELECT lsmb__grant_perms('ar_invoice_create_voucher', 'invoice_id_seq', 'ALL');
SELECT lsmb__grant_perms('ar_invoice_create_voucher', 'warehouse_inventory_entry_id_seq', 'ALL');
-- TODO add Menu ACLs

SELECT lsmb__create_role('ar_transaction_list');
SELECT lsmb__grant_role('ar_transaction_list', 'contact_read');
SELECT lsmb__grant_role('ar_transaction_list', 'file_read');
SELECT lsmb__grant_perms('ar_transaction_list', tname, 'SELECT')
  FROM unnest(
         array['ar'::text, 'acc_trans', 'business_unit_ac', 'invoice',
               'business_unit_inv', 'warehouse_inventory', 'tax_extended', 'ac_tax_form',
               'invoice_tax_form']
       ) tname;

SELECT lsmb__grant_menu('ar_transaction_list', node_id, 'allow')
  FROM unnest( array[5,7,9,10,15]) node_id;

SELECT lsmb__create_role('ar_voucher_all');
SELECT lsmb__grant_role('ar_voucher_all', 'ar_transaction_create_voucher');
SELECT lsmb__grant_role('ar_voucher_all', 'ar_invoice_create_voucher');

SELECT lsmb__create_role('ar_transaction_all');
SELECT lsmb__grant_role('ar_transaction_all', rname)
  FROM unnest(ARRAY['ar_transaction_create'::text, 'ar_invoice_create',
                    'ar_transaction_list', 'file_attach_tx']) rname;

SELECT lsmb__create_role('sales_order_create');
SELECT lsmb__grant_role('sales_order_create', 'contact_read');
SELECT lsmb__grant_role('sales_order_create', 'exchangerate_edit');
SELECT lsmb__grant_perms('sales_order_create', obj, 'ALL')
  FROM unnest(array['oe'::text, 'oe_id_seq', 'warehouse_inventory', 'orderitems_id_seq'])
       obj;
SELECT lsmb__grant_perms('sales_order_create', 'oe_id_seq', 'ALL');
SELECT lsmb__grant_perms('sales_order_create', 'orderitems', 'INSERT');
SELECT lsmb__grant_perms('sales_order_create', 'orderitems', 'UPDATE');
SELECT lsmb__grant_perms('sales_order_create', 'business_unit_oitem', 'INSERT');
SELECT lsmb__grant_perms('sales_order_create', 'business_unit_oitem', 'UPDATE');
SELECT lsmb__grant_menu('sales_order_create', '51', 'allow');

SELECT lsmb__create_role('sales_order_edit');
SELECT lsmb__grant_perms('sales_order_edit', 'orderitems', 'DELETE');
SELECT lsmb__grant_perms('sales_order_edit', 'business_unit_oitem', 'DELETE');
SELECT lsmb__grant_perms('sales_order_edit', 'new_shipto', 'DELETE');

SELECT lsmb__create_role(dt || '_delete')
  FROM unnest(array['sales_order'::text, 'sales_quotation', 'purchase_order',
              'rfq']) dt;
SELECT lsmb__grant_perms(dt || '_delete', obj, 'DELETE')
  FROM unnest(ARRAY['oe'::TEXT, 'orderitems', 'business_unit_oitem',
                    'new_shipto']) obj
 CROSS
  JOIN unnest(array['sales_order'::text, 'sales_quotation', 'purchase_order',
              'rfq']) dt;

SELECT lsmb__create_role('sales_quotation_create');
SELECT lsmb__grant_role('sales_quotation_create', 'contact_read');
SELECT lsmb__grant_role('sales_quotation_create', 'exchangerate_edit');
SELECT lsmb__grant_perms('sales_quotation_create', obj, 'ALL')
  FROM unnest(array['oe'::text, 'oe_id_seq', 'orderitems_id_seq']) obj;

SELECT lsmb__grant_perms('sales_quotation_create', obj, ptype)
  FROM unnest(array['orderitems'::text, 'business_unit_oitem']) obj,
       unnest(array['INSERT'::text, 'UPDATE']) ptype;

SELECT lsmb__grant_menu('sales_quotation_create', 68, 'allow');

SELECT lsmb__create_role('sales_order_list');
SELECT lsmb__grant_role('sales_order_list', 'contact_read');
SELECT lsmb__grant_role('sales_order_list', 'file_read');
SELECT lsmb__grant_perms('sales_order_list', obj, 'SELECT')
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem']) obj;

SELECT lsmb__grant_menu('sales_order_list', 54, 'allow');

SELECT lsmb__create_role('sales_quotation_list');
SELECT lsmb__grant_role('sales_quotation_list', 'contact_read');
SELECT lsmb__grant_role('sales_quotation_list', 'file_read');
SELECT lsmb__grant_perms('sales_quotation_list', obj, 'SELECT')
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem']) obj;

SELECT lsmb__grant_menu('sales_quotation_list', 71, 'allow');

SELECT lsmb__create_role('ar_all');
SELECT lsmb__grant_role('ar_all', rname)
  FROM unnest(array['ar_voucher_all'::text, 'ar_transaction_all',
                    'file_attach_tx']) rname;

\echo AP
SELECT lsmb__create_role('ap_transaction_create');
SELECT lsmb__grant_role('ap_transaction_create', 'contact_read');
SELECT lsmb__grant_role('ap_transaction_create', 'exchangerate_edit');
SELECT lsmb__grant_perms('ap_transaction_create', obj, ptype)
  FROM unnest(array['ap'::text, 'invoice_note', 'journal_entry', 'journal_line',
                    'business_unit_jl']) obj
 CROSS JOIN unnest(array['SELECT'::text, 'INSERT']) ptype;

SELECT lsmb__grant_perms('ap_transaction_create', obj, 'ALL')
  FROM unnest(array['id'::text, 'acc_trans_entry_id_seq',
                    'journal_entry_id_seq', 'journal_line_id_seq']) obj;

SELECT lsmb__grant_perms('ap_transaction_create', 'acc_trans', 'INSERT');
SELECT lsmb__grant_perms('ap_transaction_create', 'business_unit_ac', 'INSERT');
SELECT lsmb__grant_perms('ap_transaction_create', 'oe', 'SELECT');
SELECT lsmb__grant_menu('ap_transaction_create', node_id, 'allow')
  FROM unnest(array[13,22,196]) node_id;

SELECT lsmb__create_role('ap_transaction_create_voucher');
SELECT lsmb__grant_role('ap_transaction_create_voucher', 'contact_read');
SELECT lsmb__grant_role('ap_transaction_create_voucher', 'batch_create');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'oe', 'SELECT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'business_unit_ac', 'INSERT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'acc_trans', 'INSERT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'journal_entry', 'INSERT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'journal_entry', 'SELECT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'journal_line', 'INSERT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'journal_line', 'SELECT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'eca_invoice', 'INSERT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', 'eca_invoice', 'SELECT');
SELECT lsmb__grant_perms('ap_transaction_create_voucher', obj, ptype)
  FROM unnest(array['ap'::text, 'invoice', 'business_unit_inv']) obj
 CROSS JOIN unnest(array['SELECT'::text, 'INSERT', 'UPDATE']) ptype;

SELECT lsmb__grant_perms('ap_transaction_create_voucher', obj, 'ALL')
  FROM unnest(array['id'::text, 'acc_trans_entry_id_seq']) obj;

SELECT lsmb__grant_menu('ap_transaction_create_voucher', node_id, 'allow')
  FROM unnest(array[199, 243, 39]) node_id;

SELECT lsmb__create_role('ap_invoice_create');
SELECT lsmb__grant_role('ap_invoice_create', 'ap_transaction_create');
SELECT lsmb__grant_perms('ap_invoice_create', obj, 'INSERT')
  FROM unnest(array['invoice'::text, 'business_unit_inv', 'warehouse_inventory',
                    'tax_extended']) obj;
SELECT lsmb__grant_perms('ap_invoice_create', obj, 'ALL')
  FROM unnest(array['warehouse_inventory_entry_id_seq'::text, 'invoice_id_seq']) obj;

SELECT lsmb__grant_menu('ap_invoice_create', node_id, 'allow')
  FROM unnest(array[23,197]) node_id;

SELECT lsmb__create_role('ap_invoice_create_voucher');
SELECT lsmb__grant_role('ap_invoice_create_voucher', 'contact_read');
SELECT lsmb__grant_role('ap_invoice_create_voucher', 'batch_create');
SELECT lsmb__grant_perms('ap_invoice_create_voucher', 'invoice', 'INSERT');
SELECT lsmb__grant_perms('ap_invoice_create_voucher', 'warehouse_inventory', 'INSERT');
SELECT lsmb__grant_perms('ap_invoice_create_voucher', 'invoice_id_seq', 'ALL');
SELECT lsmb__grant_perms('ap_invoice_create_voucher', 'warehouse_inventory_entry_id_seq', 'ALL');
-- TODO add Menu ACLs

SELECT lsmb__create_role('ap_transaction_list');
SELECT lsmb__grant_role('ap_transaction_list', 'contact_read');
SELECT lsmb__grant_role('ap_transaction_list', 'file_read');
SELECT lsmb__grant_perms('ap_transaction_list', obj, 'SELECT')
  FROM unnest(array['ap'::text, 'acc_trans', 'invoice', 'warehouse_inventory',
                    'tax_extended', 'ac_tax_form', 'invoice_tax_form']) obj;
SELECT lsmb__grant_menu('ap_transaction_list', node_id, 'allow')
  FROM unnest(array[25,27,34]) node_id;

SELECT lsmb__create_role('ap_all_vouchers');
SELECT lsmb__grant_role('ap_all_vouchers', 'ap_transaction_create_voucher');
SELECT lsmb__grant_role('ap_all_vouchers', 'ap_invoice_create_voucher');

SELECT lsmb__create_role('ap_all_transactions');
SELECT lsmb__grant_role('ap_all_transactions', 'ap_transaction_create');
SELECT lsmb__grant_role('ap_all_transactions', 'ap_invoice_create');
SELECT lsmb__grant_role('ap_all_transactions', 'ap_transaction_list');

SELECT lsmb__create_role('ap_transaction_all');
SELECT lsmb__grant_role('ap_transaction_all', rname)
  FROM unnest(array['ap_transaction_create'::text, 'ap_invoice_create',
                    'ap_transaction_list', 'file_attach_tx', 'exchangerate_edit'
             ]) rname;

SELECT lsmb__create_role('purchase_order_create');
SELECT lsmb__grant_role('purchase_order_create', 'contact_read');
SELECT lsmb__grant_perms('purchase_order_create', obj, ptype)
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem']) obj
 CROSS JOIN unnest(array['INSERT'::text, 'UPDATE']) ptype;

SELECT lsmb__grant_perms('purchase_order_create', obj, 'ALL')
  FROM unnest(array['oe_id_seq'::text, 'orderitems_id_seq', 'warehouse_inventory',
                    'warehouse_inventory_entry_id_seq']) obj;
SELECT lsmb__grant_menu('purchase_order_create', 52, 'allow');

SELECT lsmb__create_role('purchase_order_edit');
SELECT lsmb__grant_perms('purchase_order_edit', obj, 'DELETE')
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem',
                    'new_shipto']) obj;

SELECT lsmb__create_role('rfq_create');
SELECT lsmb__grant_role('rfq_create', 'contact_read');
SELECT lsmb__grant_role('rfq_create', 'exchangerate_edit');
SELECT lsmb__grant_menu('rfq_create', 69, 'allow');
SELECT lsmb__grant_perms('rfq_create', 'oe_id_seq', 'ALL');
SELECT lsmb__grant_perms('rfq_create', 'orderitems_id_seq', 'ALL');
SELECT lsmb__grant_perms('rfq_create', obj, ptype)
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem']) obj,
       unnest(array['INSERT'::text, 'UPDATE']) ptype;

SELECT lsmb__create_role('purchase_order_list');
SELECT lsmb__grant_role('purchase_order_list', 'contact_read');
SELECT lsmb__grant_menu('purchase_order_list', 55, 'allow');
SELECT lsmb__grant_perms('purchase_order_list', obj, 'SELECT')
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem']) obj;

SELECT lsmb__create_role('rfq_list');
SELECT lsmb__grant_role('rfq_list', 'contact_read');
SELECT lsmb__grant_menu('rfq_list', 72, 'allow');
SELECT lsmb__grant_perms('rfq_list', obj, 'SELECT')
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem']) obj;

SELECT lsmb__create_role('ap_all');
SELECT lsmb__grant_role('ap_all', rname)
  FROM unnest(array['ap_all_vouchers'::text, 'file_attach_tx',
       'ap_all_transactions']) rname;

\echo CASH

SELECT lsmb__create_role('reconciliation_enter');
SELECT lsmb__grant_perms('reconciliation_enter', 'recon_payee', 'SELECT');
SELECT lsmb__grant_perms('reconciliation_enter', 'cr_report', ptype)
  FROM unnest(array['SELECT'::text, 'INSERT', 'UPDATE']) ptype;

SELECT lsmb__grant_perms('reconciliation_enter', obj, 'SELECT')
  FROM unnest(array['cr_coa_to_account'::text, 'acc_trans', 'account_checkpoint'
             ]) obj;

SELECT lsmb__grant_perms('reconciliation_enter', obj, 'ALL')
  FROM unnest(array['cr_report_line'::text, 'cr_report_line_id_seq',
                    'cr_report_id_seq']) obj;

SELECT lsmb__grant_menu('reconciliation_enter', 45, 'allow');

SELECT lsmb__create_role('reconciliation_approve');
SELECT lsmb__grant_perms('reconciliation_approve', 'cr_report_line', 'DELETE');
SELECT lsmb__grant_perms('reconciliation_approve', 'cr_report', 'UPDATE');
SELECT lsmb__grant_perms('reconciliation_approve', obj, 'SELECT')
  FROM unnest(array['recon_payee'::text, 'acc_trans', 'account_checkpoint']) obj;

SELECT lsmb__grant_menu('reconciliation_approve', 44, 'allow');
SELECT lsmb__grant_menu('reconciliation_approve', 211, 'allow');
SELECT lsmb__grant_exec('reconciliation_approve', 'reconciliation__reject_set(in_report_id int)');
SELECT lsmb__grant_exec('reconciliation_approve', 'reconciliation__delete_unapproved(in_report_id int)');

SELECT lsmb__create_role('reconciliation_all');
SELECT lsmb__grant_role('reconciliation_all', 'reconciliation_approve');
SELECT lsmb__grant_role('reconciliation_all', 'reconciliation_enter');

SELECT lsmb__create_role('payment_process');
SELECT lsmb__grant_role('payment_process', 'ap_transaction_list');
SELECT lsmb__grant_role('payment_process', 'exchangerate_edit');
SELECT lsmb__grant_menu('payment_process', node_id, 'allow')
  FROM unnest(array[18, 38, 43, 201, 202, 223]) node_id;

SELECT lsmb__grant_perms('payment_process', 'ap', 'UPDATE');
SELECT lsmb__grant_perms('payment_process', obj, 'ALL')
  FROM unnest(array['payment'::text, 'payment_id_seq', 'acc_trans_entry_id_seq']
       ) obj;

SELECT lsmb__grant_perms('payment_process', obj, ptype)
  FROM unnest(array['payment_links'::text, 'overpayments', 'acc_trans']) obj,
       unnest(array['SELECT'::text, 'INSERT']) ptype;

SELECT lsmb__create_role('receipt_process');
SELECT lsmb__grant_role('receipt_process', 'ap_transaction_list');
SELECT lsmb__grant_role('receipt_process', 'exchangerate_edit');
SELECT lsmb__grant_menu('receipt_process', node_id, 'allow')
  FROM unnest(array[26, 36, 37, 42, 203, 204]) node_id;

SELECT lsmb__grant_perms('receipt_process', 'ar', 'UPDATE');
SELECT lsmb__grant_perms('receipt_process', obj, 'ALL')
  FROM unnest(array['payment'::text, 'payment_id_seq', 'acc_trans_entry_id_seq']
       ) obj;

SELECT lsmb__grant_perms('receipt_process', obj, ptype)
  FROM unnest(array['payment_links'::text, 'overpayments', 'acc_trans']) obj,
       unnest(array['SELECT'::text, 'INSERT']) ptype;

SELECT lsmb__create_role('cash_all');
SELECT lsmb__grant_role('cash_all', rname)
  FROM unnest(array['reconciliation_all'::text, 'payment_process',
              'receipt_process']) rname;

\echo INVENTORY CONTROL

SELECT lsmb__create_role('part_create');
SELECT lsmb__grant_role('part_create', 'contact_read');
SELECT lsmb__grant_menu('part_create', node_id, 'allow')
  FROM unnest(array[78,79,80,81,82]) node_id;

SELECT lsmb__grant_perms('part_create', obj, 'ALL')
  FROM unnest(array['partsvendor'::text, 'partscustomer', 'parts_id_seq',
                    'partsgroup_id_seq', 'partsvendor_entry_id_seq',
                    'partscustomer_entry_id_seq']) obj;

SELECT lsmb__grant_perms('part_create', obj, 'INSERT')
  FROM unnest(array['parts'::text, 'makemodel', 'partsgroup', 'assembly',
                    'partstax']) obj;

SELECT lsmb__create_role('part_edit');
SELECT lsmb__grant_role('part_edit', 'file_read');
SELECT lsmb__grant_menu('part_edit', node_id, 'allow')
  FROM unnest(array[86,91]) node_id;

SELECT lsmb__grant_perms('part_edit', 'assembly', 'DELETE');
SELECT lsmb__grant_perms('part_edit', obj, 'ALL')
  FROM unnest(array['makemodel'::text, 'partstax', 'partscustomer_entry_id_seq',
                   'parts']
       )obj;

SELECT lsmb__grant_perms('part_edit', obj, 'UPDATE')
  FROM unnest(array['parts'::text, 'partsgroup', 'assembly']) obj;

SELECT lsmb__grant_perms('part_edit', obj, 'SELECT')
  FROM unnest(array['assembly'::text, 'orderitems', 'jcitems', 'invoice',
                    'business_unit_oitem']) obj;

SELECT lsmb__create_role('part_delete');
SELECT lsmb__grant_perms('part_delete', obj, 'DELETE')
  FROM unnest(array['parts'::text, 'partsgroup', 'assembly']) obj;

SELECT lsmb__create_role('inventory_reports');
SELECT lsmb__grant_perms('inventory_reports', obj, 'SELECT')
  FROM unnest(array['ar'::text, 'ap', 'warehouse_inventory', 'invoice', 'acc_trans']) obj;

SELECT lsmb__grant_menu('inventory_reports', 114, 'allow');
SELECT lsmb__grant_menu('inventory_reports', 75, 'allow');

SELECT lsmb__create_role('inventory_adjust');
SELECT lsmb__grant_perms('inventory_adjust', obj, 'SELECT')
  FROM unnest(array['parts'::text, 'ar', 'ap', 'invoice']) obj;

SELECT lsmb__grant_perms('inventory_adjust', obj, 'INSERT')
  FROM unnest(array['inventory_report'::text, 'inventory_report_line']) obj;

SELECT lsmb__grant_menu('inventory_adjust', node_id, 'allow')
  FROM unnest(array[6,16]) node_id;

SELECT lsmb__create_role('inventory_approve');
SELECT lsmb__grant_menu('inventory_approve', 59, 'allow');
SELECT lsmb__grant_role('inventory_approve', 'ar_invoice_create');
SELECT lsmb__grant_role('inventory_approve', 'ap_invoice_create');
SELECT lsmb__grant_perms('inventory_adjust', obj, 'SELECT')
  FROM unnest(array['inventory_report'::text, 'inventory_report_line']) obj;
SELECT lsmb__grant_perms('inventory_adjust', 'inventory_report', 'UPDATE');

SELECT lsmb__create_role('pricegroup_create');
SELECT lsmb__grant_role('pricegroup_create', 'contact_read');
SELECT lsmb__grant_menu('pricegroup_create', 83, 'allow');
SELECT lsmb__grant_perms('pricegroup_create', 'pricegroup', 'INSERT');
SELECT lsmb__grant_perms('pricegroup_create', 'pricegroup_id_seq', 'ALL');
SELECT lsmb__grant_perms('pricegroup_create', 'entity_credit_account', 'UPDATE');

SELECT lsmb__create_role('pricegroup_edit');
SELECT lsmb__grant_role('pricegroup_edit', 'contact_read');
SELECT lsmb__grant_menu('pricegroup_edit', 92, 'allow');
SELECT lsmb__grant_perms('pricegroup_edit', 'pricegroup', 'UPDATE');
SELECT lsmb__grant_perms('pricegroup_edit', 'entity_credit_account', 'UPDATE');

SELECT lsmb__create_role('assembly_stock');
SELECT lsmb__grant_perms('assembly_stock', 'parts', 'UPDATE');

SELECT lsmb__grant_perms('assembly_stock', t_name, perm)
  FROM unnest(ARRAY['mfg_lot'::text, 'mfg_lot_item']) t_name
 CROSS JOIN
       unnest(ARRAY['SELECT'::text, 'INSERT', 'UPDATE']) perm;

SELECT lsmb__grant_perms('assembly_stock', t_name, perm)
  FROM unnest(ARRAY['mfg_lot_id_seq'::text, 'mfg_lot_item_id_seq',
                    'lot_tracking_number']) t_name
 CROSS JOIN unnest(ARRAY['SELECT'::text, 'UPDATE']) perm;

SELECT lsmb__grant_menu('assembly_stock', 84, 'allow');

SELECT lsmb__create_role('inventory_ship');
SELECT lsmb__grant_role('inventory_ship', 'sales_order_list');
SELECT lsmb__grant_menu('inventory_ship', 64, 'allow');
SELECT lsmb__grant_perms('inventory_ship', 'warehouse_inventory', 'INSERT');
SELECT lsmb__grant_perms('inventory_ship', 'warehouse_inventory_entry_id_seq', 'ALL');

SELECT lsmb__create_role('inventory_receive');
SELECT lsmb__grant_role('inventory_receive', 'purchase_order_list');
SELECT lsmb__grant_menu('inventory_receive', 65, 'allow');
SELECT lsmb__grant_perms('inventory_receive', 'warehouse_inventory', 'INSERT');
SELECT lsmb__grant_perms('inventory_receive', 'warehouse_inventory_entry_id_seq', 'ALL');

SELECT lsmb__create_role('inventory_transfer');
SELECT lsmb__grant_perms('inventory_transfer', 'warehouse_inventory', 'INSERT');
SELECT lsmb__grant_perms('inventory_transfer', 'warehouse_inventory_entry_id_seq', 'ALL');
SELECT lsmb__grant_menu('inventory_transfer', 66, 'allow');

SELECT lsmb__create_role('warehouse_create');
SELECT lsmb__grant_perms('warehouse_create', 'warehouse', 'INSERT');
SELECT lsmb__grant_perms('warehouse_create', 'warehouse_id_seq', 'ALL');
SELECT lsmb__grant_menu('warehouse_create', 142, 'allow');

SELECT lsmb__create_role('warehouse_edit');
SELECT lsmb__grant_perms('warehouse_edit', 'warehouse', 'UPDATE');
SELECT lsmb__grant_menu('warehouse_edit', 143, 'allow');

SELECT lsmb__create_role('inventory_all');
SELECT lsmb__grant_role('inventory_all', rname)
  FROM unnest(array['warehouse_create'::text, 'warehouse_edit',
              'inventory_transfer', 'inventory_receive', 'inventory_ship',
              'assembly_stock', 'inventory_reports', 'part_create', 'part_edit']
      ) rname;

\echo GL
SELECT lsmb__create_role('gl_transaction_create');
SELECT lsmb__grant_perms('gl_transaction_create', 'gl', ptype)
  FROM unnest(array['SELECT'::text, 'INSERT', 'UPDATE']) ptype;

SELECT lsmb__grant_perms('gl_transaction_create', obj, 'INSERT')
  FROM unnest(array['acc_trans'::text, 'journal_entry', 'journal_line']) obj;

SELECT lsmb__grant_perms('gl_transaction_create', obj, 'ALL')
  FROM unnest(array['id'::text, 'acc_trans_entry_id_seq',
                   'journal_entry_id_seq', 'journal_line_id_seq'])obj;

SELECT lsmb__grant_menu('gl_transaction_create', node_id, 'allow')
  FROM unnest(array[74,40,245]) node_id;

SELECT lsmb__create_role('gl_voucher_create');
SELECT lsmb__grant_perms('gl_voucher_create', obj, 'INSERT')
  FROM unnest(array['gl'::text, 'acc_trans', 'business_unit_ac']) obj;

SELECT lsmb__grant_perms('gl_voucher_create', obj, 'ALL')
  FROM unnest(array['id'::text, 'acc_trans_entry_id_seq']) obj;
-- TODO Add menu permissions

SELECT lsmb__create_role('gl_reports');
SELECT lsmb__grant_role('gl_reports', 'ar_transaction_list');
SELECT lsmb__grant_role('gl_reports', 'ap_transaction_list');
SELECT lsmb__grant_menu('gl_reports', node_id, 'allow')
  FROM unnest(array[76,114]) node_id;

SELECT lsmb__grant_perms('gl_reports', obj, 'SELECT')
  FROM unnest(array['gl'::text, 'acc_trans', 'account_checkpoint']) obj;

SELECT lsmb__create_role('yearend_run');
SELECT lsmb__grant_perms('yearend_run', obj, ptype)
  FROM unnest(array['acc_trans'::text, 'account_checkpoint', 'yearend']) obj,
       unnest(array['SELECT'::text, 'INSERT']) ptype;
SELECT lsmb__grant_perms('yearend_run', 'account_checkpoint_id_seq','ALL');
SELECT lsmb__grant_menu('yearend_run', 132, 'allow');

SELECT lsmb__create_role('batch_list');
SELECT lsmb__grant_role('batch_list', 'gl_reports');
SELECT lsmb__grant_perms('batch_list', obj, 'SELECT')
  FROM unnest(array['batch'::text, 'batch_class', 'voucher']) obj;

SELECT lsmb__create_role('gl_all');
SELECT lsmb__grant_role('gl_all', rname)
  FROM unnest(array['gl_transaction_create'::text, 'gl_voucher_create',
                    'yearend_run', 'gl_reports']) rname;

SELECT lsmb__create_role('timecard_add');
SELECT lsmb__grant_role('timecard_add', 'contact_read');
SELECT lsmb__grant_menu('timecard_add', node_id, 'allow')
  FROM unnest(array[100, 106, 8]) node_id;

SELECT lsmb__grant_perms('timecard_add', 'jcitems_id_seq', 'ALL');
SELECT lsmb__grant_perms('timecard_add', 'jcitems', 'INSERT');
SELECT lsmb__grant_perms('timecard_add', 'jcitems', 'UPDATE');

SELECT lsmb__create_role('timecard_list');
SELECT lsmb__grant_role('timecard_list', 'contact_read');
SELECT lsmb__grant_menu('timecard_list', 106, 'allow');
SELECT lsmb__grant_perms('timecard_list', 'jcitems', 'SELECT');

\echo ORDER GENERATION
SELECT lsmb__create_role('orders_generate');
SELECT lsmb__grant_role('orders_generate', 'contact_read');
SELECT lsmb__grant_perms('orders_generate', obj, ptype)
  FROM unnest(array['oe'::text, 'orderitems', 'business_unit_oitem']) obj,
       unnest(array['SELECT'::text, 'INSERT', 'UPDATE']) ptype;

SELECT lsmb__grant_perms('orders_generate', obj, 'ALL')
  FROM unnest(array['oe_id_seq'::text, 'orderitems_id_seq']) obj;

SELECT lsmb__create_role('timecard_order_generate');
SELECT lsmb__grant_role('timecard_order_generate', 'orders_generate');
SELECT lsmb__grant_role('timecard_order_generate', 'timecard_list');
SELECT lsmb__grant_menu('timecard_order_generate', 102, 'allow');

SELECT lsmb__create_role('orders_sales_to_purchase');
SELECT lsmb__grant_role('orders_sales_to_purchase', 'orders_generate');
SELECT lsmb__grant_menu('orders_sales_to_purchase', node_id, 'allow')
  FROM unnest(array[57,58]) node_id;

SELECT lsmb__create_role('orders_purchase_consolidate');
SELECT lsmb__grant_role('orders_purchase_consolidate', 'orders_generate');
SELECT lsmb__grant_menu('orders_purchase_consolidate', 62, 'allow');

SELECT lsmb__create_role('orders_sales_consolidate');
SELECT lsmb__grant_role('orders_sales_consolidate', 'orders_generate');
SELECT lsmb__grant_menu('orders_sales_consolidate', 61, 'allow');

SELECT lsmb__create_role('orders_manage');
SELECT lsmb__grant_role('orders_manage', rname)
  FROM unnest(array['timecard_order_generate'::text, 'orders_sales_to_purchase',
                    'orders_purchase_consolidate', 'orders_sales_consolidate']
       ) rname;

\echo FINANCIAL REPORTS
SELECT lsmb__create_role('financial_reports');
SELECT lsmb__grant_role('financial_reports', 'gl_reports');
SELECT lsmb__grant_menu('financial_reports', node_id, 'allow')
  FROM unnest(array[75,110,111,112,113,114]) node_id;

SELECT lsmb__grant_perms('financial_reports', obj, 'SELECT')
  FROM unnest(array['yearend'::text, 'cash_impact', 'tx_report']) obj;

\echo RECURRING TRANSACTIONS
SELECT lsmb__create_role('recurring');
SELECT lsmb__grant_menu('recurring', 115, 'allow');

\echo TAX FORMS
SELECT lsmb__create_role('tax_form_save');
SELECT lsmb__grant_perms('tax_form_save', 'country_tax_form', 'ALL');
SELECT lsmb__grant_perms('tax_form_save', 'country_tax_form_id_seq', 'ALL');
SELECT lsmb__grant_menu('tax_form_save', id, 'allow')
  FROM unnest(array[218, 225, 226]) id;

\echo SYSTEM SETTINGS
SELECT lsmb__create_role('system_settings_list');
SELECT lsmb__grant_menu('system_settings_list', 131, 'allow');

SELECT lsmb__create_role('system_settings_change');
SELECT lsmb__grant_role('system_settings_change', 'system_settings_list');
SELECT lsmb__grant_menu('system_settings_change', 17, 'allow');

SELECT lsmb__create_role('taxes_set');
SELECT lsmb__grant_perms('taxes_set', 'tax', 'INSERT');
SELECT lsmb__grant_perms('taxes_set', 'tax', 'UPDATE');
SELECT lsmb__grant_menu('taxes_set', 130, 'allow');

SELECT lsmb__create_role('account_create');
SELECT lsmb__grant_perms('account_create', obj, 'INSERT')
  FROM unnest(array['chart'::text, 'account', 'cr_coa_to_account',
                    'account_heading', 'account_link',
                    'account_translation', 'account_heading_translation']) obj;

SELECT lsmb__grant_perms('account_create', obj, 'ALL')
  FROM unnest(array['account_id_seq'::text, 'account_heading_id_seq']) obj;
SELECT lsmb__grant_menu('account_create', id, 'allow')
  FROM unnest(array[137,246]) id;

SELECT lsmb__create_role('account_edit');
SELECT lsmb__grant_perms('account_edit', obj, perm)
  FROM unnest(array['account'::text, 'account_heading', 'account_link',
                    'account_translation', 'account_heading_translation',
                    'cr_coa_to_account', 'tax']) obj
 CROSS JOIN unnest(array['SELECT'::text, 'INSERT', 'UPDATE']) perm;
SELECT lsmb__grant_perms('account_edit', 'account_link', 'DELETE');
SELECT lsmb__grant_perms('account_edit', 'account_translation', 'DELETE');
SELECT lsmb__grant_perms('account_edit', 'account_heading_translation', 'DELETE');

SELECT lsmb__create_role('account_delete');
SELECT lsmb__grant_perms('account_delete', obj, 'DELETE')
  FROM unnest(array['account'::text, 'account_heading', 'account_link',
                    'account_translation', 'account_heading_translation',
                    'cr_coa_to_account', 'tax']) obj;

SELECT lsmb__create_role('auditor');
SELECT lsmb__grant_perms('auditor', 'audittrail', 'SELECT');

SELECT lsmb__create_role('audit_trail_maintenance');
SELECT lsmb__grant_perms('audit_trail_maintenance', 'audittrail', 'DELETE');

SELECT lsmb__create_role('gifi_create');
SELECT lsmb__grant_perms('gifi_create', 'gifi', 'INSERT');
SELECT lsmb__grant_menu('gifi_create', id, 'allow')
  FROM unnest(array[139,247]) id;

SELECT lsmb__create_role('gifi_edit');
SELECT lsmb__grant_perms('gifi_edit', 'gifi', 'UPDATE');
SELECT lsmb__grant_menu('gifi_edit', 140, 'allow');

SELECT lsmb__create_role('account_all');
SELECT lsmb__grant_role('account_all', rname)
  FROM unnest(array['account_create'::text, 'taxes_set', 'account_edit',
                    'gifi_create', 'gifi_edit', 'account_delete']) rname;

SELECT lsmb__create_role('business_type_create');
SELECT lsmb__grant_perms('business_type_create', 'business', 'INSERT');
SELECT lsmb__grant_perms('business_type_create', 'business_id_seq', 'ALL');
SELECT lsmb__grant_menu('business_type_create', 148, 'allow');

SELECT lsmb__create_role('business_type_edit');
SELECT lsmb__grant_perms('business_type_edit', 'business', ptype)
  FROM unnest(array['UPDATE'::text, 'DELETE'::text]) ptype;

SELECT lsmb__grant_menu('business_type_edit', 149, 'allow');

SELECT lsmb__create_role('business_type_all');
SELECT lsmb__grant_role('business_type_all', 'business_type_create');
SELECT lsmb__grant_role('business_type_all', 'business_type_edit');

SELECT lsmb__create_role('sic_create');
SELECT lsmb__grant_perms('sic_create', 'sic', 'INSERT');
SELECT lsmb__grant_menu('sic_create', id, 'allow')
  FROM unnest(array[154,248]) id;

SELECT lsmb__create_role('sic_edit');
SELECT lsmb__grant_perms('sic_edit', 'sic', 'UPDATE');
SELECT lsmb__grant_menu('sic_edit', 155, 'allow');

SELECT lsmb__create_role('sic_all');
SELECT lsmb__grant_role('sic_all', 'sic_create');
SELECT lsmb__grant_role('sic_all', 'sic_edit');

SELECT lsmb__create_role('template_edit');
SELECT lsmb__grant_perms('template_edit', 'template', 'ALL');
SELECT lsmb__grant_perms('template_edit', 'template_id_seq', 'ALL');
SELECT lsmb__grant_menu('template_edit', id, 'allow')
  FROM unnest(array[90, 99, 159,160,161,162,163,164,165,166,167,168,169,170,
                    171,173,174,175,176,177,178,179,180,181,182,183,184,
                    185,186,187,241,242]) id;

SELECT lsmb__create_role('users_manage');
SELECT lsmb__grant_role('users_manage', 'contact_read');
SELECT lsmb__grant_role('users_manage', 'contact_create');
SELECT lsmb__grant_role('users_manage', 'contact_class_employee');
SELECT lsmb__grant_exec('users_manage', 'admin__add_user_to_role(TEXT, TEXT)');
SELECT lsmb__grant_exec('users_manage', 'admin__remove_user_from_role(TEXT, TEXT)');
SELECT lsmb__grant_exec('users_manage', 'admin__get_roles_for_user(int)');
SELECT lsmb__grant_exec('users_manage', 'admin__get_roles_for_user_by_entity(int)');
SELECT lsmb__grant_exec('users_manage', 'admin__save_user(int,int,text,text,bool)');
SELECT lsmb__grant_exec('users_manage', 'admin__delete_user(TEXT, bool)');
SELECT lsmb__grant_perms('users_manage', 'role_view', 'SELECT');
SELECT lsmb__grant_menu('users_manage', 222, 'allow');SELECT lsmb__grant_menu('users_manage', 48, 'allow');
SELECT lsmb__grant_menu('users_manage', 48, 'allow');
SELECT lsmb__grant_menu('users_manage', 49, 'allow');

SELECT lsmb__create_role('system_admin');
SELECT lsmb__grant_role('system_admin', rname)
  FROM unnest(array['system_settings_change'::text, 'account_all',
                    'business_type_all', 'sic_all', 'users_manage',
                    'tax_form_save']) rname;

\echo MANUAL TRANSLATION
SELECT lsmb__create_role('language_create');
SELECT lsmb__grant_perms('language_create', 'language', 'INSERT');
SELECT lsmb__grant_menu('language_create', 151, 'allow');

SELECT lsmb__create_role('language_edit');
SELECT lsmb__grant_perms('language_edit', 'language', 'UPDATE');
SELECT lsmb__grant_menu('language_edit', 152, 'allow');

SELECT lsmb__create_role('translation_create');
SELECT lsmb__grant_perms('translation_create', obj, 'ALL')
  FROM unnest(array['parts_translation'::text, 'partsgroup_translation',
                    'business_unit_translation']) obj;

SELECT lsmb__grant_menu('translation_create', id, 'allow')
  FROM unnest(array[96,97,108]) id;

\echo FIXED ASSETS
SELECT lsmb__create_role('assets_administer');
SELECT lsmb__grant_perms('assets_administer', 'asset_class', 'ALL');
SELECT lsmb__grant_perms('assets_administer', 'asset_class_id_seq', 'ALL');
SELECT lsmb__grant_menu('assets_administer', 237, 'allow');

SELECT lsmb__create_role('assets_enter');
SELECT lsmb__grant_perms('assets_enter', 'asset_item_id_seq', 'ALL');
SELECT lsmb__grant_perms('assets_enter', 'asset_class', 'SELECT');
SELECT lsmb__grant_perms('assets_enter', 'asset_item', ptype)
  FROM unnest(array['SELECT'::text, 'INSERT', 'UPDATE']) ptype;
SELECT lsmb__grant_perms('assets_enter', 'asset_note', ptype)
  FROM unnest(array['SELECT'::text, 'INSERT', 'UPDATE']) ptype;

SELECT lsmb__grant_menu('assets_enter', id, 'allow')
  FROM unnest(array[230, 231, 232, 233, 235]) id;

SELECT lsmb__create_role('assets_depreciate');
SELECT lsmb__grant_perms('assets_depreciate', 'asset_report_id_seq', 'ALL');
SELECT lsmb__grant_perms('assets_depreciate', 'asset_report', 'UPDATE');
SELECT lsmb__grant_perms('assets_depreciate', obj, ptype)
  FROM unnest(array['SELECT'::text, 'INSERT']) ptype,
       unnest(array['asset_report'::text, 'asset_report_line', 'asset_item',
                    'asset_class']) obj;

SELECT lsmb__grant_menu('assets_depreciate', 238, 'allow');
SELECT lsmb__grant_menu('assets_depreciate', 234, 'allow');

SELECT lsmb__create_role('assets_approve');
SELECT lsmb__grant_perms('assets_approve', obj, 'SELECT')
  FROM unnest(array['asset_report'::text, 'asset_report_line', 'asset_item',
                    'asset_class']) obj;

SELECT lsmb__grant_exec('assets_approve', 'asset_report__approve(int, int, int, int)');
SELECT lsmb__grant_menu('assets_approve', id, 'allow')
  FROM unnest(array[239,240]) id;

-- Grants to all users;
SELECT lsmb__grant_perms('base_user', obj, 'SELECT')
  FROM unnest(array['asset_unit_class'::text, 'asset_dep_method',
                    'lsmb_module', 'business_unit', 'business_unit_class']) obj;
SELECT lsmb__grant_perms('base_user', obj, 'SELECT')
  FROM unnest(array['makemodel'::text, 'custom_field_catalog',
                    'custom_table_catalog', 'oe_class', 'note_class']) obj;
SELECT lsmb__grant_perms('base_user', obj, 'SELECT')
  FROM unnest(array['account_heading'::text, 'account',
                    'acc_trans', 'account_link',
                    'account_translation', 'account_heading_translation',
                    'account_link_description']) obj;
                                     -- I don't like loose grants on acc_trans
                                     -- but we need to
                                     -- change the all years function to be
                                     -- security definer first. -- CT
SELECT lsmb__grant_perms('base_user', 'defaults', 'ALL');
SELECT lsmb__grant_perms('base_user', obj, 'SELECT')
  FROM unnest(array['contact_class'::text, 'batch_class',
                    'entity_class', 'users']) obj;

SELECT lsmb__grant_perms('base_user', obj, 'ALL')
  FROM unnest(array['session'::text, 'session_session_id_seq',
                    'user_preference', 'status', 'recurring',
                    'recurringemail', 'recurringprint', 'transactions',
                    'ac_tax_form', 'invoice_tax_form', 'lsmb_sequence']) obj;
-- transactions table needs to be better locked down in 1.5

SELECT lsmb__grant_perms('base_user', obj, 'SELECT')
  FROM unnest(array['user_listable'::text, 'language',
                    'menu_node', 'menu_attribute', 'menu_acl',
                    'chart', 'gifi', 'country', 'taxmodule',
                    'parts', 'partsgroup', 'country_tax_form', 'translation',
                    'business', 'exchangerate', 'new_shipto', 'tax',
                    'entity_employee', 'jcitems', 'salutation', 'assembly']) obj;

SELECT lsmb__grant_perms('base_user', 'new_shipto', 'UPDATE');

SELECT lsmb__grant_perms('base_user', obj, 'SELECT')
  FROM unnest(array['partstax'::text, 'partscustomer',
                    'account_heading_descendant',
                    'account_heading_derived_category',
                    'account_heading_tree', 'payment_type', 'warehouse',
                    'sic', 'voucher', 'mime_type',
                    'parts_translation', 'partsgroup_translation',
                    'asset_report_class', 'asset_rl_to_disposal_method',
                    'asset_disposal_method', 'file_class', 'jctype']) obj;

REVOKE INSERT, UPDATE, DELETE ON entity_employee FROM public; --fixing old perms
SELECT lsmb__grant_exec('base_user', 'user__get_all_users()');

INSERT INTO menu_acl (node_id, acl_type, role_name)
SELECT i_id, 'allow', 'public'
  FROM unnest(array[191,192,193]) i_id
 WHERE NOT EXISTS (select * from menu_acl
                    WHERE node_id = i_id AND role_name = 'public');

\echo PERMISSIONS ENFORCEMENT PER ENTITY CLASS
CREATE OR REPLACE FUNCTION tg_enforce_perms_eclass () RETURNS TRIGGER AS
$$
DECLARE
   r_eclass entity_class;
BEGIN
IF TG_OP = 'DELETE' THEN
   RETURN OLD;
ELSE
   PERFORM 1 FROM pg_catalog.pg_roles rol
            WHERE rolname = CURRENT_USER
              AND rolsuper;
   IF FOUND THEN RETURN NEW; -- is superuser
   END IF;
   PERFORM 1 FROM pg_catalog.pg_database db
             INNER JOIN pg_catalog.pg_roles rol
             ON db.datdba = rol.oid
          WHERE db.datname = current_database()
            AND rol.rolname = CURRENT_USER;
   IF FOUND THEN RETURN NEW; -- is database owner
   END IF;                   -- without this permission, non-superusers,
                             -- with create-role *and* create-db perms
                             -- can't create new companies
   SELECT * INTO r_eclass from entity_class WHERE id = NEW.entity_class;
   IF pg_has_role(SESSION_USER,
                  lsmb__role('contact_class_'
                             || lower(regexp_replace(r_eclass.class,
                                                     ' ', '_'))),
                  'USAGE')
   THEN
      RETURN NEW;
   ELSE
      RAISE EXCEPTION 'Access Denied for class';
   END IF;
END IF;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS eclass_perms_check ON entity;
CREATE TRIGGER eclass_perms_check
BEFORE INSERT OR UPDATE OR DELETE ON entity
FOR EACH ROW EXECUTE PROCEDURE tg_enforce_perms_eclass();

DROP TRIGGER IF EXISTS eclass_perms_check ON entity_credit_account;
CREATE TRIGGER eclass_perms_check
BEFORE INSERT OR UPDATE OR DELETE ON entity_credit_account
FOR EACH ROW EXECUTE PROCEDURE tg_enforce_perms_eclass();

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
