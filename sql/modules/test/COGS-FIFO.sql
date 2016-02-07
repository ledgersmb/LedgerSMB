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
       (-4, 'TS4', 'COGS Test Series 4', -4101, -4102, -4104, -4103),
       (-5, 'TS5', 'COGS Test Series 5', -2101, -2102, -2104, -2103);

INSERT INTO entity (id, name, country_id, entity_class)
VALUES (-1000, 'Test act', 232, 1);

INSERT INTO entity_credit_account
        (id, entity_class, meta_number, entity_id, curr, ar_ap_account_id)
VALUES (-1000, 1, 'cogs test1', -1000, 'USD', -1103),
       (-2000, 2, 'cogs test2', -1000, 'USD', -1103);
-- First series of tests, AR before AP
INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account, approved)
VALUES (-1201, true, 'test1001', now() - '10 days'::interval, -2000, 't');
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-1201, -1201, -1, 100, 0, 3);

INSERT INTO test_result (test_name, success)
SELECT 'initial COGS is null, (invoice 1, series 1)', sum(amount) IS NULL
  from acc_trans
 where trans_id = -1201 and chart_id = -1102;


SELECT cogs__add_for_ar_line(-1201);
select * from invoice where id < 0;

INSERT INTO test_result (test_name, success)
SELECT 'post-run COGS is 0, (invoice 1, series 1)', sum(amount) = 0
  from acc_trans
 where trans_id = -1201 and chart_id = -1102;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account, approved)
VALUES (-1202,  true, 'test1002', now() - '10 days'::interval, -1000, 't');
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
VALUES (-2205, -2205, -2, 50, 0, 3);

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
SELECT 'post-ar-5 COGS is 62.50, (invoice 2, series 4)', sum(amount) = -62.5
from acc_trans
 where trans_id = -2204 and chart_id = -2102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-5 COGS is 50, (invoice 2, series 5)', sum(amount) = -50
from acc_trans
 where trans_id = -2205 and chart_id = -2102;

-- Series 2.5, AR reversal

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-2206,  true, 'test2006', now() - '4 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-2206, -2206, -2, -150, 0, 3);

SELECT cogs__add_for_ar_line(-2206);


INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6, allocation invoice 1 series 2 is 50; ', allocated = 50
  FROM invoice WHERE id = -2201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6, allocation invoice 2 series 2 is -75', allocated = -75
  FROM invoice WHERE id = -2202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6, allocation invoice 3 series 2 is 0; ', allocated = 0
  FROM invoice WHERE id = -2203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6, allocation invoice 4 series 2 is -75; ', allocated = -75
  FROM invoice WHERE id = -2204;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6, allocation invoice 5 series 2 is -50; ', allocated = -50
  FROM invoice WHERE id = -2205;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6, allocation invoice 6 series 2 is 150; ', allocated = 150
  FROM invoice WHERE id = -2206;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6 COGS is 37.50, (invoice 2, series 2)', sum(amount) = -37.5
from acc_trans
 where trans_id = -2202 and chart_id = -2102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6 COGS is 62.50, (invoice 4, series 2)', sum(amount) = -62.5
from acc_trans
 where trans_id = -2204 and chart_id = -2102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6 COGS is 50, (invoice 5, series 2)', sum(amount) = -50
from acc_trans
 where trans_id = -2205 and chart_id = -2102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-6 COGS is -125, (invoice 6, series 2)', sum(amount) = 125
from acc_trans
 where trans_id = -2206 and chart_id = -2102;

-- Series 3, Mixed

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-3201,  true, 'test3001', now() - '10 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-3201, -3201, -3, -100, 0, 0.5);

SELECT cogs__add_for_ap_line(-3201);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-1, allocation invoice 1 series 3 is 0', allocated = 0
  FROM invoice WHERE id = -3201;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-3202,  true, 'test3002', now() - '9 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-3202, -3202, -3, 75, 0, 3);

SELECT cogs__add_for_ar_line(-3202);

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AR run (invoice 1 series 3)', allocated = 75
  FROM invoice WHERE id = -3201;

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AR run (invoice 2 series 3)', allocated = -75
  FROM invoice WHERE id = -3202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-run COGS is 37.50, (invoice 2, series 3)', sum(amount) = -37.5
from acc_trans
 where trans_id = -3202 and chart_id = -3102;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-3203,  true, 'test3003', now() - '9 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-3203, -3203, -3, 75, 0, 3);

