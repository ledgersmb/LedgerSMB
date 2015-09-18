BEGIN;
\i Base.sql
\i data/Reconciliation.sql

INSERT INTO test_result (test_name, success)
values ('timeout set',
(select count(*) from defaults where setting_key = 'timeout') = 1);

INSERT INTO session (users_id, last_used, token)
SELECT 	currval('users_id_seq'),
now() - coalesce((select value from defaults where setting_key = 'timeout')::interval,
         '90 minutes'::interval) - '1 minute'::interval,
md5('test2');


INSERT INTO session (users_id, last_used, token)
SELECT currval('users_id_seq'),
now() - coalesce((select value from defaults where setting_key = 'timeout')::interval,
         '2 days'::interval),
md5('test3');

INSERT INTO session (users_id, last_used, token)
SELECT currval('users_id_seq'), now(), md5('test1');

INSERT INTO test_result (test_name, success)
SELECT 'records exist in transactions table', count(*) > 0 FROM transactions;

INSERT INTO test_result (test_name, success)
SELECT 'unlock record fails when record is not locked', unlock(max(id)) IS FALSE
FROM transactions;

INSERT INTO test_result (test_name, success)
SELECT 'lock record', lock_record(max(id), currval('session_session_id_seq')::int)

FROM transactions WHERE locked_by IS NULL;

INSERT INTO test_result (test_name, success)
SELECT 'unlock record', unlock(max(id))
FROM transactions WHERE locked_by = currval('session_session_id_seq')::int;

INSERT INTO test_result (test_name, success)
SELECT 'lock all record', bool_and(lock_record(id, currval('session_session_id_seq')::int))
FROM transactions WHERE locked_by IS NULL;

INSERT INTO test_result (test_name, success)
SELECT 'unlock all records', unlock_all();

INSERT INTO test_result (test_name, success)
values ('session1 retrieved',
(select t.token = md5('test1')
FROM session_check(
	currval('session_session_id_seq')::int,
	md5('test1')
) t )
);

INSERT INTO test_result (test_name, success)
select 'Form_open on correct syntax', form_open(currval('session_session_id_seq')::int) > 0;

INSERT INTO test_result (test_name, success)
select 'Form_close fails on bad values', form_close(currval('session_session_id_seq')::int + 1, currval('open_forms_id_seq')::int) is false;

INSERT INTO test_result (test_name, success)
select 'Form_close fails on bad values', form_close(currval('session_session_id_seq')::int, currval('open_forms_id_seq')::int);

INSERT INTO test_result (test_name, success)
VALUES ('session 2 removed',
(select count(*) from session where token = md5('test2') AND users_id = currval('users_id_seq')) = 0);

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
