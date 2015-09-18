BEGIN;
\i Base.sql

--- COMMON SETUP
insert into users (entity_id, username, id)
values (-200, '_test1', -200);

insert into session (session_id, users_id, token, last_used)
values (-200, -200, md5(random()::text), now());

INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00001', 'testing', 'A', 'L', 'AP');
INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00002', 'testing2', 'A', 'E', 'AP_amount');
INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00003', 'testing2', 'A', 'A', 'AP_paid');

INSERT INTO session (users_id, last_used, token)
values (currval('users_id_seq'),  now(), md5('test2'));

 -- The test cases in this file create 4 AP items, numbered
 --  * nextval('id') [amount: 1| invnum: 'test_hide'| lines: 0| batch: test]
 --  * nextval('id') [amount: 100 000| invnum: 'test_show2'| lines: 2| batch: -]
 --  * -300 [amount: 1 000 000| invnum: 'test_show3'| lines: 2| batch: -]
 --  * nextval('id') [amount: 1| invnum: 'test_show'| lines: 2| batch: test2]

 -- The cases are all assumed to be local currency (USD).

 -- Additionally, 2 batches are beeing created:
 --  * number: 'test', class: 'ap'
 --  * number: 'test2', class: 'ap' (###TODO test reports "payment batch"?)

 -- Functions being tested:
 --  - batch_create (tests 1, 2)
 --  - payment_get_all_contact_invoices (tests 3-6)

 -- ###TODO Add tests for these functions (absolutely minimally)
 --  - payment_post
 --  - payment_bulk_post


-- TEST 1: AP Batch creation
INSERT INTO test_result(test_name, success)
SELECT 'AP Batch created', (SELECT batch_create('test', 'test', 'ap', now()::date)) IS NOT NULL;


INSERT INTO company (id, legal_name, entity_id)
VALUES (-101, 'TEST', -101);

INSERT INTO business (id, description)
values (-101, 'test');

INSERT INTO entity_credit_account (id, meta_number, threshold, entity_id, entity_class, business_id, ar_ap_account_id)
values (-101, 'TEST1', 100000, -101, 1, -101, -1000); 

INSERT INTO ap (invnumber, entity_credit_account, approved,
                amount_bc, netamount_bc, curr, amount_tc, netamount_tc)
values ('test_hide', -101, false, '1', '1', 'XTS', 1, 1);

INSERT INTO voucher (trans_id, batch_class, batch_id) 
VALUES (currval('id'), 1, currval('batch_id_seq'));

-- TEST 2: Payment batch creation
INSERT INTO test_result(test_name, success)
SELECT 'Payment Batch created', (SELECT batch_create('test2', 'test2', 'ap', now()::date)) IS NOT NULL;
INSERT INTO ap (invnumber, entity_credit_account, approved,
                amount_bc, netamount_bc, curr, amount_tc, netamount_tc,
                transdate, paid_deprecated)
VALUES ('test_show2', -101, true, 100000, 100000, 'XTS',
        100000, 100000, now()::date, 0);

INSERT INTO acc_trans (approved, transdate, amount_bc, curr, amount_tc,
                       trans_id, chart_id)
VALUES (true, now()::date, '100000', 'XTS', '100000',
        currval('id'), (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount_bc, curr, amount_tc,
                       trans_id, chart_id)
VALUES (true, now()::date, '-100000', 'XTS', '-100000', currval('id'),
        (select id from chart where accno = '00002'));

INSERT INTO ap (id, invnumber, entity_credit_account, approved,
                amount_bc, netamount_bc, curr, amount_tc, netamount_tc,
                transdate, paid_deprecated)
VALUES (-300, 'test_show3', -101, true, 1000000, 1000000, 'XTS',
        1000000, 1000000, now()::date, 0);

INSERT INTO acc_trans (approved, transdate, amount_bc, curr, amount_tc,
                       trans_id, chart_id)
VALUES (true, now()::date, '1000000', 'XTS', '1000000',
       -300, (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount_bc, curr, amount_tc,
                       trans_id, chart_id)
VALUES (true, now()::date, '-1000000', 'XTS', '-1000000',
        -300, (select id from chart where accno = '00002'));

update transactions set locked_by = -200 where id = -300;

INSERT INTO ap (invnumber, entity_credit_account, approved,
                amount_bc, netamount_bc, curr, amount_tc, netamount_tc,
                transdate, paid_deprecated)
values ('test_show', -101, false, '1', '1', 'XTS', 1, 1, now()::date, 0);

INSERT INTO acc_trans (approved, transdate, amount_bc, curr, amount_tc,
                       trans_id, chart_id)
VALUES (true, now()::date, '1', 'XTS', 1,
        currval('id'), (select id from chart where accno = '00001'));

INSERT INTO acc_trans (approved, transdate, amount_bc, curr, amount_tc,
                       trans_id, chart_id)
VALUES (true, now()::date, '-1', 'XTS', -1,
        currval('id'), (select id from chart where accno = '00002'));

INSERT INTO voucher (trans_id, batch_class, batch_id) 
VALUES (currval('id'), 1, currval('batch_id_seq'));

CREATE FUNCTION test_convert_array(anyarray) RETURNS text AS
'
	SELECT array_to_string($1, ''::'');
' LANGUAGE SQL;

-- TEST 3: verify payment_get_all_contact_invoices result (1)
INSERT INTO test_result(test_name, success)
VALUES ('Batch Voucher In Payment Selection', 
	(SELECT test_convert_array(invoices) LIKE '%::test_show::%'
			FROM 
				(
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'XTS', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1')
)p));

-- TEST 4: verify payment_get_all_contact_invoices result (2)
INSERT INTO test_result(test_name, success)
VALUES ('Locked Invoice In Payment Selection', 
	(SELECT test_convert_array(invoices) LIKE '%::test_show3::%'
			FROM 
				(
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'XTS', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1')
)p));

-- TEST 5: verify payment_get_all_contact_invoices result (3)
INSERT INTO test_result(test_name, success)
VALUES ('Threshold met', 
	(SELECT test_convert_array(invoices) LIKE '%::test_show2::%'
			FROM 
				(
SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'XTS', NULL, NULL, NULL, '00001', 'TEST1')
)p));

-- TEST 6: verify payment_get_all_contact_invoices result (4)
INSERT INTO test_result(test_name, success)
VALUES ('Non-Batch Voucher Not In Payment Selection', 
		(SELECT test_convert_array(invoices) NOT LIKE '%::test_hide::%'
			FROM 
				(SELECT invoices FROM payment_get_all_contact_invoices(1, NULL, 'XTS', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1'))p ));

INSERT INTO test_result(test_name, success)
VALUES ('Locked Invoice not in total', 
		(SELECT total_due < 1000000
			FROM payment_get_all_contact_invoices(1, NULL, 'XTS', NULL, NULL, currval('batch_id_seq')::int, '00001', 'TEST1')) );

--###TODO Dead code?
-- INSERT INTO voucher(batch_id, batch_class, id, trans_id)
-- values (currval('batch_id_seq')::int, 4, -100, currval('id')::int);
-- INSERT INTO acc_trans(trans_id, chart_id, voucher_id, approved, amount_bc,
--        curr, amount_tc, transdate, source)
-- values (currval('id')::int, 
-- 	(select id from chart where accno = '00003'), -100, true, '1', 'XTS', 1,
--     now(), '_test_src1');
-- INSERT INTO acc_trans(trans_id, chart_id, voucher_id, approved, amount_bc, 
-- 	curr, amount_tc, transdate, source)
-- values (currval('id')::int, 
-- 	(select id from chart where accno = '00001'), -100, true, '-1', 'XTS', 1,
--    now(), '_test_src1');

SELECT * FROM TEST_RESULT;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

 ROLLBACK;
