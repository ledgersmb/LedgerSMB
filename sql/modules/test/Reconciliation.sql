BEGIN;
\i Base.sql
\i data/Reconciliation.sql

INSERT INTO entity (id, control_code, name, entity_class) values (-50, 'Test User', 'Test User', 3);
INSERT INTO person (id, entity_id, first_name, last_name) values (-50, -50, 'Test', 'Usr');

INSERT INTO users (id, entity_id, username) values (-50, -50, SESSION_USER);

INSERT INTO test_result(test_name, success)
SELECT 'Create Recon Report', 
	reconciliation__new_report_id(-200, 100, now()::date) > 0;

INSERT INTO test_result(test_name, success)
SELECT 'Pending Transactions Ran', reconciliation__pending_transactions(now()::date, -200, currval('cr_report_id_seq')::int, 110) > 0;

INSERT INTO test_result(test_name, success)
SELECT 'Correct number of GL groups', count(*) = 4 from cr_report_line where scn like '% gl %' and report_id = currval('cr_report_id_seq')::int;

INSERT INTO test_result(test_name, success)
SELECT 'Correct number of report lines', count(*) = 10 from cr_report_line where report_id = currval('cr_report_id_seq')::int;


INSERT INTO test_result(test_name, success)
SELECT 'Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, (select as_array(id::int) from cr_report_line where report_id = currval('cr_report_id_seq')::int));

INSERT INTO test_result(test_name, success)
SELECT 'Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, (select as_array(id::int) from cr_report_line where report_id = currval('cr_report_id_seq')::int));

INSERT INTO test_result(test_name, success)
SELECT '1 Report Approved', reconciliation__report_approve(currval('cr_report_id_seq')::int) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Transactions closed', count(*) = 2 FROM acc_trans where chart_id = -200 and cleared is false;

INSERT INTO test_result(test_name, success)
SELECT '1 Create Recon Report', 
	reconciliation__new_report_id(-201, 100, now()::date) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Pending Transactions Ran', reconciliation__pending_transactions(now()::date, -201, currval('cr_report_id_seq')::int, 110) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Correct number of GL groups', count(*) = 4 from cr_report_line where scn like '% gl %' and report_id = currval('cr_report_id_seq')::int;

INSERT INTO test_result(test_name, success)
SELECT '1 Correct number of report lines', count(*) = 10 from cr_report_line where report_id = currval('cr_report_id_seq')::int;


INSERT INTO test_result(test_name, success)
SELECT '1 Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, '{}');


INSERT INTO test_result(test_name, success)
SELECT '1 Cleared balance pre-approval is 10', reconciliation__get_cleared_balance(-201) = 10;

INSERT INTO test_result(test_name, success)
SELECT '1 Report Approved', reconciliation__report_approve(currval('cr_report_id_seq')::int) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Transactions open', count(*) = 14 FROM acc_trans where chart_id = -201 and cleared is false;

INSERT INTO test_result(test_name, success)
SELECT '1 Cleared balance post-approval is 10', reconciliation__get_cleared_balance(-201) = 10;


INSERT INTO test_result(test_name, success)
SELECT '1 Create Recon Report', 
	reconciliation__new_report_id(-201, 100, now()::date) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Pending Transactions Ran', reconciliation__pending_transactions(now()::date, -201, currval('cr_report_id_seq')::int, 110) > 0;


INSERT INTO test_result(test_name, success)
SELECT 'Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, (select as_array(id::int) from cr_report_line where report_id = currval('cr_report_id_seq')::int));

INSERT INTO test_result(test_name, success)
SELECT 'Their Balance Updated', their_total = 110 
FROM reconciliation__report_summary(currval('cr_report_id_seq')::int);

INSERT INTO test_result(test_name, success)
SELECT 'Cleared balance pre-approval is 10', reconciliation__get_cleared_balance(-201) = 10;

INSERT INTO test_result(test_name, success)
SELECT 'Report Approved', reconciliation__report_approve(currval('cr_report_id_seq')::int) > 0;

INSERT INTO test_result(test_name, success)
SELECT 'Transactions closed', count(*) = 2 FROM acc_trans where chart_id = -200 and cleared is false;

INSERT INTO test_result(test_name, success)
SELECT 'Cleared balance post-approval is 130', reconciliation__get_cleared_balance(-201) = 130;


SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;


ROLLBACK;
