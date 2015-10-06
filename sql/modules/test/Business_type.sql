BEGIN;
\i Base.sql

INSERT INTO business (description) values ('testing');

INSERT INTO test_result (test_name, success)
SELECT 'Business Class Inserted', count(*) > 0 from business_type__list()
WHERE description = 'testing';

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
