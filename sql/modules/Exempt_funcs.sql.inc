CREATE TABLE pg_temp.test_exempt_funcs (funcname text primary key);

insert into pg_temp.test_exempt_funcs values ('rewrite');
insert into pg_temp.test_exempt_funcs values ('in_tree');
insert into pg_temp.test_exempt_funcs values ('gin_extract_trgm');
insert into pg_temp.test_exempt_funcs values ('plainto_tsquery');
insert into pg_temp.test_exempt_funcs values ('headline');
insert into pg_temp.test_exempt_funcs values ('rank');
insert into pg_temp.test_exempt_funcs values ('to_tsquery');
insert into pg_temp.test_exempt_funcs values ('to_tsvector');
insert into pg_temp.test_exempt_funcs values ('stat');
insert into pg_temp.test_exempt_funcs values ('product');
insert into pg_temp.test_exempt_funcs values ('lexize');
insert into pg_temp.test_exempt_funcs values ('connectby');
insert into pg_temp.test_exempt_funcs values ('parse');
insert into pg_temp.test_exempt_funcs values ('set_curprs');
insert into pg_temp.test_exempt_funcs values ('rank_cd');
insert into pg_temp.test_exempt_funcs values ('set_curdict');
insert into pg_temp.test_exempt_funcs values ('set_curcfg');
insert into pg_temp.test_exempt_funcs values ('token_type');
insert into pg_temp.test_exempt_funcs values ('crosstab');
insert into pg_temp.test_exempt_funcs values ('concat_colon');
insert into pg_temp.test_exempt_funcs values ('to_args');
insert into pg_temp.test_exempt_funcs values ('table_log_restore_table');
insert into pg_temp.test_exempt_funcs values ('lsmb__grant_perms');
-- there's an array and a non-array form of the above function
