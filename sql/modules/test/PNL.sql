/* Designing tests here based on data in taxform.sql.  We may want to split
   this out into another data script. --CT
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

UPDATE account SET category = 'L' WHERE id = -1000;

INSERT INTO account_link (account_id, description)
values (-1001, 'AP_amount');

UPDATE account SET category = 'E' WHERE id = -1001;

INSERT INTO account_link (account_id, description)
values (-1002, 'AP_paid');

UPDATE account SET category = 'A' WHERE id = -1002;

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

INSERT INTO test_result(test_name, success)
SELECT '-1024, cash impact 1 across all dates', sum(portion) = 1
  FROM cash_impact
 WHERE id = -1024;

INSERT INTO test_result(test_name, success)
SELECT '-1024, one cash impact row', count(*) = 1
  FROM cash_impact
 WHERE id = -1024;

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

INSERT INTO test_result(test_name, success)
SELECT '-1025, cash impact 0.5 across all dates', sum(portion) = 0.5
  FROM cash_impact
 WHERE id = -1025;

INSERT INTO test_result(test_name, success)
SELECT '-1025, one cash impact row', count(*) = 1
  FROM cash_impact
 WHERE id = -1025;

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

INSERT INTO test_result(test_name, success)
SELECT '-1026, cash impact 1 across all dates', sum(portion) = 1
  FROM cash_impact
 WHERE id = -1026;

INSERT INTO test_result(test_name, success)
SELECT '-1026, two cash impact rows', count(*) = 2
  FROM cash_impact
 WHERE id = -1026;

INSERT INTO test_result(test_name, success)
SELECT '-1026, cash impact 0.5 on date 1', portion=0.5
  FROM cash_impact
 WHERE id = -1026 and transdate = date1();

INSERT INTO test_result(test_name, success)
SELECT '-1026, cash impact 0.5 on date 2', portion=0.5
  FROM cash_impact
 WHERE id = -1026 and transdate = date2();

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

INSERT INTO test_result(test_name, success)
SELECT '-1027, cash impact 1 across all dates', sum(portion) = 1
  FROM cash_impact
 WHERE id = -1027;

INSERT INTO test_result(test_name, success)
SELECT '-1027, one cash impact row', count(*) = 1
  FROM cash_impact
 WHERE id = -1027;

INSERT INTO test_result(test_name, success)
SELECT 'Account -1001 shows up in accrual income statement', count(*) = 1
  FROM pnl__income_statement_accrual(date1(), date2() - 1, 'none', ARRAY[]::int[], null)
 WHERE account_id = -1001;

INSERT INTO test_result(test_name, success)
SELECT 'Account -1001 accrual total -4040', amount = -4040
  FROM pnl__income_statement_accrual(date1(), date2() - 1, 'none', ARRAY[]::int[], null)
 WHERE account_id = -1001;

INSERT INTO test_result(test_name, success)
SELECT 'Account -1001 does not show up in future accrual pnl', count(*) = 0
  FROM pnl__income_statement_accrual(date2(), date2() + 365, 'none', ARRAY[]::int[], null)
 WHERE account_id = -1001;

INSERT INTO test_result(test_name, success)
SELECT 'Account -1001 shows up in cash income statement', count(*) = 1
  FROM pnl__income_statement_cash(date1(), date2() - 1, 'none', ARRAY[]::int[], null)
 WHERE account_id = -1001;

INSERT INTO test_result(test_name, success)
SELECT 'Account -1001 cash total -3030', amount = -3030
  FROM pnl__income_statement_cash(date1(), date2() - 1, 'none', ARRAY[]::int[], null)
 WHERE account_id = -1001;

SELECT * FROM pnl__income_statement_cash(date1(), date2() - 1, 'none', ARRAY[]::int[], null);

INSERT INTO test_result(test_name, success)
SELECT 'Account -1001 shows up in future cash pnl', count(*) = 1
  FROM pnl__income_statement_cash(date2() - 5, date2() + 20, 'none', ARRAY[]::int[], null)
 WHERE account_id = -1001;

INSERT INTO test_result(test_name, success)
SELECT 'Account -1001 future cash total -505', sum(amount) = -505
  FROM pnl__income_statement_cash(date2() - 5, date2() + 20, 'none', ARRAY[]::int[], null)
 WHERE account_id = -1001;

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
