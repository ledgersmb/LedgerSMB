CREATE TEMPORARY TABLE test_result (
        test_name text,
        success bool
);

-- from https://en.wikipedia.org/wiki/ISO_4217
INSERT INTO currency (curr, description)
VALUES ('XTS', 'Code reserved for testing purposes');

INSERT INTO entity (id, name, control_code, country_id)
VALUES (-100, 'Testing.....', '_TESTING.....', 242);

INSERT INTO entity (id, name, control_code, country_id)
VALUES (-101, 'Testing..... 2', '_TEST2', 242);

INSERT INTO person(id, entity_id, first_name, last_name)
values (-100, -100, 'Test', 'User');

INSERT INTO company (id, entity_id, legal_name)
VALUES (-101, -101, 'Test Company');

INSERT INTO location(id, line_one, city, country_id)
VALUES (-101, '101 Main Street', 'Cityville', 242);

INSERT INTO entity_to_location (location_id, location_class, entity_id)
VALUES (-101, 1, -101);

DELETE FROM users WHERE username = CURRENT_USER;

INSERT INTO users (entity_id, username)
SELECT -100, CURRENT_USER;

INSERT INTO entity_employee(entity_id) values (-100);

INSERT INTO entity(name, id, control_code, country_id)
values ('test user 1', -200, 'Test User 1', 242);

select account_heading_save(NULL, '000000000000000000000', 'TEST', NULL);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1000, '-1000000000', 'Test cases only', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1001, '-1000000001', 'Test cases only', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1002, '-1000000002', 'Test cases only', 'A', (select id from account_heading WHERE accno  = '000000000000000000000'), false);

select account_heading_save(NULL, '00000000000000000000E', 'TEST', NULL);
select account_heading_save(NULL, '00000000000000000000I', 'TEST', NULL);
select account_heading_save(NULL, '00000000000000000000Q', 'TEST', NULL);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1003, '-1000000003', 'Test cases only (E)', 'E', (select id from account_heading WHERE accno  = '00000000000000000000E'), false);


INSERT INTO account(id, accno, description, category, heading, contra)
values (-1004, '-1000000004', 'Test cases only (I)', 'I', (select id from account_heading WHERE accno  = '00000000000000000000I'), false);

INSERT INTO account(id, accno, description, category, heading, contra)
values (-1005, '-1000000005', 'Test cases only (Q)', 'Q', (select id from account_heading WHERE accno  = '00000000000000000000Q'), false);

CREATE OR REPLACE FUNCTION test_get_account_id(in_accno text) returns int as
$$
SELECT id FROM account WHERE accno = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION test_insert_default_currency() returns boolean as
$$
BEGIN
   PERFORM * FROM defaults WHERE setting_key = 'curr';

   IF NOT FOUND THEN
      INSERT INTO defaults
      VALUES ('curr', 'XTS');
      RETURN 'f'::boolean;
   ELSE
      RETURN 't'::boolean;
   END IF;
END;
$$ language plpgsql;

select test_insert_default_currency();
