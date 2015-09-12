BEGIN;
\i Base.sql

INSERT INTO test_result (test_name, success)
SELECT 'Saving Company',
	company__save (NULL, 'TESTING...', 1,'TESTING', 'TESTING', NULL, '1234', 232, 'st-123', 'ubi-123-456-789')
		IS NOT NULL;


INSERT INTO test_result (test_name, success)
SELECT 'Saving Credit Acct',
	eca__save(  NULL , 1, currval('entity_id_seq')::int, 'TEST', 0, false,
		0, 0, 0, 'test-123', NULL, NULL, NULL, 'USD', now()::date, now()::date,
		0, -1000, NULL, NULL, NULL, NULL)
	IS NOT NULL;

INSERT INTO test_result (test_name, success)
SELECT 'eca_location_save',
	eca__location_save(currval('entity_credit_account_id_seq')::int, NULL, 2, 'Test', 'Test',
		NULL, 'Test', 'Test', '12345', 25, NULL)
	IS NOT NULL;

INSERT INTO test_result (test_name, success)
SELECT 'eca_location_save returns same id with same args and no in_location_id',
	eca__location_save(currval('entity_credit_account_id_seq')::int, NULL, 1, 'Test2', 'Test',
                '', 'Test', 'Test123', '12345', 25, NULL) =
	eca__location_save(currval('entity_credit_account_id_seq')::int, NULL, 3, 'Test2', 'Test',
                '', 'Test', 'Test123', '12345', 25, NULL);

INSERT INTO test_result (test_name, success)
SELECT 'list_locations', count(*) = 3
	FROM eca__list_locations(currval('entity_credit_account_id_seq')::int);

INSERT INTO test_result(test_name, success)
SELECT 'saving eca contact',
	eca__save_contact(currval('entity_credit_account_id_seq')::int,
		1, 'test_d', 'test_c', NULL, NULL) IS NOT NULL;

INSERT INTO test_result(test_name, success)
SELECT 'Contact found correctly', count(*) = 1
FROM eca__list_contacts(currval('entity_credit_account_id_seq')::int)
WHERE contact = 'test_c';

INSERT INTO test_result(test_name, success)
SELECT 'Company_get_billing_info working', count(*) = 1
FROM company_get_billing_info((select max(id) from entity_credit_account))
WHERE control_code is not null;

-- Note tests --

INSERT INTO test_result (test_name, success)
SELECT 'entity__save_notes',
       entity__save_notes ( currval('entity_id_seq')::int, 'Test note text', 'Test note subject' ) > 0;

INSERT INTO test_result (test_name, success)
SELECT 'entity__save_note subject record',
       CASE WHEN subject = 'Test note subject' THEN 't'::bool ELSE 'f'::bool END
       FROM entity_note
       WHERE id = currval('note_id_seq');

INSERT INTO test_result(test_name, success)
SELECT 'eca_save_notes',
       eca__save_notes( currval('entity_credit_account_id_seq')::int, 'Test note text', 'ECA test note subject' ) > 0;

INSERT INTO test_result (test_name, success)
SELECT 'eca__save_notes subject record',
       CASE WHEN subject = 'ECA test note subject' THEN 't'::bool ELSE 'f'::bool END
       FROM eca_note
       WHERE id = currval('note_id_seq');


SELECT * FROM test_result;


SELECT (select count(*) from test_result where success is true)
|| ' tests passed and '
|| (select count(*) from test_result where success is not true)
|| ' failed' as message;

ROLLBACK;
