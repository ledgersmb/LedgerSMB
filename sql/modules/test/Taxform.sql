/*


*igning tests. Thinking:

1) Correct number of lines on summary report
2) Correct total on summary report
3) Correct number of lines on detail report
4) Correct totals on detail report
5) Correct total summary report for future year
6) Correct number of lines for report on future year
7) Correct number of lines on detail report for futture year
8) Correct totals on lines of details report for future year

Invoices 8:

1) AP transaction: Reportable amount 1000, non-reportable amount $10, paid
in full in current year.
2) AP transaction: Reportable amount $1000, non-reportable amount $10,
partially paid ($500) in current year
3) AP Transaction: Reportable amount $1000, non-reportable amount $10,
paid $500 currnet year, $500 in future year

4) AP invoice: Reportable amount 1000, non-reportable amount $10, paid in
full in current year.
5) AP invoice: Reportable amount $1000, non-reportable amount $10,
partially paid ($500) in current year
6) AP invice: Reportable amount $1000, non-reportable amount $10, paid
$500 currnet year, $500 in future year

7 like 1 but different vendor
8 like 4 but different vendor

--CT

*/

BEGIN;

\i Base.sql


-- Basic setup
INSERT INTO account_heading(id, accno ) VALUES (-255, '-billion');
INSERT INTO account (id, accno, category, heading ) VALUES (-255, '-billion', 'L', -255);
INSERT INTO account (id, accno, category, heading ) VALUES (-256, '-billiontest', 'L', -255);


INSERT INTO country_tax_form (country_id, form_name, id) VALUES (232, 'Testing Form', -511);

INSERT INTO parts (id, partnumber, description) values (-255, '-test1', 'test 1');
INSERT INTO parts (id, partnumber, description) values (-256, '-test2', 'test 2');

-- Set up an ECAs, for AP.

INSERT INTO entity_credit_account (id, entity_id, entity_class, meta_number, taxform_id, ar_ap_account_id) VALUES (-255, -100, 1, 'Test account 1', -511, -255);

INSERT INTO company (id, entity_id, legal_name) VALUES (-1024, -100, 'Testing Tax Form');

INSERT INTO entity_credit_account (id, entity_id, entity_class, meta_number, taxform_id, ar_ap_account_id) VALUES (-256, -101, 1, 'Test account 2', -511, -255);

INSERT INTO company (id, entity_id, legal_name) VALUES (-1025, -101, 'Testing Tax Form');

CREATE OR REPLACE FUNCTION date1() RETURNS date AS
$$
SELECT (extract('YEAR' from now())|| '-12-01')::date;
$$ language sql;

CREATE OR REPLACE FUNCTION date2() RETURNS date AS
$$
SELECT ((extract('YEAR' from now())|| '-12-01')::date
        + '1 year'::interval)::date;
$$ language sql;

INSERT INTO account_link (account_id, description)
values (-1000, 'AP');

INSERT INTO account_link (account_id, description)
values (-1001, 'AP_amount');

INSERT INTO account_link (account_id, description)
values (-1002, 'AP_paid');
--AP transactions.

--1) AP transaction: Reportable amount 1000, non-reportable amount $10, paid
-- in full in current year. id -1024

INSERT INTO ap (id, transdate, amount, netamount, curr, entity_credit_account,
                approved)
values(-1024, date1(), 1010, 1010, 'USD', -255, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1024, -1000, date1(), 1010, true, -111);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1024, -1001, date1(), -1000, true, -112);

INSERT INTO ac_tax_form(entry_id, reportable) values (-112, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1024, -1001, date1(), -10, true, -113);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1024, -1002, date1(), 1010, true, -114);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1024, -1000, date1(), -1010, true, -115);

-- 2) AP transaction: Reportable amount $1000, non-reportable amount $10,
-- partially paid ($500) in current year -1025

INSERT INTO ap (id, transdate, amount, netamount, curr, entity_credit_account,
            approved)
