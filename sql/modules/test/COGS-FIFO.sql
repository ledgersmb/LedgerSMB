BEGIN;
\i Base.sql

INSERT INTO account_heading (id, accno, description)
VALUES (-1000, '-1000', 'Test heading');


INSERT INTO account (id, accno, category, description, heading)
VALUES (-1101, 'TEST1001', 'A', 'COGS test series 1 Inventory', -1000),
       (-1102, 'TEST1002', 'E', 'COGS test series 1 COGS', -1000),
       (-1103, 'TEST1003', 'E', 'COGS test series 1 returns', -1000),
       (-1104, 'TEST1004', 'I', 'COGS test series 1 income', -1000),
       (-2101, 'TEST2001', 'A', 'COGS test series 2 Inventory', -1000),
       (-2102, 'TEST2002', 'E', 'COGS test series 1 COGS', -1000),
       (-2103, 'TEST2003', 'E', 'COGS test series 1 returns', -1000),
       (-2104, 'TEST2004', 'I', 'COGS test series 1 income', -1000),
       (-3101, 'TEST3002', 'A', 'COGS test series 2 Inventory', -1000),
       (-3102, 'TEST3001', 'E', 'COGS test series 1 COGS', -1000),
       (-3103, 'TEST3003', 'E', 'COGS test series 1 returns', -1000),
       (-3104, 'TEST3004', 'I', 'COGS test series 1 income', -1000),
       (-4101, 'TEST4001', 'A', 'COGS test series 2 Inventory', -1000),
       (-4102, 'TEST4002', 'E', 'COGS test series 1 COGS', -1000),
       (-4103, 'TEST4003', 'E', 'COGS test series 1 returns', -1000),
       (-4104, 'TEST4004', 'I', 'COGS test series 1 income', -1000);

INSERT INTO parts 
       (id, partnumber, description, income_accno_id, expense_accno_id, 
        inventory_accno_id, returns_accno_id)
VALUES (-1, 'TS1', 'COGS Test Series 1', -1101, -1102, -1104, -1103),
       (-2, 'TS2', 'COGS Test Series 2', -2101, -2102, -2104, -2103),
       (-3, 'TS3', 'COGS Test Series 3', -3101, -3102, -3104, -3103),
       (-4, 'TS4', 'COGS Test Series 4', -4101, -4102, -4104, -4103);
  
INSERT INTO entity (id, name, country_id, entity_class)
VALUES (-1000, 'Test act', 232, 1);

INSERT INTO entity_credit_account 
        (id, entity_class, meta_number, entity_id, curr, ar_ap_account_id)
VALUES (-1000, 1, 'cogs test1', -1000, 'USD', -1103), 
       (-2000, 2, 'cogs test2', -1000, 'USD', -1103);
-- First series of tests, AR before AP
INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-1201, true, 'test1001', now() - '10 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-1201, -1201, -1, 100, 0, 3);

INSERT INTO test_result (test_name, success)
SELECT 'initial COGS is null, (invoice 1, series 1)', sum(amount) IS NULL
  from acc_trans 
 where trans_id = -1201 and chart_id = -1102;

SELECT cogs__add_for_ar_line(-1201);

INSERT INTO test_result (test_name, success)
SELECT 'post-run COGS is 0, (invoice 1, series 1)', sum(amount) = 0
  from acc_trans 
 where trans_id = -1201 and chart_id = -1102;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-1202,  true, 'test1002', now() - '10 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-1202, -1202, -1, -75, 0, 0.5);

SELECT cogs__add_for_ap_line(-1202);

INSERT INTO test_result (test_name, success)
SELECT 'post-ap-run COGS is 37.50, (invoice 1, series 1)', sum(amount) = -37.5
  from acc_trans 
 where trans_id = -1201 and chart_id = -1102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 75 (invoice 1, series 1)', allocated = -75
FROM invoice WHERE id = -1201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 75 (invoice 2, series 1)', allocated = 75
FROM invoice WHERE id = -1202;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-1203, true, 'test1003', now() - '9 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-1203, -1203, -1, 100, 0, 3);

INSERT INTO test_result (test_name, success)
SELECT 'initial COGS is null, (invoice 3, series 1)', sum(amount) IS NULL
  from acc_trans 
 where trans_id = -1203 and chart_id = -1102;

SELECT cogs__add_for_ar_line(-1203);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 75 (invoice 1, series 1)', allocated = -75
FROM invoice WHERE id = -1201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated still 75 (invoice 2, series 1)', allocated = 75
FROM invoice WHERE id = -1202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 0 (invoice 3, series 1)', allocated = 0
FROM invoice WHERE id = -1203;

--duplicate to check against reversals
INSERT INTO test_result (test_name, success)
SELECT 'post-ap-run COGS still 37.50, (invoice 1, series 1)', 
       sum(amount) = -37.5
  from acc_trans 
 where trans_id = -1201 and chart_id = -1102;

INSERT INTO test_result (test_name, success)
SELECT 'post-run COGS is 0, (invoice 3, series 1)', 
        sum(amount) = 0 
  from acc_trans 
 where trans_id = -1203 and chart_id = -1102;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-1204,  true, 'test1004', now() - '8 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-1204, -1204, -1, -75, 0, 1);

SELECT cogs__add_for_ap_line(-1204);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 100 (invoice 1, series 1)', allocated = -100
FROM invoice WHERE id = -1201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated still 75 (invoice 2, series 1)', allocated = 75
FROM invoice WHERE id = -1202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 50 (invoice 3, series 1)', allocated = -50
FROM invoice WHERE id = -1203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 75 (invoice 4, series 1)', allocated = 75
FROM invoice WHERE id = -1204;

