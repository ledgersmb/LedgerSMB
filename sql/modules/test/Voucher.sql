BEGIN;
\i Base.sql

INSERT INTO test_result (test_name, success)
SELECT 'Batch Created', 
	batch_create('_TEST', '_TEST', 'payment', '2008-01-01') IS NOT NULL;

INSERT INTO entity (id, name, entity_class, control_code) 
values (-3, 'Test', 1, 'test');
INSERT INTO entity_credit_account (entity_id, id, meta_number, entity_class) 
values (-3, -1, 'Test', 1);

INSERT INTO chart (id, accno, description, link)
VALUES ('-5', '-21111', 'Testing AP', 'AP');

INSERT INTO ap (id, invnumber, amount, curr, approved, entity_credit_account)
VALUES (-5, 'test1', '1000', 'USD', false, -1);

INSERT INTO acc_trans(trans_id, chart_id, amount, approved)
values (-5, -5, 1000, true);

INSERT INTO ap (id, invnumber, amount, curr, approved, entity_credit_account)
VALUES (-6, 'test1', '1000', 'USD', false, -1);

INSERT INTO acc_trans(trans_id, chart_id, amount, approved)
values (-6, -5, 1000, true);
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

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

ROLLBACK;