values(-1025, date1(), 1010, 1010, 'USD', -255, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1025, -1000, date1(), 1010, true, -121);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1025, -1001, date1(), -1000, true, -122);

INSERT INTO ac_tax_form(entry_id, reportable) values (-122, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1025, -1001, date1(), -10, true, -123);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1025, -1002, date1(), 505, true, -124);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1025, -1000, date1(), -505, true, -125);

-- 3)_AP Transaction: Reportable amount $1000, non-reportable amount $10,
-- paid $500 currnet year, $500 in future year -1026


INSERT INTO ap (id, transdate, amount, netamount, curr, entity_credit_account,
            approved)
      values(-1026, date1(), 1010, 1010, 'USD', -255, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1026, -1000, date1(), 1010, true, -131);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1026, -1001, date1(), -1000, true, -132);

INSERT INTO ac_tax_form(entry_id, reportable) values (-132, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1026, -1001, date1(), -10, true, -133);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1026, -1002, date1(), 505, true, -134);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1026, -1000, date1(), -505, true, -135);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1026, -1002, date2(), 505, true, -136);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1026, -1000, date2(), -505, true, -137);

-- 4) AP transaction: Reportable amount 1000, non-reportable amount $10, paid
-- $500 currnet year, $500 in future year -1027, to second vendor
-- Vendor Invoices.

INSERT INTO ap (id, transdate, amount, netamount, curr, entity_credit_account,
            approved)
values(-1027, date1(), 1010, 1010, 'USD', -256, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1027, -1000, date1(), 1010, true, -141);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1027, -1001, date1(), -1000, true, -142);

INSERT INTO ac_tax_form(entry_id, reportable) values (-142, true);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1027, -1001, date1(), -10, true, -143);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1027, -1002, date1(), 1010, true, -144);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1027, -1000, date1(), -1010, true, -145);


-- 2) AP invoice: Reportable amount $1000, non-reportable amount $10,
-- partially paid ($500) in current year -1035

INSERT INTO ar (id, transdate, amount, netamount, curr, entity_credit_account,
                approved, invoice, invnumber)
      values(-1035, date1(), 1010, 1010, 'USD', -255, true, true, 'test1');

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1035, -1000, date1(), 1010, true, -221);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1035, -1001, date1(), -1000, true, -222);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1035, -1001, date1(), -10, true, -223);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1035, -1002, date1(), 505, true, -224);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1035, -1000, date1(), -505, true, -225);

insert into invoice(trans_id, id, parts_id, description, qty, sellprice)
     VALUES (-1035, -211, -255, 'test 1', -1, 1000);

INSERT INTO invoice_tax_form(invoice_id, reportable)
     VALUES (-211, true);

insert into invoice(trans_id, id, parts_id, description, qty, sellprice)
     VALUES (-1035, -212, -256, 'test 1', -1, 10);

-- 3)_AP invoice: Reportable amount $1000, non-reportable amount $10,
-- paid $500 currnet year, $500 in future year -1036

INSERT INTO ar (id, transdate, amount, netamount, curr, entity_credit_account,
                approved, invoice, invnumber)
      values(-1036, date1(), 1010, 1010, 'USD', -255, true, true, 'test2');

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1036, -1000, date1(), 1010, true, -231);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1036, -1001, date1(), -1000, true, -232);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1036, -1001, date1(), -10, true, -233);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1036, -1002, date1(), 505, true, -234);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1036, -1000, date1(), -505, true, -235);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1036, -1002, date2(), 505, true, -236);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1036, -1000, date2(), -505, true, -237);

insert into invoice(trans_id, id, parts_id, description, qty, sellprice)
     VALUES (-1036, -221, -255, 'test 1', -1, 1000);

INSERT INTO invoice_tax_form(invoice_id, reportable)
     VALUES (-221, true);

insert into invoice(trans_id, id, parts_id, description, qty, sellprice)
     VALUES (-1036, -222, -256, 'test 1', -1, 10);

-- 4) AP invoice: Reportable amount 1000, non-reportable amount $10, paid
-- $500 currnet year, $500 in future year -1037, to second vendor


