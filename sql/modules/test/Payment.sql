BEGIN;
\i Base.sql

INSERT INTO entity (name, entity_class, control_code)
VALUES ('Testing.....', 3, '_TESTING.....');

DELETE FROM users WHERE username = CURRENT_USER;

INSERT INTO users (entity_id, username)
SELECT currval('entity_id_seq'), CURRENT_USER;

INSERT INTO person(first_name, last_name, entity_id)
VALUES ('test', 'test', currval('entity_id_seq'));

INSERT INTO entity_employee(entity_id, person_id)
VALUES (currval('entity_id_seq'), currval('person_id_seq'));

INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00001', 'testing', 'A', 'L', 'AP');
INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00002', 'testing2', 'A', 'E', 'AP');

INSERT INTO session (users_id, last_used, token, transaction_id)
values (currval('users_id_seq'),  now(), md5('test2'), 2);

INSERT INTO test_result(test_name, success)
SELECT 'AP Batch created', (SELECT batch_create('test', 'test', 'ap', now()::date)) IS NOT NULL;

INSERT INTO ap (invnumber, entity_credit_account, approved, amount, netamount, curr)
values ('test_hide', (select min(id) from entity_credit_account where entity_class = 1), false, '100000', '100000', 'USD');

INSERT INTO voucher (trans_id, batch_class, batch_id) 
VALUES (currval('id'), 1, currval('batch_id_seq'));

INSERT INTO test_result(test_name, success)
SELECT 'Payment Batch created', (SELECT batch_create('test', 'test', 'ap', now()::date)) IS NOT NULL;

INSERT INTO ap (invnumber, entity_credit_account, approved, amount, netamount, curr, transdate)
values ('test_show', (select min(id) from entity_credit_account where entity_class = 1), false, '100000', '100000', 'USD', now()::date);

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '100000', currval('id'), (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '-100000', currval('id'), (select id from chart where accno = '00002'));

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
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', (select meta_number from entity_credit_account order by id asc limit 1))
)p));

INSERT INTO test_result(test_name, success)
VALUES ('Non-Batch Voucher Not In Payment Selection', 
		(SELECT test_convert_array(invoices) NOT LIKE '%::test_hide::%'
			FROM 
				(SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', (select meta_number from entity_credit_account order by id asc limit 1)))p ));

SELECT * FROM TEST_RESULT;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

ROLLBACK;
