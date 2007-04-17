BEGIN;

ALTER TABLE employee RENAME TO employees;

CREATE TABLE locations ( 
	id SERIAL PRIMARY KEY,
	companyname text,
	address1 text,
	address2 text,
	city text,
	state text,
	country text,
	zipcode text
);	

CREATE SEQUENCE employees_id_seq;
SELECT setval('employees_id_seq', (select max(id) + 1 FROM employees));

ALTER TABLE employees ADD COLUMN locations_id integer;
ALTER TABLE employees ADD FOREIGN KEY (locations_id) REFERENCES locations(id);
ALTER TABLE employees ALTER COLUMN id DROP DEFAULT;
ALTER TABLE employees ALTER COLUMN id SET DEFAULT  nextval('employee_id_seq');

DROP RULE employee_id_track_i ON employees; -- no longer needed

CREATE TABLE account_links AS

COMMIT;