INSERT INTO ar (id, transdate, amount, netamount, curr, entity_credit_account,
                approved, invoice, invnumber)
      values(-1037, date1(), 1010, 1010, 'USD', -256, true, true, 'test3');

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1037, -1000, date1(), 1010, true, -241);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1037, -1001, date1(), -1000, true, -242);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1037, -1001, date1(), -10, true, -243);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1037, -1002, date1(), 1010, true, -244);

INSERT INTO acc_trans(trans_id, chart_id, transdate, amount, approved, entry_id)
     VALUES (-1037, -1000, date1(), -1010, true, -245);

insert into invoice(trans_id, id, parts_id, description, qty, sellprice)
     VALUES (-1037, -231, -255, 'test 1', -1, 1000);

INSERT INTO invoice_tax_form(invoice_id, reportable)
     VALUES (-231, true);

insert into invoice(trans_id, id, parts_id, description, qty, sellprice)
     VALUES (-1037, -232, -256, 'test 1', -1, 10);


-- Tests

INSERT INTO test_result(test_name, success)
SELECT '2 rows on current summary report', count(*) = 2
  FROM tax_form_summary_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date);

INSERT INTO test_result(test_name, success)
SELECT '2 rows on current accrual summary report', count(*) = 2
  FROM tax_form_summary_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date);

INSERT INTO test_result(test_name, success)
SELECT '1 row on future summary report', count(*) = 1
  FROM tax_form_summary_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date);

INSERT INTO test_result(test_name, success)
SELECT '0 rows on future summary accrual report', count(*) = 0
  FROM tax_form_summary_report_accrual(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date);



INSERT INTO test_result(test_name, success)
SELECT 'inv_sum for test vendor 1, current report is $1000', invoice_sum = 1000
  FROM tax_form_summary_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'inv_sum for test vendor 1, current accrual report is $2000', invoice_sum = 2000
  FROM tax_form_summary_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'inv_sum for test vendor 1, future report is $500', invoice_sum = 500
  FROM tax_form_summary_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'inv_sum for test vendor 2, current report is $1000', invoice_sum = 1000
  FROM tax_form_summary_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 2';

INSERT INTO test_result(test_name, success)
SELECT 'inv_sum for test vendor 2, current accrual report is $1000', invoice_sum = 1000
  FROM tax_form_summary_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 2';


INSERT INTO test_result(test_name, success)
SELECT 'total_sum for test vendor 1, current report is $3000', total_sum = 3000
  FROM tax_form_summary_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'total_sum for test vendor 1, current accrual report is $5000', total_sum = 5000
  FROM tax_form_summary_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'total_sum for test vendor 1, future report is $1000', total_sum = 1000
  FROM tax_form_summary_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'total_sum for test vendor 2, current report is $2000', total_sum = 2000
  FROM tax_form_summary_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 2';

INSERT INTO test_result(test_name, success)
SELECT 'total_sum for test vendor 2, current accrual report is $2000', total_sum = 2000
  FROM tax_form_summary_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 2';

INSERT INTO test_result(test_name, success)
SELECT 'ac_sum for test vendor 1, current report is $2000', acc_sum = 2000
  FROM tax_form_summary_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'ac_sum for test vendor 1, current accrual report is $3000', acc_sum = 3000
  FROM tax_form_summary_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'ac_sum for test vendor 1, future report is $500', acc_sum = 500
  FROM tax_form_summary_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date)
 where meta_number = 'Test account 1';

INSERT INTO test_result(test_name, success)
SELECT 'ac_sum for test vendor 2, current report is $1000', acc_sum = 1000
  FROM tax_form_summary_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 2';

INSERT INTO test_result(test_name, success)
SELECT 'ac_sum for test vendor 2, current accrual report is $1000', acc_sum = 1000
  FROM tax_form_summary_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date)
 where meta_number = 'Test account 2';

INSERT INTO test_result(test_name, success)
    SELECT '6 in detail report for current report, vendor 1', count(*) = 5
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1');

