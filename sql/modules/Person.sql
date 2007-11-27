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

commit;
