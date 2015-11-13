BEGIN;
\i Base.sql


insert into users (entity_id, username, id)
values (-200, '_test1', -200);

insert into session (session_id, users_id, token, last_used)
values (-200, -200, md5(random()::text), now());

SELECT account__save(null, accno, description, category, null, null, false, 
                    false, array[link], false, false)
  FROM (VALUES ('00001', 'testing', 'L', 'AP'),
               ('00002', 'testing2', 'E', 'AP_amount'),
               ('00003', 'testing2', 'A', 'AP_paid')) f
               (accno, description, category, link);

INSERT INTO session (users_id, last_used, token)
values (currval('users_id_seq'),  now(), md5('test2'));

INSERT INTO test_result(test_name, success)
SELECT 'AP Batch created', (SELECT batch_create('test', 'test', 'ap', now()::date)) IS NOT NULL;

INSERT INTO company (id, legal_name, entity_id)
VALUES (-101, 'TEST', -101);

INSERT INTO business (id, description)
values (-101, 'test');

INSERT INTO entity_credit_account (id, meta_number, threshold, entity_id, entity_class, business_id, ar_ap_account_id)
values (-101, 'TEST1', 100000, -101, 1, -101, -1000);

INSERT INTO ap (invnumber, entity_credit_account, approved, amount, netamount, curr)
values ('test_hide', -101, false, '1', '1', 'USD');

INSERT INTO voucher (trans_id, batch_class, batch_id)
VALUES (currval('id'), 1, currval('batch_id_seq'));

INSERT INTO test_result(test_name, success)
SELECT 'Payment Batch created', (SELECT batch_create('test2', 'test2', 'ap', now()::date)) IS NOT NULL;
INSERT INTO ap (invnumber, entity_credit_account, approved, amount, netamount, curr, transdate, paid)
VALUES ('test_show2', -101, true, 100000, 100000, 'USD', now()::date, 0);

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '100000', currval('id'), (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '-100000', currval('id'), (select id from chart where accno = '00002'));

INSERT INTO ap (id, invnumber, entity_credit_account, approved, amount, netamount, curr, transdate, paid)
VALUES (-300, 'test_show3', -101, true, 1000000, 1000000, 'USD', now()::date, 0);

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '1000000', -300, (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount, trans_id, chart_id)
VALUES (true, now()::date, '-1000000', -300, (select id from chart where accno = '00002'));

update transactions set locked_by = -200 where id = -300;

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
VALUES ('Locked Invoice In Payment Selection',
	(SELECT test_convert_array(invoices) LIKE '%::test_show3::%'
			FROM
				(
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1')
)p));

INSERT INTO test_result(test_name, success)
VALUES ('Threshold met',
	(SELECT test_convert_array(invoices) LIKE '%::test_show2::%'
			FROM
				(
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, NULL, '00001', 'TEST1')
)p));

INSERT INTO test_result(test_name, success)
VALUES ('Non-Batch Voucher Not In Payment Selection',
		(SELECT test_convert_array(invoices) NOT LIKE '%::test_hide::%'
			FROM
				(SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1'))p ));

INSERT INTO test_result(test_name, success)
VALUES ('Locked Invoice not in total',
		(SELECT total_due < 1000000
			FROM payment_get_all_contact_invoices(1, NULL, 'USD', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1')) );

INSERT INTO voucher(batch_id, batch_class, id, trans_id)
values (currval('batch_id_seq')::int, 4, -100, currval('id')::int);
INSERT INTO acc_trans(trans_id, chart_id, voucher_id, approved, amount,
	transdate, source)
values (currval('id')::int,
	(select id from chart where accno = '00003'), -100, true, '1', now(),
	'_test_src1');
INSERT INTO acc_trans(trans_id, chart_id, voucher_id, approved, amount,
	transdate, source)
values (currval('id')::int,
	(select id from chart where accno = '00001'), -100, true, '-1', now(),
	'_test_src1');

SELECT * FROM TEST_RESULT;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

 ROLLBACK;
