BEGIN;
\i Base.sql

INSERT INTO test_result (test_name, success)
values ('timeout set', 
(select count(*) from defaults where setting_key = 'timeout') = 1);

INSERT INTO entity (name, entity_class, control_code)
VALUES ('Testing.....', 3, '_TESTING.....');

INSERT INTO users (entity_id, username)
SELECT currval('entity_id_seq'), CURRENT_USER;

INSERT INTO session (users_id, last_used, token, transaction_id)
SELECT 	currval('users_id_seq'), 
now() - coalesce((select value from defaults where setting_key = 'timeout')::interval, 
         '90 minutes'::interval), 
md5('test2'), 2;


INSERT INTO session (users_id, last_used, token, transaction_id)
SELECT currval('users_id_seq'), 
now() - coalesce((select value from defaults where setting_key = 'timeout')::interval, 
         '2 days'::interval), 
md5('test3'), 3;

select * from session_check(currval('session_session_id_seq')::int, md5('test1'));

INSERT INTO session (users_id, last_used, token, transaction_id)
SELECT currval('users_id_seq'), now(), md5('test1'), 1;


INSERT INTO test_result (test_name, success)
values ('session1 retrieved', 
(select t.token = md5('test1') 
FROM session_check(
	currval('session_session_id_seq')::int, 
	md5('test1')
) t )
);

INSERT INTO test_result (test_name, success)
VALUES ('session 2 removed', 
(select count(*) from session where token = md5('test2') AND users_id = currval('users_id_seq')) = 0);

DELETE FROM session WHERE users_id = currval('users_id_seq');
DELETE FROM entity WHERE control_code = '_TESTING.....';

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true) 
|| ' tests passed and ' 
|| (select count(*) from test_result where success is not true) 
|| ' failed' as message;

DROP TABLE test_result;
ROLLBACK;
