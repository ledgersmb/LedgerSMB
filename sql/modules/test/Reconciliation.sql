BEGIN;
\i Base.sql

INSERT INTO chart (id, accno, description, charttype, category)
values (-100, -100, 'Test acct', 'A', 'A');

INSERT INTO test_result(test_name, success)
SELECT 'Create Recon Report', 
	reconciliation__new_report_id(-100, 100, now()::date) > 0;

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;


ROLLBACK;
