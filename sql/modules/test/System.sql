BEGIN;
\i Base.sql
-- Include the exempted functions in temporary table.
\i Exempt_funcs.sql

-- Set temporary table in pg_temp
create table pg_temp.test_exempt_tables (tablename text, reason text);
insert into pg_temp.test_exempt_tables values ('note', 'abstract table, no data');
insert into pg_temp.test_exempt_tables values ('open_forms', 'security definer only');
insert into pg_temp.test_exempt_tables values ('pg_ts_cfg', 'security definer only');
insert into pg_temp.test_exempt_tables values ('pg_ts_cfgmap', 'security definer only');
insert into pg_temp.test_exempt_tables values ('pg_ts_dict', 'security definer only');
insert into pg_temp.test_exempt_tables values ('pg_ts_parser', 'security definer only');
insert into pg_temp.test_exempt_tables values ('file_view_catalog', 'addon installaiton only');

insert into pg_temp.test_exempt_tables
values ('person_to_company', 'Unused in core, for addons only');
insert into pg_temp.test_exempt_tables
values ('person_to_entity', 'Unused in core, for addons only');

insert into pg_temp.test_exempt_tables values ('pg_temp.test_exempt_funcs', 'test data only');

insert into pg_temp.test_exempt_tables values  ('pg_temp.test_exempt_tables', 'test data only');
insert into pg_temp.test_exempt_tables values ('menu_friendly', 'dev info only');
insert into pg_temp.test_exempt_tables values ('note', 'abstract table, no data');
analyze pg_temp.test_exempt_tables;

INSERT INTO test_result(test_name, success)
select 'No overloaded functions in current schema', count(*) = 0
FROM (select proname FROM pg_proc
        WHERE pronamespace =
                (select oid from pg_namespace
                where nspname = current_schema())
                AND proname NOT IN (select funcname FROM pg_temp.test_exempt_funcs)
        group by proname
        having count(*) > 1
) t;

select proname FROM pg_proc WHERE pronamespace =
        (select oid from pg_namespace
        where nspname = current_schema())
        AND proname NOT IN (select funcname from pg_temp.test_exempt_funcs)
group by proname
having count(*) > 1;

SELECT * FROM test_result;

SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
