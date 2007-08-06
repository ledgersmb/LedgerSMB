-- VERSION 1.3.0
BEGIN;
CREATE OR REPLACE FUNCTION employee_save
(in_id integer, in_employeenumber varchar(32), 
	in_salutation int, in_first_name varchar(64), in_last_name varchar(64),
	in_address1 varchar(32), in_address2 varchar(32),
	in_city varchar(32), in_state varchar(32), in_zipcode varchar(10),
	in_country int, in_workphone varchar(20), 
	in_homephone varchar(20), in_startdate date, in_enddate date, 
	in_notes text, in_role varchar(20), in_sales boolean, in_email text, 
	in_ssn varchar(20), in_dob date, in_iban varchar(34), 
	in_bic varchar(11), in_managerid integer) 
returns int AS $$ 
DECLARE
    e_id int;
    e entity;
    loc location;
    l_id int;
    per person;
    p_id int;
BEGIN

    select * into e from entity where id = in_id and entity_class = 3;
    
    if found then
        
        select l.* into loc from location l 
        left join person_to_location ptl on ptl.location_id = l.id
        left join person p on p.id = ptl.person_id
        where p.entity_id = in_id;
        
        select * into per from person p where p.entity_id = in_id;
        
        update location 
        set
            line_one = in_address1,
        	line_two = in_address2,
        	city_province = in_city,
        	mail_code = in_zipcode,
        	country_id = in_country
        where id = loc.id;
	
    	UPDATE employee
    	SET 
    		employeenumber = in_employeenumber,
    		startdate = in_startdate,
    		enddate = in_enddate,
    		role = in_role,
    		sales = in_sales,
    		ssn = in_ssn,
    		dob = in_dob, 
    		managerid = in_managerid
    	WHERE entity_id = in_id;
    	
    	update entity_note
    	set 
    	    note = in_note
    	where entity_id = in_id;
    	
    	UPDATE entity_bank_account 
    	SET
    	    bic = in_bic,
    	    iban = in_iban
    	WHERE entity_id = in_id;
    	
    	UPDATE person
        SET
            salutation_id = in_salutation,
            first_name = in_first_name,
            last_name = in_last_name
        WHERE entity_id = in_id;
        
        UPDATE person_to_contact
        set
            contact = in_homephone
        WHERE person_id = per.id
          AND contact_class_id = 11;
          
        UPDATE person_to_contact
        set
          contact = in_workphone
        WHERE person_id = per.id
          AND contact_class_id = 1;
          
        UPDATE person_to_contact
        set
        contact = in_email
        WHERE person_id = per.id
        AND contact_class_id = 12;  
        
        return in_id;
        
	ELSIF NOT FOUND THEN	
	    -- first, create a new entity
    	-- Then, create an employee.
	
    	e_id := in_id; -- expect nextval entity_id to have been called.
    	INSERT INTO entity (id, entity_class, name) VALUES (e_id, 3, in_first_name||' '||in_last_name);
    	    
    	INSERT INTO entity_bank_account (entity_id, iban, bic)
    	VALUES (e_id, in_iban, in_bic);
    	
    	p_id := nextval('person_id_seq');
    	insert into person (id, salutation_id, first_name, last_name, entity_id)
    	VALUES
    	(p_id, in_salutation, in_first_name, in_last_name, e_id);
	    
	    if in_notes is not null then
	        insert into entity_note (note_class, note, ref_key, vector)
	        values (1, in_notes, e_id, '');
	    END IF;
	    
	    insert into person_to_contact (person_id, contact_class_id, contact)
	    VALUES (p_id, 1, in_workphone); -- work phone #
	    insert into person_to_contact (person_id, contact_class_id, contact)
	    VALUES (p_id, 11, in_homephone); -- Home phone #
	    insert into person_to_contact (person_id, contact_class_id, contact)
	    VALUES (p_id, 12, in_email); -- email address.
	    
    	INSERT INTO employee
    	(employeenumber, startdate, enddate, 
    	    role, sales, ssn,
    		dob, managerid, entity_id, entity_class_id)
    	VALUES
    	(in_employeenumber, in_startdate, in_enddate,
    	    in_role, in_sales, in_ssn, 
    	    in_dob,	in_managerid, e_id, 3);
    		
    	l_id := nextval('location_id_seq');
    	insert into location (id, location_class, line_one, line_two, city_province, country_id, mail_code)
    	VALUES (
    	    l_id,
    	    1,
    	    in_address1,
    	    in_address2,
    	    in_city,
    	    in_country, 
    	    in_zipcode    	    
    	);
    	insert into person_to_location (person_id, location_id)
    	VALUES (p_id, l_id);
	
    	return e_id;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

-- why is this like this?
CREATE OR REPLACE FUNCTION employee_get
(in_id integer)
returns employee as
$$
DECLARE
	emp employee%ROWTYPE;
BEGIN
	SELECT * INTO emp FROM employees WHERE id = in_id;
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
			AND entity_id <> coalesce(in_id, -1)
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

CREATE INDEX name_idx ON employee USING gist(name gist_trgm_ops);
CREATE INDEX notes_idx ON entity_note USING gist(note gist_trgm_ops);

CREATE OR REPLACE VIEW employee_search AS
SELECT e.*, em.name AS manager, emn.note, en.name as name
FROM employee e 
LEFT JOIN entity en on (e.entity_id = en.id)
LEFT JOIN employee m ON (e.managerid = m.entity_id)
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
COMMIT;