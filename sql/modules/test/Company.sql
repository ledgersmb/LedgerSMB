BEGIN;
\i Base.sql

INSERT INTO test_result (test_name, success)
SELECT 'Saving Company', 
	company_save (NULL, 'TESTING...', 1,'TESTING', 'TESTING', NULL, '1234') 
		IS NOT NULL;


INSERT INTO test_result (test_name, success)
SELECT 'Saving Credit Acct', 
	entity_credit_save(  NULL , 1, currval('entity_id_seq')::int, 'TEST', 0, false,
		0, 0, 0, 'test-123', NULL, NULL, NULL, 'USD', now()::date, now()::date,
		0, NULL, NULL)
	IS NOT NULL;

INSERT INTO test_result (test_name, success)
SELECT 'eca_location_save', 
	eca__location_save(currval('entity_credit_account_id_seq')::int, NULL, 2, 'Test', 'Test', 
		NULL, 'Test', 'Test', '12345', 25)
	IS NOT NULL;

INSERT INTO test_result (test_name, success)
SELECT 'list_locations', count(*) > 0 
	FROM eca__list_locations(currval('entity_credit_account_id_seq')::int);


SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

ROLLBACK;