SELECT cogs__add_for_ar_line(-3203);

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 100 post-AR run (invoice 1 series 3)', allocated = 100
  FROM invoice WHERE id = -3201;

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AR run (invoice 2 series 3)', allocated = -75
  FROM invoice WHERE id = -3202;

INSERT INTO test_result(test_name, success)
SELECT 'Allocated is 75 post-AR run (invoice 3 series 3)', allocated = -25
  FROM invoice WHERE id = -3203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-run COGS is 37.50, (invoice 2, series 3)', sum(amount) = -37.5
from acc_trans
 where trans_id = -3202 and chart_id = -3102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-run COGS is 12.5, (invoice 3, series 3)', sum(amount) = -12.5
from acc_trans
 where trans_id = -3203 and chart_id = -3102;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-3204,  true, 'test3004', now() - '8 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-3204, -3204, -3, -100, 0, 1);

SELECT cogs__add_for_ap_line(-3204);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is 100 post-AR run (invoice 1 series 3)',
       allocated = 100
  FROM invoice WHERE id = -3201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is 75 post-AR run (invoice 2 series 3)',
        allocated = -75
  FROM invoice WHERE id = -3202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is 75 post-AR run (invoice 3 series 3)', allocated = -75
  FROM invoice WHERE id = -3203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is 50 post-AR run (invoice 4 series 3)', allocated = 50
  FROM invoice WHERE id = -3204;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 COGS is 37.50, (invoice 2, series 3)', sum(amount) = -37.5
from acc_trans
 where trans_id = -3202 and chart_id = -3102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 COGS is 62.5, (invoice 3, series 3)', sum(amount) = -62.5
from acc_trans
 where trans_id = -3203 and chart_id = -3102;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-3205,  true, 'test3005', now() - '9 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-3205, -3205, -3, 75, 0, 3);

SELECT cogs__add_for_ar_line(-3205);


INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 Allocated is 100 post-AR run (invoice 1 series 3)',
       allocated = 100
  FROM invoice WHERE id = -3201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 Allocated is 75 post-AR run (invoice 2 series 3)',
        allocated = -75
  FROM invoice WHERE id = -3202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 Allocated is 75 post-AR run (invoice 3 series 3)', allocated = -75
  FROM invoice WHERE id = -3203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 Allocated is 100 post-AR run (invoice 4 series 3)',
       allocated = 100
  FROM invoice WHERE id = -3204;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 Allocated is 50 post-AR run (invoice 5 series 3)', allocated = -50
  FROM invoice WHERE id = -3205;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 COGS is 37.50, (invoice 2, series 3)', sum(amount) = -37.5
from acc_trans
 where trans_id = -3202 and chart_id = -3102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 COGS is 62.5, (invoice 3, series 3)', sum(amount) = -62.5
from acc_trans
 where trans_id = -3203 and chart_id = -3102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-5 COGS is 50, (invoice 3, series 5)', sum(amount) = -50
from acc_trans
 where trans_id = -3205 and chart_id = -3102;


-- Series 4, AP Reversal

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-4201,  true, 'test3001', now() - '10 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-4201, -4201, -4, -100, 0, 1);

SELECT cogs__add_for_ap_line(-4201);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-1 Allocated is 0 (invoice 1 series 4)', allocated = 0
  FROM invoice WHERE id = -4201;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-4202,  true, 'test4002', now() - '10 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-4202, -4202, -4, 75, 0, 1);

SELECT cogs__add_for_ap_line(-4202);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-2 Allocated is 75 (invoice 1 series 4)', allocated = 75
  FROM invoice WHERE id = -4201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-2 Allocated is -75 (invoice 2 series 4)', allocated = -75
  FROM invoice WHERE id = -4202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-2 COGS is 0, invoice 2, series 4)', sum(amount) = 0
  FROM acc_trans
 WHERE trans_id = -4202 and chart_id = -4102;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-4203,  true, 'test4003', now() - '7 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-4203, -4203, -4, -100, 0, 0.5);

SELECT cogs__add_for_ap_line(-4203);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-3 Allocated is 75 (invoice 1 series 4)', allocated = 75
  FROM invoice WHERE id = -4201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-3 Allocated is -75 (invoice 2 series 4)', allocated = -75
  FROM invoice WHERE id = -4202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-3 Allocated is 0 (invoice 3 series 4)', allocated = 0
  FROM invoice WHERE id = -4203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-3 COGS is 0, invoice 2, series 4)', sum(amount) = 0
  FROM acc_trans
 WHERE trans_id = -4202 and chart_id = -4102;

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-4204,  true, 'test4002', now() - '5 days'::interval, -1000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-4204, -4204, -4, 75, 0, 1);

