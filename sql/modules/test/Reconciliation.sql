BEGIN;
\i Base.sql
\i data/Reconciliation.sql


INSERT INTO test_result(test_name, success)
SELECT 'check_prefix set', count(*) = 1
FROM defaults where setting_key = 'check_prefix';

update defaults set value = 'Recon gl test ' where setting_key = 'check_prefix';

INSERT INTO test_result(test_name, success)
SELECT 'Create Recon Report',
	reconciliation__new_report_id(test_get_account_id('-11111'), 100, now()::date, false) > 0;

INSERT INTO test_result(test_name, success)
SELECT 'Pending Transactions Ran', reconciliation__pending_transactions(currval('cr_report_id_seq')::int, 110) > 0;

INSERT INTO test_result(test_name, success)
select 'Correct number of transactions 1', count(*) = 10
from cr_report_line where report_id = currval('cr_report_id_seq')::int;

INSERT INTO test_result(test_name, success)
SELECT 'Correct number of GL groups', count(*) = 3 from cr_report_line where scn like '% gl %' and report_id = currval('cr_report_id_seq')::int;

INSERT INTO test_result(test_name, success)
SELECT 'Correct number of report lines', count(*) = 10 from cr_report_line where report_id = currval('cr_report_id_seq')::int;


INSERT INTO test_result(test_name, success)
SELECT 'Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, (select as_array(id::int) from cr_report_line where report_id = currval('cr_report_id_seq')::int));

INSERT INTO test_result(test_name, success)
SELECT 'Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, (select as_array(id::int) from cr_report_line where report_id = currval('cr_report_id_seq')::int));

INSERT INTO test_result(test_name, success)
SELECT '1 Report Approved', reconciliation__report_approve(currval('cr_report_id_seq')::int) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Transactions closed', count(*) = 2 FROM acc_trans
JOIN account a ON (acc_trans.chart_id = a.id)
WHERE a.accno = '-11111' and cleared is false;

INSERT INTO test_result(test_name, success)
SELECT '1 Create Recon Report',
	reconciliation__new_report_id(test_get_account_id('-11112'), 100, now()::date, false) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Pending Transactions Ran', reconciliation__pending_transactions(currval('cr_report_id_seq')::int, 110) > 0;

INSERT INTO test_result(test_name, success)
select 'Correct number of transactions 2', count(*) = 10
from cr_report_line where report_id = currval('cr_report_id_seq')::int;

INSERT INTO test_result(test_name, success)
SELECT '1 Pending Transactions Ran', reconciliation__pending_transactions(currval('cr_report_id_seq')::int, 110) > 0;

INSERT INTO test_result(test_name, success)
select 'Correct number of transactions 3', count(*) = 10
from cr_report_line where report_id = currval('cr_report_id_seq')::int;

INSERT INTO test_result(test_name, success)
SELECT '1 Correct number of GL groups', count(*) = 3 from cr_report_line where scn like '% gl %' and report_id = currval('cr_report_id_seq')::int;


INSERT INTO test_result(test_name, success)
SELECT '1 Correct number of report lines', count(*) = 10 from cr_report_line where report_id = currval('cr_report_id_seq')::int;


INSERT INTO test_result(test_name, success)
SELECT '1 Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, '{}');


INSERT INTO test_result(test_name, success)
SELECT '1 Cleared balance pre-approval is 10', reconciliation__get_cleared_balance(test_get_account_id('-11112')) = -10;

INSERT INTO test_result(test_name, success)
SELECT '1 Report Approved', reconciliation__report_approve(currval('cr_report_id_seq')::int) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Transactions open', count(*) = 14 FROM acc_trans
JOIN account ON (acc_trans.chart_id = account.id)
WHERE accno = '-11112'  and cleared is false;

INSERT INTO test_result(test_name, success)
SELECT '1 Cleared balance post-approval is 10', reconciliation__get_cleared_balance(test_get_account_id('-11112')) = -10;

INSERT INTO test_result(test_name, success)
SELECT '1 Create Recon Report',
	reconciliation__new_report_id(test_get_account_id('-11112'), 100, now()::date, false) > 0;

INSERT INTO test_result(test_name, success)
SELECT '1 Pending Transactions Ran', reconciliation__pending_transactions(currval('cr_report_id_seq')::int, 110) > 0;

INSERT INTO test_result(test_name, success)
select 'Correct number of transactions 4', count(*) = 10
from cr_report_line where report_id = currval('cr_report_id_seq')::int;


INSERT INTO test_result(test_name, success)
SELECT 'Report Submitted', reconciliation__submit_set(currval('cr_report_id_seq')::int, (select as_array(id::int) from cr_report_line where report_id = currval('cr_report_id_seq')::int));

INSERT INTO test_result(test_name, success)
SELECT 'Their Balance Updated', their_total = 110
FROM reconciliation__report_summary(currval('cr_report_id_seq')::int);

INSERT INTO test_result(test_name, success)
SELECT 'Cleared balance pre-approval is 10', reconciliation__get_cleared_balance(test_get_account_id('-11112')) = -10;


INSERT INTO test_result(test_name, success)
SELECT 'Report Approved', reconciliation__report_approve(currval('cr_report_id_seq')::int) > 0;

INSERT INTO test_result(test_name, success)
SELECT 'Transactions closed', count(*) = 2 FROM acc_trans
JOIN account a ON (acc_trans.chart_id = a.id)
WHERE accno = '-11112' and cleared is false;

INSERT INTO test_result(test_name, success)
SELECT 'Cleared balance post-approval is 130', reconciliation__get_cleared_balance(test_get_account_id('-11112')) = -130;


SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
