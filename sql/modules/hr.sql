
CREATE TABLE location ( 
	id SERIAL PRIMARY KEY,
	companyname text,
	address1 text,
	address2 text,
	city text,
	state text,
	country text,
	zipcode text
);	

CREATE SEQUENCE employee_id_seq;
SELECT setval('employee_id_seq', (select max(id) + 1 FROM employee));

ALTER TABLE employee ADD COLUMN locations_id integer;
ALTER TABLE employee ADD FOREIGN KEY (locations_id) REFERENCES location(id);
ALTER TABLE employee ALTER COLUMN id DROP DEFAULT;
ALTER TABLE employee ALTER COLUMN id SET DEFAULT  nextval('employee_id_seq');

CREATE OR REPLACE FUNCTION location_save
(in_id int, in_companyname text, in_address1 text, in_address2 text, 
	in_city text, in_state text, in_zipcode text, in_country text) 
returns integer AS
$$
DECLARE
	location_id integer;
BEGIN
	UPDATE location
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
	UPDATE employee
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
	INSERT INTO employee
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
returns employee as
$$
DECLARE
	emp employee%ROWTYPE;
BEGIN
	SELECT * INTO emp FROM employee WHERE id = in_id;
	RETURN emp;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION employee_list_managers
(in_id integer)
RETURNS SETOF employee as
$$
DECLARE
	emp employee%ROWTYPE;
BEGIN
	FOR emp IN 
		SELECT * FROM employee 
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
	DELETE FROM employee WHERE id = in_id;
	RETURN;
END;
$$ language plpgsql;

-- as long as we need the datatype, might as well get some other use out of it!
CREATE OR REPLACE VIEW employee_search AS
SELECT e.*, m.name AS manager 
FROM employee e JOIN employee m ON (e.managerid = m.id);

CREATE OR REPLACE FUNCTION employee_search
(in_startdatefrom date, in_startdateto date, in_name varchar, in_notes text,
	in_enddateto date, in_enddatefrom date)
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
