BEGIN;
\i Base.sql

INSERT INTO entity_credit_account (id, entity_id, entity_class, meta_number)
SELECT '-1', min(id), 1, '_test vendor'
FROM entity;

INSERT INTO entity_credit_account (id, entity_id, entity_class, meta_number)
SELECT '-2', min(id), 2, '_test customer'
FROM entity;

INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00001', 'AP Test', 'A', 'L', 'AP');

INSERT INTO chart (accno, description, charttype, category, link)
VALUES ('00002', 'AR Test', 'A', 'A', 'AP');

INSERT INTO ap (invnumber, entity_credit_account, amount, netamount, paid, 
	approved, curr)
select '_TEST AP', min(id), '100', '100', '0', FALSE, 'USD'
FROM entity_credit_account WHERE entity_class = 1;

INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '100', TRUE FROM chart WHERE accno = '00001';
INSERT INTO acc_trans (chart_id, trans_id, amount, approved)
SELECT id, currval('id'), '-100', TRUE FROM chart WHERE accno = '00002';

INSERT INTO ar (invnumber, entity_credit_account, amount, netamount, paid, 
	approved, curr)
select '_TEST AR', min(id), '100', '100', '0', FALSE, 'USD'
FROM entity_credit_account WHERE entity_class = 2;

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
