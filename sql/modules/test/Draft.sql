BEGIN;
\i Base.sql
INSERT INTO entity (id, entity_class, name, country_id)
VALUES (-1000, 1, '__TEST', 243);

INSERT INTO entity_credit_account (id, meta_number, entity_class, entity_id, ar_ap_account_id)
VALUES (-1000, '_testv', 1, -1000, -1000);
INSERT INTO entity_credit_account (id, meta_number, entity_class, entity_id, ar_ap_account_id)
VALUES (-1001, '_testc', 2, -1000, -1000);
SELECT account__save
       (NULL, '00001', 'test only', 'A', NULL, NULL, FALSE, FALSE,'{}', false,
       false);
SELECT account__save
       (NULL, '00002', 'test only', 'A', NULL, NULL, FALSE, FALSE,'{}', false,
       false);
INSERT INTO ap (invnumber, entity_credit_account, amount, netamount, paid,
	approved, curr)
select '_TEST AP', -1000, '100', '100', '0', FALSE, 'USD';

INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '100', TRUE FROM chart WHERE accno = '00001';
INSERT INTO ac_tax_form (entry_id, reportable)
VALUES (currval('acc_trans_entry_id_seq')::int, true);
INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '-100', TRUE FROM chart WHERE accno = '00002';
INSERT INTO ac_tax_form (entry_id, reportable)
VALUES (currval('acc_trans_entry_id_seq')::int, false);

INSERT INTO ar (invnumber, entity_credit_account, amount, netamount, paid,
	approved, curr)
select '_TEST AR', -1001, '100', '100', '0', FALSE, 'USD';

INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '-100', TRUE FROM chart WHERE accno = '00001';
INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '100', TRUE FROM chart WHERE accno = '00002';

INSERT INTO gl (reference, description, approved)
VALUES ('_TEST GL', 'Testing GL Drafts', false);

INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '-100', TRUE FROM chart WHERE accno = '00001';
INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '100', TRUE FROM chart WHERE accno = '00002';

INSERT INTO test_result(test_name, success)
SELECT '"ap" search successful', count(*) = 1
FROM draft__search('ap',  NULL, NULL, NULL, NULL, NULL)
WHERE reference = '_TEST AP';

INSERT INTO test_result(test_name, success)
SELECT '"AP" search successful', count(*) = 1
FROM draft__search('AP',  NULL, NULL, NULL, NULL, NULL)
WHERE reference = '_TEST AP';

INSERT INTO test_result(test_name, success)
SELECT '"AP" delete successful (w/1099)', draft_delete(id)
FROM draft__search('AP',  NULL, NULL, NULL, NULL, NULL)
WHERE reference = '_TEST AP';

INSERT INTO test_result(test_name, success)
SELECT '"ar" search successful', count(*) = 1
FROM draft__search('ar',  NULL, NULL, NULL, NULL, NULL)
WHERE reference = '_TEST AR';

INSERT INTO test_result(test_name, success)
SELECT '"AR" search successful', count(*) = 1
FROM draft__search('AR',  NULL, NULL, NULL, NULL, NULL)
WHERE reference = '_TEST AR';

INSERT INTO test_result(test_name, success)
SELECT '"gl" search successful', count(*) = 1
FROM draft__search('gl',  NULL, NULL, NULL, NULL, NULL)
WHERE reference = '_TEST GL';

INSERT INTO test_result(test_name, success)
SELECT '"GL" search successful', count(*) = 1
FROM draft__search('GL',  NULL, NULL, NULL, NULL, NULL)
WHERE reference = '_TEST GL';

INSERT INTO test_result(test_name, success)
SELECT 'gl draft deletion', draft_delete(currval('id')::int);

INSERT INTO test_result(test_name, success)
SELECT 'gl table cleanup', count(*) = 0 from gl where id = currval('id');

INSERT INTO test_result(test_name, success)
SELECT 'acc_trans table cleanup', count(*) = 0 from acc_trans where trans_id = currval('id');

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
