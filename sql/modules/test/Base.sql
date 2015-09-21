CREATE TEMPORARY TABLE test_result (
	test_name text,
	success bool
);

INSERT INTO entity (id, name, entity_class, control_code, country_id)
VALUES (-100, 'Testing.....', 3, '_TESTING.....', 242);

INSERT INTO entity (id, name, entity_class, control_code, country_id)
VALUES (-101, 'Testing..... 2', 3, '_TEST2', 242);

INSERT INTO person(id, entity_id, first_name, last_name)
values (-100, -100, 'Test', 'User');

DELETE FROM users WHERE username = CURRENT_USER;

INSERT INTO users (entity_id, username)
SELECT -100, CURRENT_USER;

INSERT INTO entity_employee(entity_id) values (-100);

INSERT INTO entity(name, id, entity_class, control_code, country_id)
values ('test user 1', -200, 3, 'Test User 1', 242);

select account_heading_save(NULL, '000000000000000000000', 'TEST', NULL);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1000, '-1000000000', 'Test cases only', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1001, '-1000000001', 'Test cases only', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1002, '-1000000002', 'Test cases only', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

CREATE OR REPLACE FUNCTION test_get_account_id(in_accno text) returns int as
$$
SELECT id FROM chart WHERE accno = $1;
$$ language sql;
