BEGIN;
\i Base.sql

INSERT INTO test_result (test_name, success)
SELECT 'Batch Created', 
	batch_create('_TEST', '_TEST', 'payment', '2008-01-01') IS NOT NULL;

INSERT INTO entity (id, name, entity_class, control_code) 
values (-3, 'Test', 1, 'test');
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class) 
values (-3, -1, 'Test', 1);

INSERT INTO entity_employee(entity_id) values (-3);

INSERT INTO chart (id, accno, description, link, charttype, category)
VALUES ('-5', '-21111', 'Testing AP', 'AP', 'A', 'A');

INSERT INTO ap (id, invnumber, amount, curr, approved, entity_credit_account)
VALUES (-5, 'test1', '1000', 'USD', false, -1);

INSERT INTO acc_trans(trans_id, chart_id, amount, approved)
values (-5, test_get_account_id('-21111'), 1000, true);

INSERT INTO ap (id, invnumber, amount, curr, approved, entity_credit_account)
VALUES (-6, 'test1', '1000', 'USD', false, -1);

INSERT INTO acc_trans(trans_id, chart_id, amount, approved)
values (-6, test_get_account_id('-21111'), 1000, true);
INSERT INTO voucher (trans_id, batch_id, batch_class)
values (-5, currval('batch_id_seq'), 1);
INSERT INTO voucher (trans_id, batch_id, batch_class)
values (-5, currval('batch_id_seq'), 3);
INSERT INTO voucher (trans_id, batch_id, batch_class)
values (-5, currval('batch_id_seq'), 3);

INSERT INTO test_result(test_name, success)
select 'Voucher Seach finds Payable Vouchers',  count(*)=1 
from voucher_list( currval('batch_id_seq')::int);

INSERT INTO test_result (test_name, success)
SELECT 'partial payment support', count(*) > 1 
FROM voucher where trans_id = -5 and batch_class = 3;

-- Adding the test for empty batch sproc

insert into batch (batch_class_id, control_code, description, default_date, created_by) values (1, 'EMPTYBATCHTEST1', 'EMPTY BATCH TEST', '2009-01-01', -3);

INSERT INTO test_result (test_name, success)
SELECT 'Empty Batch Detected', count(*) = 1
  FROM batch_search_empty(1,                        -- Batch class ID
                          'EMPTY BATCH TEST',       -- Batch description
                          -3,                       -- Entity ID
       	                  NULL::numeric,            -- Amount greater than
       	                  NULL::numeric,            -- Amount less than
       	                  'f'::bool                 -- Approved
);

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

ROLLBACK;