INSERT INTO test_result (test_name, success)
SELECT 'post-ap-run COGS is 62.50, (invoice 1, series 1)', sum(amount) = -62.5
  from acc_trans 
 where trans_id = -1201 and chart_id = -1102;

INSERT INTO test_result (test_name, success)
SELECT 'post-ap-run COGS is 50, (invoice 2, series 1)', sum(amount) = -50
  from acc_trans 
 where trans_id = -1203 and chart_id = -1102;


INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-1205,  true, 'test1004', now() - '8 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-1205, -1205, -1, -50, 0, 2);

SELECT cogs__add_for_ap_line(-1205);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated still 100 (invoice 1, series 1)', allocated = -100
FROM invoice WHERE id = -1201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated still 75 (invoice 2, series 1)', allocated = 75
FROM invoice WHERE id = -1202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 100 (invoice 3, series 1)', allocated = -100
FROM invoice WHERE id = -1203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated still 75 (invoice 4, series 1)', allocated = 75
FROM invoice WHERE id = -1204;


INSERT INTO test_result(test_name, success)
SELECT 'post-ap-run allocated 50 (invoice 5, series 1)', allocated = 50
FROM invoice WHERE id = -1205;

INSERT INTO test_result (test_name, success)
SELECT 'post-ap-run COGS is 62.50, (invoice 1, series 1)', sum(amount) = -62.5
  from acc_trans 
 where trans_id = -1201 and chart_id = -1102;

SELECT 'post-ap-run COGS is 62.50, (invoice 1, series 1)', sum(amount)
from acc_trans
 where trans_id = -1201 and chart_id = -1102;


INSERT INTO test_result (test_name, success)
SELECT 'post-ap-run COGS is 150, (invoice 2, series 1)', sum(amount) = -150
  from acc_trans 
 where trans_id = -1203 and chart_id = -1102;

-- Series 2, AP invoices first, cogs only added to AR

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-2201,  true, 'test2001', now() - '10 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-2201, -2201, -2, -100, 0, 0.5);

SELECT cogs__add_for_ap_line(-2201);

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 0 post-AP run (invoice 1 series 2)', allocated = 0
  FROM invoice WHERE id = -2201;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-2202,  true, 'test2001', now() - '10 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-2202, -2202, -2, 75, 0, 3);

SELECT cogs__add_for_ar_line(-2202);

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AR run (invoice 1 series 2)', allocated = 75
  FROM invoice WHERE id = -2201;

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AR run (invoice 2 series 2)', allocated = -75
  FROM invoice WHERE id = -2202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-run COGS is 37.50, (invoice 2, series 2)', sum(amount) = -37.5
from acc_trans
 where trans_id = -2202 and chart_id = -2102;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-2203,  true, 'test2003', now() - '9 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-2203, -2203, -2, -100, 0, 1);

SELECT cogs__add_for_ap_line(-2203);

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AP run (invoice 1 series 2)', allocated = 75
  FROM invoice WHERE id = -2201;

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AP run (invoice 2 series 2)', allocated = -75
  FROM invoice WHERE id = -2202;

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 0 post-AP run (invoice 3 series 2)', allocated = 0
  FROM invoice WHERE id = -2203;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-2204,  true, 'test2004', now() - '7 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-2204, -2204, -2, 75, 0, 3);

SELECT cogs__add_for_ar_line(-2204);

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4, allocation invoice 1 series 2 is 100', allocated = 100
  FROM invoice WHERE id = -2201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4, allocation invoice 2 series 2 is 75', allocated = -75
  FROM invoice WHERE id = -2202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4, allocation invoice 3 series 2 is 50', allocated = 50
  FROM invoice WHERE id = -2203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4, allocation invoice 4 series 2 is 75', allocated = -75
  FROM invoice WHERE id = -2204;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4 COGS is 37.50, (invoice 2, series 2)', sum(amount) = -37.5
from acc_trans
 where trans_id = -2202 and chart_id = -2102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4 COGS is 62.50, (invoice 2, series 4)', sum(amount) = -62.5
from acc_trans
 where trans_id = -2204 and chart_id = -2102;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-2205,  true, 'test2005', now() - '5 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-2205, -2205, -2, 75, 0, 3);

SELECT cogs__add_for_ar_line(-2205);


INSERT INTO test_result(test_name, success)
SELECT 'post-ar-5, allocation invoice 1 series 2 is 100', allocated = 100
  FROM invoice WHERE id = -2201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-5, allocation invoice 2 series 2 is 75', allocated = -75
  FROM invoice WHERE id = -2202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-5, allocation invoice 3 series 2 is 100', allocated = 100
  FROM invoice WHERE id = -2203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-5, allocation invoice 4 series 2 is 75', allocated = -75
  FROM invoice WHERE id = -2204;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-5, allocation invoice 5 series 2 is 50', allocated = -50
  FROM invoice WHERE id = -2205;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-5 COGS is 37.50, (invoice 2, series 2)', sum(amount) = -37.5
from acc_trans
 where trans_id = -2202 and chart_id = -2102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4 COGS is 62.50, (invoice 2, series 4)', sum(amount) = -62.5
from acc_trans
 where trans_id = -2204 and chart_id = -2102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-4 COGS is 50, (invoice 2, series 5)', sum(amount) = -50
from acc_trans
 where trans_id = -2205 and chart_id = -2102;

-- Series 2.5, AR reversal
-- Series 3, Mixed

-- Series 4, AP Reversal

-- finalization
SELECT sum(amount) as balance, chart_id, trans_id from acc_trans 
 WHERE trans_id < -1000
GROUP BY chart_id, trans_id;

SELECT id, parts_id, qty, allocated, sellprice from invoice
 WHERE trans_id < -1000;


SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
-- */
