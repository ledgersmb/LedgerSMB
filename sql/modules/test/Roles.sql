BEGIN;
\i Base.sql

-- This function is vulnerable to SQL injection but it is transient for the
-- purposes of these test cases. In particular it is intended only to ensure
-- that basic permissions are tested.
--
-- IT IS THE RESPONSIBILITY OF TEST CASE AUTHORS TO ENSURE THAT THE USAGE OF
-- THIS FUNCTION IS SAFE.
CREATE OR REPLACE FUNCTION test__has_select_permission
(rolname name, relspec text)
returns bool language plpgsql as
$$
BEGIN
   EXECUTE 'SET SESSION AUTHORIZATION ' || lsmb__role(rolname);
   EXECUTE 'SELECT * FROM '  || relspec || ' LIMIT 1';
   RESET SESSION AUTHORIZATION;
   RETURN TRUE;
EXCEPTION
   WHEN insufficient_privilege THEN
       RESET SESSION AUTHORIZATION;
       RETURN FALSE;
END;
$$;

-- READ PERMISSIONS
INSERT INTO test_result (test_name, success)
SELECT 'budget_view can read budget_info',
             test__has_select_permission('budget_view', 'budget_info');

INSERT INTO test_result (test_name, success)
SELECT 'budget_view can read budget_info',
             test__has_select_permission('budget_view', 'budget_line');

INSERT INTO test_result (test_name, success)
SELECT 'file_read can read file_base',
        test__has_select_permission('file_read', 'file_base');

INSERT INTO test_result (test_name, success)
SELECT 'file_read can read file_links',
        test__has_select_permission('file_read', 'file_links');

INSERT INTO test_result (test_name, success)
SELECT 'file_read can read file_secondary_transaction',
        test__has_select_permission('file_read', 'file_secondary_attachment');

INSERT INTO test_result (test_name, success)
SELECT 'file_read can read file_order',
        test__has_select_permission('file_read', 'file_order');

INSERT INTO test_result (test_name, success)
SELECT 'file_read can read file_part',
        test__has_select_permission('file_read', 'file_part');

INSERT INTO test_result(test_name, success)
SELECT 'contact_read can read ' || t,
       test__has_select_permission('contact_read', t)
  FROM unnest(ARRAY['partsvendor'::text, 'partscustomer', 'taxcategory',
          'entity', 'company', 'location', 'entity_to_location',
          'entity_to_contact', 'person', 'entity_credit_account',
          'contact_class', 'eca_tax', 'entity_class', 'entity_note',
          'entity_bank_account', 'entity_other_name', 'location_class',
          'person_to_company', 'eca_to_contact', 'eca_to_location', 'eca_note',
          'pricegroup'
       ]) t;

INSERT INTO test_result(test_name, success)
SELECT 'ar_transaction_list can read ' || t,
       test__has_select_permission('ar_transaction_list', t)
  FROM unnest(ARRAY['partsvendor'::text, 'partscustomer', 'taxcategory',
          'entity', 'company', 'location', 'entity_to_location',
          'entity_to_contact', 'person', 'entity_credit_account',
          'contact_class', 'eca_tax', 'entity_class', 'entity_note',
          'entity_bank_account', 'entity_other_name', 'location_class',
          'person_to_company', 'eca_to_contact', 'eca_to_location', 'eca_note',
          'ar', 'acc_trans', 'invoice', 'ac_tax_form', 'invoice_tax_form'
       ]) t;

INSERT INTO test_result(test_name, success)
SELECT 'ap_transaction_list can read ' || t,
       test__has_select_permission('ap_transaction_list', t)
  FROM unnest(ARRAY['partsvendor'::text, 'partscustomer', 'taxcategory',
          'entity', 'company', 'location', 'entity_to_location',
          'entity_to_contact', 'person', 'entity_credit_account',
          'contact_class', 'eca_tax', 'entity_class', 'entity_note',
          'entity_bank_account', 'entity_other_name', 'location_class',
          'person_to_company', 'eca_to_contact', 'eca_to_location', 'eca_note',
          'ap', 'acc_trans', 'invoice', 'ac_tax_form', 'invoice_tax_form'
       ]) t;

INSERT INTO test_result(test_name, success)
SELECT 'sales_order_list can read ' || t,
       test__has_select_permission('sales_order_list', t)
  FROM unnest(ARRAY['partsvendor'::text, 'partscustomer', 'taxcategory',
          'entity', 'company', 'location', 'entity_to_location',
          'entity_to_contact', 'person', 'entity_credit_account',
          'contact_class', 'eca_tax', 'entity_class', 'entity_note',
          'entity_bank_account', 'entity_other_name', 'location_class',
          'person_to_company', 'eca_to_contact', 'eca_to_location', 'eca_note',
          'oe', 'orderitems'
       ]) t;

INSERT INTO test_result(test_name, success)
SELECT 'purchase_order_list can read ' || t,
       test__has_select_permission('purchase_order_list', t)
  FROM unnest(ARRAY['partsvendor'::text, 'partscustomer', 'taxcategory',
          'entity', 'company', 'location', 'entity_to_location',
          'entity_to_contact', 'person', 'entity_credit_account',
          'contact_class', 'eca_tax', 'entity_class', 'entity_note',
          'entity_bank_account', 'entity_other_name', 'location_class',
          'person_to_company', 'eca_to_contact', 'eca_to_location', 'eca_note',
          'oe', 'orderitems'
       ]) t;

INSERT INTO test_result(test_name, success)
SELECT 'inventory_reports can read ' || t,
       test__has_select_permission('inventory_reports', t)
FROM unnest(array['ar'::text, 'ap', 'warehouse_inventory', 'invoice', 'acc_trans']) t;

INSERT INTO test_result(test_name, success)
SELECT 'gl_reports can read ' || t,
       test__has_select_permission('gl_reports', t)
FROM unnest(array['gl'::text, 'acc_trans', 'account_checkpoint', 'ar', 'ap',
                  'entity', 'entity_credit_account'])t;

INSERT INTO test_result(test_name, success)
SELECT 'financial_reports can read ' || t,
       test__has_select_permission('financial_reports', t)
FROM unnest(array['gl'::text, 'acc_trans', 'account_checkpoint', 'ar', 'ap',
                  'entity', 'entity_credit_account', 'cash_impact'])t;

-- TEST RESULTS
SELECT test_name, success FROM test_result;


SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;

