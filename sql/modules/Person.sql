begin;

CREATE OR REPLACE FUNCTION person__save
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
			l.state, l.mail_code, c.name, lc.class
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
		SELECT cc.class, cc.id, c.contact
		FROM person_to_contact c
		JOIN contact_class cc ON (c.contact_class_id = cc.id)
		JOIN person p ON (c.person_id = p.id)
		WHERE p.entity_id = in_entity_id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

--

CREATE OR REPLACE FUNCTION person__save_contact
(in_entity_id int, in_contact_class int, in_contact_orig text, in_contact_new TEXT)
RETURNS INT AS
$$
DECLARE 
    out_id int;
    v_orig person_to_contact;
BEGIN
    
    SELECT cc.* into v_orig 
    FROM person_to_contact cc, person p
    WHERE p.entity_id = in_entity_id 
    and cc.contact_class_id = in_contact_class
    AND cc.contact = in_contact_orig
    AND cc.person_id = p.id;
    
    IF NOT FOUND THEN
    
        -- create
        INSERT INTO person_to_contact(person_id, contact_class_id, contact)
        VALUES (
            (SELECT id FROM person WHERE entity_id = in_entity_id),
            in_contact_class,
            in_contact_new
        );
        return 1;
    ELSE
        -- edit.
        UPDATE person_to_contact
        SET contact = in_contact_new
        WHERE 
        contact = in_contact_orig
        AND person_id = v_orig.person_id
        AND contact_class = in_contact_class;
        return 0;
    END IF;
    
END;
$$ LANGUAGE PLPGSQL;

--

create or replace function person__save_location(
    in_entity_id int, 
    in_location_id int,
    in_location_class int,
    in_line_one text, 
    in_line_two text, 
    in_line_three text,
    in_city TEXT, 
    in_state TEXT, 
    in_mail_code text, 
    in_country_code int
) returns int AS $$

    DECLARE
        l_row location;
        l_id INT;
	    t_person_id int;
    BEGIN
	SELECT id INTO t_person_id
	FROM person WHERE entity_id = in_entity_id;
    -- why does it delete?
    
    select * into l_row FROM location
    WHERE id = in_location_id;
    
    IF NOT FOUND THEN
        -- Create a new one.
        l_id := location_save(
            in_location_id, 
    	    in_line_one, 
    	    in_line_two, 
    	    in_line_three, 
    	    in_city,
    		in_state, 
    		in_mail_code, 
    		in_country_code);
    	
        INSERT INTO person_to_location 
    		(person_id, location_id, location_class)
    	VALUES  (t_person_id, l_id, in_location_class);
    ELSE
        l_id := location_save(
            in_location_id, 
    	    in_line_one, 
    	    in_line_two, 
    	    in_line_three, 
    	    in_city,
    		in_state, 
    		in_mail_code, 
    		in_country_code);
        -- Update the old one.
    END IF;
    return l_id;
    END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION person__delete_location (
    in_entity_id INT, in_location_id INT
) returns int AS $$

DECLARE
    v_loc location;
    
BEGIN
    
    select loc.* into v_loc FROM location loc
    JOIN person_to_location ptl ON loc.id = ptl.location_id
    JOIN person p ON p.id = ptl.person_id
    WHERE p.entity_id = in_entity_id 
    AND loc.id = in_location_id;
    
    IF NOT FOUND THEN
       RAISE EXCEPTION 'Cannot find records to delete for entity % and location %', in_entity_id, in_location_id;
    ELSE
        DELETE FROM people_to_location WHERE location_id = in_location_id;
        DELETE FROM location WHERE location_id = in_location_id;
    END IF;

END;

$$ language plpgsql;

CREATE OR REPLACE FUNCTION person__all_locations (
    in_entity_id int
) returns setof location AS $$

    SELECT l.* FROM location l
    JOIN person_to_location ptl ON ptl.location_id = l.id
    JOIN person p on ptl.person_id = p.id
    WHERE p.id = $1;

$$ language sql;

commit;
