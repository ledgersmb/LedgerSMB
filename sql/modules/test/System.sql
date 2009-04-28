BEGIN;
\i Base.sql

CREATE TABLE test_exempt_funcs (funcname text primary key);

insert into test_exempt_funcs values ('headline');
insert into test_exempt_funcs values ('rank');
insert into test_exempt_funcs values ('to_tsquery');
insert into test_exempt_funcs values ('to_tsvector');
insert into test_exempt_funcs values ('stat');
insert into test_exempt_funcs values ('lexize');
insert into test_exempt_funcs values ('connectby');
insert into test_exempt_funcs values ('parse');
insert into test_exempt_funcs values ('set_curprs');
insert into test_exempt_funcs values ('rank_cd');
insert into test_exempt_funcs values ('set_curdict');
insert into test_exempt_funcs values ('set_curcfg');
insert into test_exempt_funcs values ('token_type');
insert into test_exempt_funcs values ('crosstab');

INSERT INTO test_result(test_name, success)
select 'No overloaded functions in current schema', count(*) = 0
FROM (select proname FROM pg_proc 
	WHERE pronamespace = 
		(select oid from pg_namespace 
		where nspname = current_schema())
		AND proname NOT IN (select funcname FROM test_exempt_funcs)
	group by proname
	having count(*) > 1
) t;

select proname FROM pg_proc WHERE pronamespace =
	(select oid from pg_namespace 
	where nspname = current_schema())
	AND proname NOT IN (select funcname from test_exempt_funcs)
group by proname
having count(*) > 1;

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;

