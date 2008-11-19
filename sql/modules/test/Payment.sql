BEGIN;
\i Base.sql

INSERT INTO entity (id, name, entity_class, control_code)
VALUES (-100, 'Testing.....', 3, '_TESTING.....');

DELETE FROM users WHERE username = CURRENT_USER;

INSERT INTO users (entity_id, username)
SELECT -100, CURRENT_USER;

INSERT INTO person(first_name, last_name, entity_id, id)
VALUES ('test', 'test', -100, -100);

INSERT INTO entity_employee(entity_id, person_id)
VALUES (-100, -100);

INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00001', 'testing', 'A', 'L', 'AP');
INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00002', 'testing2', 'A', 'E', 'AP_expense');

INSERT INTO session (users_id, last_used, token, transaction_id)
values (currval('users_id_seq'),  now(), md5('test2'), 2);

INSERT INTO test_result(test_name, success)
SELECT 'AP Batch created', (SELECT batch_create('test', 'test', 'ap', now()::date)) IS NOT NULL;

INSERT INTO entity (id, entity_class, name, control_code)
VALUES (-101, 1, 'TEST VENDOR', 'TEST 2');

INSERT INTO company (id, legal_name, entity_id)
VALUES (-101, 'TEST', -101);

INSERT INTO business (id, description)
values (-101, 'test');

INSERT INTO entity_credit_account (id, meta_number, threshold, entity_id, entity_class, business_id)
values (-101, 'TEST1', 100000, -101, 1, -101); 

INSERT INTO ap (invnumber, entity_credit_account, approved, amount, netamount, curr)
values ('test_hide', -101, false, '1', '1', 'USD');

INSERT INTO voucher (trans_id, batch_class, batch_id) 
VALUES (currval('id'), 1, currval('batch_id_seq'));

INSERT INTO test_result(test_name, success)
SELECT 'Payment Batch created', (SELECT batch_create('test', 'test', 'ap', now()::date)) IS NOT NULL;
INSERT INTO ap (invnumber, entity_credit_account, approved, amount, netamount, curr, transdate, paid)
VALUES ('test_show2', -101, true, 100000, 100000, 'USD', now()::date, 0);

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '100000', currval('id'), (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '-100000', currval('id'), (select id from chart where accno = '00002'));

INSERT INTO ap (invnumber, entity_credit_account, approved, amount, netamount, curr, transdate, paid)
values ('test_show', -101, false, '1', '1', 'USD', now()::date, 0);

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '1', currval('id'), (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '-1', currval('id'), (select id from chart where accno = '00002'));

INSERT INTO voucher (trans_id, batch_class, batch_id) 
VALUES (currval('id'), 1, currval('batch_id_seq'));

CREATE FUNCTION test_convert_array(anyarray) RETURNS text AS
'
	SELECT array_to_string($1, ''::'');
' LANGUAGE SQL;

INSERT INTO test_result(test_name, success)
VALUES ('Batch Voucher In Payment Selection', 
	(SELECT test_convert_array(invoices) LIKE '%::test_show::%'
			FROM 
				(
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1')
)p));

INSERT INTO test_result(test_name, success)
VALUES ('Threshold met', 
	(SELECT test_convert_array(invoices) LIKE '%::test_show2::%'
			FROM 
				(
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1')
)p));
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL,  currval('batch_id_seq')::int, '00001', 'TEST1');

INSERT INTO test_result(test_name, success)
VALUES ('Non-Batch Voucher Not In Payment Selection', 
		(SELECT test_convert_array(invoices) NOT LIKE '%::test_hide::%'
			FROM 
				(SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1'))p ));

SELECT * FROM TEST_RESULT;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

-- ROLLBACK;