SELECT cogs__add_for_ap_line(-4204);

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is 100 (invoice 1 series 4)', allocated = 100
  FROM invoice WHERE id = -4201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is -75 (invoice 2 series 4)', allocated = -75
  FROM invoice WHERE id = -4202;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is 50 (invoice 3 series 4)', allocated = 50
  FROM invoice WHERE id = -4203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 Allocated is 75 (invoice 4 series 4)', allocated = -75
  FROM invoice WHERE id = -4204;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 COGS is 0, invoice 2, series 4)', sum(amount) = 0
  FROM acc_trans
 WHERE trans_id = -4202 and chart_id = -4102;

INSERT INTO test_result(test_name, success)
SELECT 'post-ap-4 COGS is 25, invoice 2, series 4)', sum(amount) = 25
  FROM acc_trans
 WHERE trans_id = -4204 and chart_id = -4102;

INSERT INTO test_result(test_name, success)
SELECT 'multi-call-safe ar cogs, id ' || i.id, cogs__add_for_ar_line(i.id) = 0
  FROM invoice i JOIN ar ON ar.id = i.trans_id
 WHERE i.id < -1000;

INSERT INTO test_result(test_name, success)
SELECT 'multi-call-safe ap cogs, id ' || i.id, cogs__add_for_ap_line(i.id) = 0
  FROM invoice i JOIN ap ON ap.id = i.trans_id
 WHERE i.id < -1000;



-- Series 5, AR reversal

-- Simple reversal of invoice without allocation
INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-5201,  true, 'test5001', now() - '4 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-5201, -5201, -5, 150, 0, 3);

SELECT cogs__add_for_ar_line(-5201);

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-1, allocation invoice 1 series 5 is 0; ', allocated = 0
  FROM invoice WHERE id = -5201;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-5202,  true, 'test5002', now() - '4 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-5202, -5202, -5, -150, 0, 3);

SELECT cogs__add_for_ar_line(-5202);

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-2, allocation invoice 1 series 5 is -150; ', allocated = -150
  FROM invoice WHERE id = -5201;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-2, allocation invoice 2 series 5 is 150; ', allocated = 150
  FROM invoice WHERE id = -5202;

-- Reversal of invoice with allocation, reallocates to invoice without and AP

-- Test outline:
--  * Set up an ar invoice and an ap invoice, each at 150 units
--  * Allocate these against each other
--  * Set up another ar invoice at 75 units
--  * Allocate the new invoice / no units availeble == no effect
--  * Reverse the original AR invoice at 150 units
--  * Allocate the reversal invoice
--  * The second AR invoice is now allocated
--  * The AP invoice is 50% de-allocated

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-5203,  true, 'test5003', now() - '4 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-5203, -5203, -5, 150, 0, 3);

INSERT INTO ap (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-5104,  true, 'test5004', now() - '4 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-5104, -5104, -5, -150, 0, 3);

SELECT cogs__add_for_ap_line(-5104);

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-1, allocation invoice 3 series 5 is -150; ', allocated = -150
  FROM invoice WHERE id = -5203;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-1, allocation invoice 4 series 5 is 150; ', allocated = 150
  FROM invoice WHERE id = -5104;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-5205,  true, 'test5005', now() - '4 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-5205, -5205, -5, 75, 0, 3);

SELECT cogs__add_for_ar_line(-5205);

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-2, allocation invoice 5 series 5 is 0', allocated = 0
  FROM invoice WHERE id = -5205;

INSERT INTO ar (id, invoice, invnumber, transdate, entity_credit_account)
VALUES (-5206,  true, 'test5006-rev3', now() - '4 days'::interval, -2000);
INSERT INTO invoice (id, trans_id, parts_id, qty, allocated, sellprice)
VALUES (-5206, -5206, -5, -150, 0, 3);

SELECT cogs__add_for_ar_line(-5206);

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-3, allocation invoice 5 series 5 is -75', allocated = -75
  FROM invoice WHERE id = -5205;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-3, allocation invoice 6 series 5 is 150', allocated = 150
  FROM invoice WHERE id = -5206;

INSERT INTO test_result(test_name, success)
SELECT 'post-ar-3, allocation invoice 4 series 5 is -75; ' || allocated, allocated = -75
  FROM invoice WHERE id = -5204;


SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

-- */
ROLLBACK;
