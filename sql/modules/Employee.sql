-- VERSION 1.3.0
BEGIN;


CREATE OR REPLACE FUNCTION employee_save(
    in_person int, in_entity int, in_startdate date, in_enddate date,
	in_role text, in_sales boolean, in_dob date, 
    in_managerid integer, in_employeenumber text
)
returns int AS $$

    DECLARE
        e_ent entity_employee;
        e entity;
        p person;
    BEGIN
        select * into e from entity where id = in_entity and entity_class = 3;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No entity found for ID %', in_id;
        END IF;
        
        select * into p from person where id = in_person;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No person found for ID %', in_id;
        END IF;
        
        -- Okay, we're good. Check to see if we update or insert.
        
        select * into e_ent from entity_employee where person_id = in_person 
            and entity_id = in_entity;
            
        IF NOT FOUND THEN
            -- insert.
            
            INSERT INTO entity_employee (person_id, entity_id, startdate, 
                enddate, role, sales, manager_id, employeenumber, dob)
            VALUES (in_person, in_entity, in_startdate, in_enddate, in_role, 
                in_sales, in_managerid, in_employeenumber, in_dob);
            
            return in_entity;
        ELSE
        
            -- update
            
            UPDATE entity_employee
            SET
                startdate = in_startdate,
                enddate = in_enddate,
                role = in_role,
                sales = in_sales,
                manager_id = in_managerid,
                employeenumber = in_employeenumber,
                dob = in_dob
            WHERE
                entity_id = in_entity
            AND
                person_id = in_person;
                
            return in_entity;
        END IF;
    END;

$$ language 'plpgsql';

create view employees as
    select 
        s.salutation,
        p.first_name,
        p.last_name,
        ee.*
    FROM person p
    JOIN entity_employee ee USING (entity_id)
    JOIN salutation s ON (p.salutation_id = s.id);
    

CREATE OR REPLACE FUNCTION employee_get
(in_id integer)
returns employees as
$$
DECLARE
	emp employees%ROWTYPE;
BEGIN
	SELECT 
	    s.salutation, 
	    p.first_name,
	    p.last_name,
	    ee.* 
	INTO emp 
    FROM employees ee 
    join person p USING (entity_id)
    JOIN salutation s ON (p.salutation_id = s.id)
    WHERE ee.entity_id = in_id;
    
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

COMMIT;

