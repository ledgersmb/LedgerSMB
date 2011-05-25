/* 

This tests the new taxform functions in 1099_reports.sql

Per discussion with Chris, test cases function in the form of:

AP, acc_trans, invoice (on some items), ac_taxform (some items), invoice_taxform (some items)

Invoice tests:
* Create a new account, for testing
* Insert a record into transactions
* Insert a record into AP
* Insert a record into transactions
* Insert a record into acc_trans
* Associate acc_trans with 2nd transaction


*/ 

BEGIN;

\i Base.sql

/* First, we do the invoice testing */

INSERT INTO account_heading(id, accno ) VALUES (-255, '-billion');
INSERT INTO account (id, accno, category, heading ) VALUES (-255, '-billion', 'T', -255);
INSERT INTO account (id, accno, category, heading ) VALUES (-256, '-billiontest', 'T', -255);

-- New account is created.


-- Set up a tax form.

INSERT INTO country_tax_form (country_id, form_name, id) VALUES (232, 'Testing Form', -511);

-- Set up an ECA, for AP.


INSERT INTO entity_credit_account (id, entity_id, entity_class, meta_number, taxform_id, ar_ap_account_id) VALUES (-255, -100, 1, 'Test account', -511, -255);

INSERT INTO company (id, entity_id, legal_name) VALUES (-1024, -100, 'Testing Tax Form');

-- Set up the Transaction
--INSERT INTO transactions (id) VALUES (-255);

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-255, 5000, 't'::bool, -255, 'USD');

INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-255, -255, 5000, 't'::bool, -1000);

-- Set up the second transaction

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-256, -1000, 't'::bool, -255, 'USD');
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-256, -255, -1000, 't'::bool, -1001);

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-257, -1500, 't'::bool, -255, 'USD');
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-257, -255, -1500, 't'::bool, -1002);

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-258, -2500, 't'::bool, -255, 'USD');
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-258, -255, -2500, 't'::bool, -1003);

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-259, 5000, 't'::bool, -255, 'USD');

INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-259, -255, 5000, 't'::bool, -1004);

-- Set up the paid transactions

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-260, -1000, 't'::bool, -255, 'USD');
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-260, -255, -1000, 't'::bool, -1005);
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-260, -256, 1000, 't'::bool, -1006);

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-261, -1500, 't'::bool, -255, 'USD');
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-261, -255, -1500, 't'::bool, -1007);
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-261, -256, 1500, 't'::bool, -1008);

INSERT INTO ap (id, amount, approved, entity_credit_account, curr) VALUES (-262, -2500, 't'::bool, -255, 'USD');

INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-262, -255, -2500, 't'::bool, -1009);
INSERT INTO acc_trans (trans_id, chart_id, amount, approved, entry_id) VALUES (-262, -256, 2500, 't'::bool, -1010);

-- Now we set up the invoice entries themselves.


INSERT INTO invoice (id, trans_id, sellprice, qty) VALUES (-1000, -256, 250, 4);
INSERT INTO invoice (id, trans_id, sellprice, qty) VALUES (-1001, -257, 750, 2);
INSERT INTO invoice (id, trans_id, sellprice, qty) VALUES (-1002, -258, 500, 5);
INSERT INTO invoice (id, trans_id, sellprice, qty) VALUES (-1003, -260, 250, 4);
INSERT INTO invoice (id, trans_id, sellprice, qty) VALUES (-1004, -261, 750, 2);
INSERT INTO invoice (id, trans_id, sellprice, qty) VALUES (-1005, -262, 500, 5);


-- And finally, the tax_form references

INSERT INTO invoice_tax_form (invoice_id, reportable) VALUES (-1000, TRUE);
INSERT INTO invoice_tax_form (invoice_id, reportable) VALUES (-1001, TRUE);
INSERT INTO invoice_tax_form (invoice_id, reportable) VALUES (-1002, TRUE);
INSERT INTO invoice_tax_form (invoice_id, reportable) VALUES (-1003, TRUE);
INSERT INTO invoice_tax_form (invoice_id, reportable) VALUES (-1004, TRUE);
INSERT INTO invoice_tax_form (invoice_id, reportable) VALUES (-1005, TRUE);


