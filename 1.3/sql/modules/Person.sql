
-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General 
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

BEGIN;

CREATE OR REPLACE FUNCTION person__get_my_entity_id() RETURNS INT AS
$$
	SELECT entity_id from users where username = SESSION_USER;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION person__get_my_entity_id() IS
$$ Returns the entity_id of the current, logged in user.$$;

CREATE OR REPLACE FUNCTION person__list_languages() 
RETURNS SETOF language AS
$$ SELECT * FROM language ORDER BY code ASC $$ language sql;
COMMENT ON FUNCTION person__list_languages() IS
$$ Returns a list of languages ordered by code$$;

CREATE OR REPLACE FUNCTION person__list_salutations() 
RETURNS SETOF salutation AS
$$ SELECT * FROM salutation ORDER BY id ASC $$ language sql;

COMMENT ON FUNCTION person__list_salutations() IS
$$ Returns a list of salutations ordered by id.$$; 

CREATE OR REPLACE FUNCTION person__save
(in_entity_id integer, in_salutation_id int, 
in_first_name text, in_middle_name text, in_last_name text,
in_country_id integer
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
    
    IF FOUND THEN
        UPDATE entity 
           SET name = in_first_name || ' ' || in_last_name,
               country_id = in_country_id
         WHERE id = in_entity_id; 
    ELSE
        INSERT INTO entity (name, entity_class, country_id) 
	values (in_first_name || ' ' || in_last_name, 3, in_country_id);
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

COMMENT ON FUNCTION person__save
(in_entity_id integer, in_salutation_id int, 
in_first_name text, in_middle_name text, in_last_name text,
in_country_id integer
) IS
$$ Saves the person with the information specified.  Returns the entity_id
of the record saved.$$;

CREATE OR REPLACE FUNCTION person__list_locations(in_entity_id int)
RETURNS SETOF location_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT l.id, l.line_one, l.line_two, l.line_three, l.city, 
			l.state, l.mail_code, c.id, c.name, lc.id, lc.class
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

COMMENT ON FUNCTION person__list_locations(in_entity_id int) IS
$$ Returns a list of locations specified attached to the person.$$;

CREATE OR REPLACE FUNCTION person__list_contacts(in_entity_id int)
RETURNS SETOF contact_list AS 
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN 
		SELECT cc.class, cc.id, c.description, c.contact
		FROM person_to_contact c
		JOIN contact_class cc ON (c.contact_class_id = cc.id)
		JOIN person p ON (c.person_id = p.id)
		WHERE p.entity_id = in_entity_id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION person__list_contacts(in_entity_id int) IS
$$ Returns a list of contacts attached to the function.$$;
--

CREATE OR REPLACE FUNCTION person__delete_contact
(in_person_id int, in_contact_class_id int, in_contact text)
returns bool as $$
BEGIN

DELETE FROM person_to_contact
 WHERE person_id = in_person_id and contact_class_id = in_contact_class_id
       and contact= in_contact;
RETURN FOUND;

END;

$$ language plpgsql;

COMMENT ON FUNCTION person__delete_contact
(in_person_id int, in_contact_class_id int, in_contact text) IS
$$ Deletes a contact record specified for the person.  Returns true if a record
was found and deleted, false if not.$$;

DROP FUNCTION IF EXISTS  person__save_contact
(in_entity_id int, in_contact_class int, in_contact_orig text, in_contact_new TEXT);

CREATE OR REPLACE FUNCTION person__save_contact
(in_entity_id int, in_contact_class int, in_old_contact text, in_contact_new TEXT, in_description text, in_old_contact_class int)
RETURNS INT AS
$$
DECLARE 
    out_id int;
    v_orig person_to_contact;
BEGIN
    
    SELECT cc.* into v_orig 
    FROM person_to_contact cc, person p
    WHERE p.entity_id = in_entity_id 
    and cc.contact_class_id = in_old_contact_class
    AND cc.contact = in_old_contact
    AND cc.person_id = p.id;
    
    IF NOT FOUND THEN
    
        -- create
        INSERT INTO person_to_contact(person_id, contact_class_id, contact, description)
        VALUES (
            (SELECT id FROM person WHERE entity_id = in_entity_id),
            in_contact_class,
            in_contact_new,
            in_description
        );
        return 1;
    ELSE
        -- edit.
        UPDATE person_to_contact
           SET contact = in_contact_new, description = in_description
         WHERE contact = in_old_contact
               AND person_id = v_orig.person_id
               AND contact_class_id = in_old_contact_class;
        return 0;
    END IF;
    
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION person__save_contact
(in_entity_id int, in_contact_class int, in_old_contact text, in_contact_new TEXT, in_description text, in_old_contact_class int) IS
$$ Saves saves contact info.  Returns 1 if a row was inserted, 0 if it was 
updated. $$;

CREATE OR REPLACE FUNCTION person__list_bank_account(in_entity_id int)
RETURNS SETOF entity_bank_account AS
$$
DECLARE out_row entity_bank_account%ROWTYPE;
BEGIN
	FOR out_row IN
		SELECT * from entity_bank_account where entity_id = in_entity_id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION person__list_bank_account(in_entity_id int) IS
$$ Lists bank accounts for a person$$;

CREATE OR REPLACE FUNCTION person__list_notes(in_entity_id int) 
RETURNS SETOF entity_note AS 
$$
DECLARE out_row record;
BEGIN
	FOR out_row IN
		SELECT *
		FROM entity_note
		WHERE ref_key = in_entity_id
		ORDER BY created
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
		
COMMENT ON FUNCTION person__list_notes(in_entity_id int) IS
$$ Returns a list of notes attached to a person.$$;
--
CREATE OR REPLACE FUNCTION person__delete_location
(in_person_id int, in_location_id int, in_location_class int)
RETURNS BOOL AS
$$
BEGIN

DELETE FROM person_to_location
 WHERE person_id = in_person_id AND location_id = in_location_id 
       AND location_class = in_location_class;

RETURN FOUND;

END;
$$ language plpgsql;

COMMENT ON FUNCTION person__delete_location
(in_person_id int, in_location_id int, in_location_class int) IS
$$Deletes a location mapping to a person.  Returns true if found, false if no
data deleted.$$;

CREATE OR REPLACE FUNCTION person__save_location(
    in_entity_id int, 
    in_location_id int,
    in_location_class int,
    in_line_one text, 
    in_line_two text, 
    in_line_three text,
    in_city TEXT, 
    in_state TEXT, 
    in_mail_code text, 
    in_country_code int,
    in_old_location_class int
) returns int AS $$

    DECLARE
        l_row location;
        l_id INT;
	    t_person_id int;
    BEGIN
	SELECT id INTO t_person_id
	FROM person WHERE entity_id = in_entity_id;

    UPDATE person_to_location
       SET location_class = in_location_class
     WHERE person_id = t_person_id 
           AND location_class = in_old_location_class
           AND location_id = in_location_id;
    
    
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

COMMENT ON FUNCTION person__save_location(
    in_entity_id int,
    in_location_id int,
    in_location_class int,
    in_line_one text,
    in_line_two text,
    in_line_three text,
    in_city TEXT,
    in_state TEXT,
    in_mail_code text,
    in_country_code int,
    in_old_location_class int
) IS
$$ Saves a location mapped to the person with the specified information.
Returns the location id saved.$$;
COMMIT;
