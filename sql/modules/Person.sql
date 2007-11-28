begin;

CREATE OR REPLACE FUNCTION person_save
(in_entity_id integer, in_salutation_id int, 
in_first_name text, in_middle_name text, in_last_name text    
)
RETURNS INT AS $$

    DECLARE
        e_id int;
        e entity;
        loc location;
        l_id int;
        p_id int;
    BEGIN
    
    select * into e from entity where id = in_entity_id and entity_class = 3;
    e_id := in_entity_id; 
    
    IF NOT FOUND THEN
        INSERT INTO entity (name, entity_class) 
	values (in_first_name || ' ' || in_last_name, 3);
	e_id := currval('entity_id_seq');
       
    END IF;
    
      
    UPDATE person SET
            salutation_id = in_salutation_id,
            first_name = in_first_name,
            last_name = in_last_name,
            middle_name = in_middle_name
    WHERE
            entity_id = in_entity_id;
    IF FOUND THEN
	RETURN in_entity_id;
    ELSE 
        -- Do an insert
        
        INSERT INTO person (salutation_id, first_name, last_name, entity_id)
	VALUES (in_salutation_id, in_first_name, in_last_name, e_id);
        RETURN e_id;
    
    END IF;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION employee__save 
(in_entity_id int, in_start_date date, in_end_date date, in_dob date, 
	in_role text, in_ssn text, in_sales bool, in_manager_id int, in_employee_number text)
RETURNS int AS $$
DECLARE out_id INT;
BEGIN
	UPDATE entity_employee 
	SET startdate = in_start_date,
		enddate = in_end_date,
		dob = in_dob,
		role = in_role,
		ssn = in_ssn,
		manager_id = in_manager_id,
		employeenumber = in_employee_number,
		person_id = (select id FROM person 
			WHERE entity_id = in_entity_id)
	WHERE entity_id = in_entity_id;

	out_id = in_entity_id;

	IF NOT FOUND THEN
		INSERT INTO entity_employee 
			(startdate, enddate, dob, role, ssn, manager_id, 
				employeenumber, entity_id, person_id)
		VALUES
			(in_start_date, in_end_date, in_dob, in_role, in_ssn,
				in_manager_id, in_employee_number, in_entity_id,
				(SELECT id FROM person 
				WHERE entity_id = in_entity_id));
		RETURN in_entity_id;
	END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION person__list_locations(in_entity_id int)
RETURNS SETOF location_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT l.id, l.line_one, l.line_two, l.line_three, l.city, 
			l.state, c.name, lc.class
		FROM location l
		JOIN person_to_location ctl ON (ctl.location_id = l.id)
		JOIN person p ON (ctl.person_id = p.id)
		JOIN location_class lc ON (ctl.location_class = lc.id)
		JOIN country c ON (c.id = l.country_id)
		WHERE p.entity_id = in_entity_id
		ORDER BY lc.id, l.id, c.name
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION person__list_contacts(in_entity_id int)
RETURNS SETOF contact_list AS 
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN 
		SELECT cc.class, c.contact
		FROM person_to_contact c
		JOIN contact_class cc ON (c.contact_class_id = cc.id)
		JOIN person p ON (c.person_id = p.id)
		WHERE p.entity_id = in_entity_id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION person__save_contact
(in_entity_id int, in_contact_class int, in_contact text)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN
	INSERT INTO person_to_contact(person_id, contact_class_id, contact)
	SELECT id, in_contact_class, in_contact FROM person
	WHERE entity_id = in_entity_id;

	RETURN 1;
END;
$$ LANGUAGE PLPGSQL;

create or replace function person_location_save(
    in_entity_id int, in_location_id int,
    in_line_one text, in_line_two text, 
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text, 
    in_country_code int
) returns int AS $$

    DECLARE
        l_row location;
        l_id INT;
	t_person_id int;
    BEGIN
	SELECT id INTO t_person_id
	FROM person WHERE entity_id = in_entity_id;

	DELETE FROM person_to_location
	WHERE person_id = t_person_id
		AND location_id = in_location_id;

	SELECT location_save(in_line_one, in_line_two, in_line_three, in_city,
		in_state, in_mail_code, in_country_code) 
	INTO l_id;

	INSERT INTO person_to_location 
		(person_id, location_id)
	VALUES  (t_person_id, l_id);

	RETURN l_id;    
    END;

$$ language 'plpgsql';

commit;