--
-- Finally, we test if the entries are showing up 
--


-- There should be three entries.

INSERT INTO test_result(test_name, success)
VALUES ('3 Reportable Invoices, sum of 5000', (
    SELECT
        CASE WHEN invoice_sum <> 5000 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_summary_report(-511, (now()::date- '1 day'::interval)::date, now()::date)
));

--select * from tax_form_details_report(-511, (now() - '1 day'::interval)::date, now()::date, 'Test account');

-- Test reportable-only

UPDATE invoice_tax_form SET reportable = FALSE where invoice_id = -1001;


INSERT INTO test_result(test_name, success)
VALUES ('2 Reportable invoices, 1 disabled, sum of 1000', (
    SELECT
        CASE WHEN total_sum <> 3500 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_summary_report(-511, (now()::date- '1 day'::interval)::date, now()::date)
));

-- Clean up all the invoices and test the AP form instead.

DELETE FROM invoice_tax_form WHERE invoice_id < 0 AND reportable is TRUE;
DELETE FROM invoice WHERE id < 0 AND id NOT IN (select invoice_id from invoice_tax_form);


-- AC tax form stuff


INSERT INTO ac_tax_form (entry_id, reportable) VALUES (-1001, 't'::bool);
INSERT INTO ac_tax_form (entry_id, reportable) VALUES (-1002, 't'::bool);
INSERT INTO ac_tax_form (entry_id, reportable) VALUES (-1003, 't'::bool);

--select * from tax_form_details_report(-511, (now() - '1 day'::interval)::date, now()::date, 'Test account');

-- And now, test the AC tax form

INSERT INTO test_result(test_name, success)
VALUES ('3 Reportable AC tax forms', (
    SELECT
        CASE WHEN total_sum <> -5000 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_summary_report(-511, (now()::date- '1 day'::interval)::date, now()::date)
));

UPDATE ac_tax_form SET reportable = FALSE where entry_id = -1002;


INSERT INTO test_result(test_name, success)
VALUES ('Detail test, 2 records', (
    SELECT
        CASE WHEN count(*) <> 2 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_details_report(-511, (now() - '1 day'::interval)::date, now()::date, 'Test account')
));

INSERT INTO test_result(test_name, success)
VALUES ('Detail test, 2 records sum of acc_sum is -3500 ', (
    SELECT
        CASE WHEN sum(acc_sum) <> -3500 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_details_report(-511, (now() - '1 day'::interval)::date, now()::date, 'Test account')
));



INSERT INTO test_result(test_name, success)
VALUES ('2 Reportable invoices, 1 disabled', (
    SELECT
        CASE WHEN total_sum <> -3500 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_summary_report(-511, (now()::date- '1 day'::interval)::date, now()::date)
));

UPDATE invoice_tax_form SET reportable = TRUE;


INSERT INTO test_result(test_name, success)
VALUES ('2 Reportable invoices, 1 disabled, 1 invoice', (
    SELECT
        CASE WHEN total_sum <> -2000 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_summary_report(-511, (now()::date- '1 day'::interval)::date, now()::date)
));

INSERT INTO test_result(test_name, success)
VALUES ('2 Reportable invoices, 1 disabled, 1 invoice, acc_sum is -3500', (
    SELECT
        CASE WHEN acc_sum <> -3500 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_summary_report(-511, (now()::date- '1 day'::interval)::date, now()::date)
));

INSERT INTO test_result(test_name, success)
VALUES ('2 Reportable invoices, 1 disabled, 1 invoice, invoice_total is 1500', (
    SELECT
        CASE WHEN invoice_sum <> 1500 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_summary_report(-511, (now()::date- '1 day'::interval)::date, now()::date)
));


-- Now, do the detail testing.
-- At this point, there ought to be 3 records.


INSERT INTO test_result(test_name, success)
VALUES ('Detail test, 3 records', (
    SELECT
        CASE WHEN count(*) <> 3 THEN
            FALSE
        ELSE
            TRUE
        END as success
    FROM tax_form_details_report(-511, (now() - '1 day'::interval)::date, now()::date, 'Test account')
));



SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

ROLLBACK;
