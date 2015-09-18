BEGIN;
\i Base.sql

INSERT INTO test_result (test_name, success)
SELECT 'Batch Created',
	batch_create('_TEST', '_TEST', 'payment', '2008-01-01') IS NOT NULL;

INSERT INTO entity (id, name, entity_class, control_code, country_id)
values (-3, 'Test', 1, 'test', 242);
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class, ar_ap_account_id)
values (-3, -1, 'Test', 1, -1000);

INSERT INTO entity_employee(entity_id) values (-3);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-5, '-21111', 'Testing AP', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO country_tax_form(country_id, form_name, id) values (232, 'TEST', '-101');

INSERT INTO account_link(account_id, description) values (-5, 'AP');

INSERT INTO ap (id, invnumber, amount, curr, approved, entity_credit_account)
VALUES (-5, 'test1', '1000', 'USD', false, -1);

INSERT INTO acc_trans(trans_id, chart_id, amount, approved)
values (-5, test_get_account_id('-21111'), 1000, true);

INSERT INTO ap (id, invnumber, amount, curr, approved, entity_credit_account)
VALUES (-6, 'test1', '1000', 'USD', false, -1);

INSERT INTO acc_trans(trans_id, chart_id, amount, approved, entry_id)
values (-6, test_get_account_id('-21111'), 1000, true, -1);

INSERT INTO voucher(id, trans_id, batch_id, batch_class)
values (-6, -6, currval('batch_id_seq'), 1);

INSERT INTO ac_tax_form (entry_id, reportable)
values (-1, false);

INSERT INTO ap (id, invnumber, amount, curr, approved, entity_credit_account)
VALUES (-7, 'test1', '1000', 'USD', false, -1);

INSERT INTO acc_trans(trans_id, chart_id, amount, approved, entry_id)
values (-7, test_get_account_id('-21111'), 1000, true, -2);

INSERT INTO ac_tax_form (entry_id, reportable)
values (-2, false);

INSERT INTO voucher (id, trans_id, batch_id, batch_class)
values (-1, -5, currval('batch_id_seq'), 1);
INSERT INTO voucher (id, trans_id, batch_id, batch_class)
values (-2, -5, currval('batch_id_seq'), 3);
INSERT INTO voucher (id, trans_id, batch_id, batch_class)
values (-3, -5, currval('batch_id_seq'), 3);

INSERT INTO test_result(test_name, success)
select 'Voucher Seach finds Payable Vouchers',  count(*)=2
from voucher__list( currval('batch_id_seq')::int);

INSERT INTO test_result (test_name, success)
SELECT 'partial payment support', count(*) > 1
FROM voucher where trans_id = -5 and batch_class = 3;

-- Adding the test for empty batch sproc

INSERT INTO test_result(test_name, success)
SELECT 'creating batch 2',
batch_create('EMPTYBATCHTEST1', 'EMPTY BATCH TEST', 'ap', '2008-01-01')
IS NOT NULL;

INSERT INTO test_result (test_name, success)
SELECT 'Empty Batch Detected', count(*) = 1
  FROM batch_search_empty(1,                        -- Batch class ID
                          'EMPTY BATCH TEST',       -- Batch description
                          -100,                       -- Entity ID
       	                  NULL::numeric,            -- Amount greater than
       	                  NULL::numeric,            -- Amount less than
       	                  'f'::bool                 -- Approved
);

INSERT INTO test_result(test_name, success)
SELECT 'Delete voucher with tax_form', voucher__delete(-6) = 1;

INSERT INTO test_result(test_name, success)
SELECT 'not all tax form lines deleted', count(*) > 0
FROM ac_tax_form;

INSERT INTO test_result(test_name, success)
select 'DELETED voucher does not exist', count(*) = 0
FROM ap WHERE id = -6;

INSERT INTO test_result(test_name, success)
SELECT 'Delete batch', batch_delete(currval('batch_id_seq')::int) = 1;

INSERT INTO test_result(test_name, success)
SELECT 'Batch is deleted', count(*) = 0
FROM batch where id = currval('batch_id_seq');

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
