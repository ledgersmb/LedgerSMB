-- VERSION 1.3.0


CREATE OR REPLACE FUNCTION employee__save 
(in_entity_id int, in_start_date date, in_end_date date, in_dob date, 
	in_role text, in_ssn text, in_sales bool, in_manager_id int, 
        in_employee_number text)
RETURNS int AS $$
DECLARE out_id INT;
BEGIN
	UPDATE entity_employee 
	SET startdate = coalesce(in_start_date, now()::date),
		enddate = in_end_date,
		dob = in_dob,
		role = in_role,
		ssn = in_ssn,
		manager_id = in_manager_id,
		employeenumber = in_employee_number
	WHERE entity_id = in_entity_id;

	out_id = in_entity_id;

	IF NOT FOUND THEN
		INSERT INTO entity_employee 
			(startdate, enddate, dob, role, ssn, manager_id, 
				employeenumber, entity_id)
		VALUES
			(coalesce(in_start_date, now()::date), in_end_date, 
                                in_dob, in_role, in_ssn,
				in_manager_id, in_employee_number, 
                                in_entity_id);
		RETURN in_entity_id;
	END IF;
        RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

create view employees as
    select 
        s.salutation,
        p.first_name,
        p.last_name,
        ee.*
    FROM person p
    JOIN entity_employee ee USING (entity_id)
    LEFT JOIN salutation s ON (p.salutation_id = s.id);

GRANT select ON employees TO public;
    

CREATE OR REPLACE FUNCTION employee__get
(in_id integer)
returns employees as
$$
DECLARE
	emp employees%ROWTYPE;
BEGIN
	SELECT 
	    ee.* 
	INTO emp 
    FROM employees ee 
    WHERE ee.entity_id = in_id;
    
	RETURN emp;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION employee__list_managers
(in_id integer)
RETURNS SETOF employees as
$$
DECLARE
	emp employees%ROWTYPE;
BEGIN
	FOR emp IN 
		SELECT 
		    e.salutation,
		    e.first_name,
		    e.last_name,
		    ee.* 
		FROM entity_employee ee
		JOIN entity e on e.id = ee.entity_id
		WHERE ee.sales = 't'::bool AND ee.role='manager'
			AND ee.entity_id <> coalesce(in_id, -1)
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
	DELETE FROM employee WHERE entity_id = in_id;
	RETURN;
END;
$$ language plpgsql;

-- as long as we need the datatype, might as well get some other use out of it!
--
-- % type is pg_trgm comparison.

CREATE INDEX notes_idx ON entity_note USING gist(note gist_trgm_ops);

CREATE OR REPLACE VIEW employee_search AS
SELECT e.*, em.name AS manager, emn.note, en.name as name
FROM entity_employee e 
LEFT JOIN entity en on (e.entity_id = en.id)
LEFT JOIN entity_employee m ON (e.manager_id = m.entity_id)
LEFT JOIN entity em on (em.id = m.entity_id)
LEFT JOIN entity_note emn on (emn.ref_key = em.id);

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
			AND (name % in_name
			    OR note % in_notes)
			AND (sales = 't' OR coalesce(in_sales, 'f') = 'f')
	LOOP
		RETURN NEXT emp;
	END LOOP;
	return;
END;
$$ language plpgsql;

create or replace function employee_set_location 
    (in_employee int, in_location int) 
returns void as $$

    INSERT INTO person_to_location (person_id,location_id) 
        VALUES ($1, $2);
    
$$ language 'sql';

