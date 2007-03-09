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

CREATE OR REPLACE FUNCTION location_save
(in_id int, in_companyname text, in_address1 text, in_address2 text, 
	in_city text, in_state text, in_zipcode text, in_country text) 
returns integer AS
$$
DECLARE
	location_id integer;
BEGIN
	UPDATE locations
	SET companyname = in_companyname,
		address1 = in_address1,
		address2 = in_address2,
		city = in_city,
		state = in_state,
		zipcode = in_zipcode,
		country = in_country
	WHERE id = in_id;
	IF FOUND THEN
		return in_id;
	END IF;
	INSERT INTO location 
	(companyname, address1, address2, city, state, zipcode, country)
	VALUES
	(in_companyname, in_address1, in_address2, in_city, in_state,
		in_zipcode, in_country);
	SELECT lastval('location_id_seq') INTO location_id;
	return location_id;
END;
$$ LANGUAGE PLPGSQL;

create or replace function employee_save
(in_id integer, in_location_id integer, in_employeenumber varchar(32), 
	in_name varchar(64), in_address1 varchar(32), in_address2 varchar(32),
	in_city varchar(32), in_state varchar(32), in_zipcode varchar(10),
	in_country varchar(32), in_workphone varchar(20), 
	in_homephone varchar(20), in_startdate date, in_enddate date, 
	in_notes text, in_role varchar(20), in_sales boolean, in_email text, 
	in_ssn varchar(20), in_dob date, in_iban varchar(34), 
	in_bic varchar(11), in_managerid integer) returns int
AS
$$
BEGIN
	UPDATE employees
	SET location_id = in_location_id,
		employeenumber = in_employeenumber,
		name = in_name,
		address1 = in_address1,
		address2 = in_address2,
		city = in_city,
		state = in_state,
		zipcode = in_zipcode,
		country = in_country,
		workphone = in_workphone,
		homephone = in_homephone,
		startdate = in_startdate,
		enddate = in_enddate,
		notes = in_notes,
		role = in_role,
		sales = in_sales,
		email = in_email,
		ssn = in_ssn,
		dob=in_dob,
		iban = in_iban, 
		bic = in_bic, 
		manager_id = in_managerid
	WHERE id = in_id;

	IF FOUND THEN
		return in_id;
	END IF;
	INSERT INTO employees
	(location_id, employeenumber, name, address1, address2, 
		city, state, zipcode, country, workphone, homephone,
		startdate, enddate, notes, role, sales, email, ssn,
		dob, iban, bic, managerid)
	VALUES
	(in_location_id, in_employeenumber, in_name, in_address1,
		in_address2, in_city, in_state, in_zipcode, in_country,
		in_workphone, in_homephone, in_startdate, in_enddate,
		in_notes, in_role, in_sales, in_email, in_ssn, in_dob,
		in_iban, in_bic, in_managerid);
	SELECT currval('employee_id_seq') INTO employee_id;
	return employee_id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION employee_get
(in_id integer)
returns employees as
$$
DECLARE
	emp employees%ROWTYPE;
BEGIN
	SELECT * INTO emp FROM employees WHERE id = in_id;
	RETURN emp;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION employee_list_managers
(in_id integer)
RETURNS SETOF employees as
$$
DECLARE
	emp employees%ROWTYPE;
BEGIN
	FOR emp IN 
		SELECT * FROM employees 
		WHERE sales = '1' AND role='manager'
			AND id <> coalesce(in_id, -1)
		ORDER BY name
	LOOP
		RETURN NEXT emp;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION employee_delete
(in_id integer) returns void as
$$
BEGIN
	DELETE FROM employees WHERE id = in_id;
	RETURN;
END;
$$ language plpgsql;

-- as long as we need the datatype, might as well get some other use out of it!
CREATE OR REPLACE VIEW employee_search AS
SELECT e.*, m.name AS manager 
FROM employees e LEFT JOIN employees m ON (e.managerid = m.id);

CREATE OR REPLACE FUNCTION employee_search
(in_startdatefrom date, in_startdateto date, in_name varchar, in_notes text,
	in_enddateto date, in_enddatefrom date, in_sales boolean)
RETURNS SETOF employee_search AS
$$
DECLARE
	emp employee_search%ROWTYPE;
BEGIN
	FOR emp IN
		SELECT * FROM employee_search
		WHERE coalesce(startdate, 'infinity'::timestamp)
			>= coalesce(in_startdateto, '-infinity'::timestamp)
			AND coalesce(startdate, '-infinity'::timestamp) <=
				coalesce(in_startdatefrom, 
						'infinity'::timestamp)
			AND coalesce(enddate, '-infinity'::timestamp) <= 
				coalesce(in_enddateto, 'infinity'::timestamp)
			AND coalesce(enddate, 'infinity'::timestamp) >= 
				coalesce(in_enddatefrom, '-infinity'::timestamp)
			AND lower(name) LIKE '%' || lower(in_name) || '%'
			AND lower(notes) LIKE '%' || lower(in_notes) || '%'
			AND (sales = 't' OR coalesce(in_sales, 'f') = 'f')
	LOOP
		RETURN NEXT emp;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION location_get (in_id integer) returns locations AS
$$
DECLARE
	location locations%ROWTYPE;
BEGIN
	SELECT * INTO location FROM locations WHERE id = in_id;
	RETURN location;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION location_search 
(in_companyname varchar, in_address1 varchar, in_address2 varchar, 
	in_city varchar, in_state varchar, in_zipcode varchar, 
	in_country varchar)
RETURNS SETOF locations
AS
$$
DECLARE
	location locations%ROWTYPE;
BEGIN
	FOR location IN
		SELECT * FROM locations 
		WHERE companyname ilike '%' || in_companyname || '%'
			AND address1 ilike '%' || in_address1 || '%'
			AND address2 ilike '%' || in_address2 || '%'
			AND in_city ilike '%' || in_city || '%'
			AND in_state ilike '%' || in_state || '%'
			AND in_zipcode ilike '%' || in_zipcode || '%'
			AND in_country ilike '%' || in_country || '%'
	LOOP
		RETURN NEXT location;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION location_list_all () RETURNS SETOF locations AS
$$
DECLARE 
	location locations%ROWTYPE;
BEGIN
	FOR location IN
		SELECT * FROM locations 
		ORDER BY company_name, city, state, country
	LOOP
		RETURN NEXT location;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION location_delete (in_id integer) RETURNS VOID AS
$$
BEGIN
	DELETE FROM locations WHERE id = in_id;
END;
$$ language plpgsql;

COMMIT;