INSERT INTO test_result(test_name, success)
    SELECT '6 in detail report for current accrual report, vendor 1', count(*) = 5
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1');

INSERT INTO test_result(test_name, success)
    SELECT '2 in detail report for current report, vendor 2', count(*) = 2
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2');
INSERT INTO test_result(test_name, success)
    SELECT '2 in detail report for current accrual report, vendor 2', count(*) = 2
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2');


INSERT INTO test_result(test_name, success)
    SELECT '2 in detail report for future report, vendor 1', count(*) = 2
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 1');

INSERT INTO test_result(test_name, success)
    SELECT '0 in detail report for future report, vendor 2', count(*) = 0
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 2');

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1024, acc $1000', acc_sum= 1000
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1024;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1024, acc $1000', acc_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1024;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1025, acc $500', acc_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1025;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1025, acc $1000', acc_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1025;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1026, acc $500', acc_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1026, acc $1000', acc_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1027, acc $1000', acc_sum= 1000
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1027;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1027, acc $1000', acc_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1027;


INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1024, total $1000', total_sum= 1000
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1024;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1024, total $1000', total_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1024;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1025, total $500', total_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1025;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1025, total $1000', total_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1025;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1026, total $500', total_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1026, total $1000', total_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1027, total $1000', total_sum= 1000
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1027;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1027, total $1000', total_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1027;



INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1024, inv_total 0', invoice_sum= 0
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1024;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1024, inv_total 0', invoice_sum= 0
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1024;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1025, inv 0', invoice_sum= 0
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1025;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1025, inv 0', invoice_sum= 0
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1025;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1026, inv 0', invoice_sum = 0
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1026, inv 0', invoice_sum = 0
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1027, inv 0', invoice_sum= 0
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1027;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1027, inv 0', invoice_sum= 0
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1027;



INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1035, inv $500', invoice_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1035;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1035, inv $1000', invoice_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1035;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1036, inv $500', invoice_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1036, inv $1000', invoice_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1037, inv $1000', invoice_sum= 1000
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1037;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1037, inv $1000', invoice_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1037;



INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1035, total $500', total_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1035;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1036, total $500', total_sum= 500
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1037, total $1000', total_sum= 1000
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1037;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1035, total $1000', total_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1035;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1036, total $1000', total_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1037, total $1000', total_sum= 1000
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1037;




INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1035, acc 0', acc_sum = 0
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1035;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1036, acc 0',  acc_sum = 0
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

INSERT INTO test_result(test_name, success)
   SELECT 'current report, invoice -1037, acc 0', acc_sum = 0
    FROM tax_form_details_report(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1037;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1035, acc 0', acc_sum = 0
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1035;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1036, acc 0',  acc_sum = 0
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

INSERT INTO test_result(test_name, success)
   SELECT 'current accrual report, invoice -1037, acc 0', acc_sum = 0
    FROM tax_form_details_report_accrual(-511, (date1() - '1 day'::interval)::date,
                                  (date1() + '1 day'::interval)::date,
                                'Test account 2')
    WHERE invoice_id = -1037;



INSERT INTO test_result(test_name, success)
   SELECT 'future report, invoice -1026, acc 500',  acc_sum = 500
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'future report, invoice -1026, inv 0',  invoice_sum = 0
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;


INSERT INTO test_result(test_name, success)
   SELECT 'future report, invoice -1026, total 500',  total_sum = 500
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1026;

INSERT INTO test_result(test_name, success)
   SELECT 'future report, invoice -1036, acc 0',  acc_sum = 0
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

INSERT INTO test_result(test_name, success)
   SELECT 'future report, invoice -1036, inv 500',  invoice_sum = 500
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;


INSERT INTO test_result(test_name, success)
   SELECT 'future report, invoice -1036, total 500',  total_sum = 500
    FROM tax_form_details_report(-511, (date2() - '1 day'::interval)::date,
                                  (date2() + '1 day'::interval)::date,
                                'Test account 1')
    WHERE invoice_id = -1036;

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
