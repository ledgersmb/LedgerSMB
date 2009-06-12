CREATE TEMPORARY TABLE test_result (
	test_name text,
	success bool
);

select account_heading_save(NULL, '000000000000000000000', 'TEST', NULL);

CREATE OR REPLACE FUNCTION test_get_account_id(in_accno text) returns int as
$$ 
SELECT id FROM chart WHERE accno = $1; 
$$ language sql;
