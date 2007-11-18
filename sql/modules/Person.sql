begin;

CREATE OR REPLACE FUNCTION person_save

(in_id integer, in_salutation int, 
in_first_name text, in_last_name text    
)
RETURNS INT AS $$

    DECLARE
        e_id int;
        e entity;
        loc location;
        l_id int;
        per person;
        p_id int;
    BEGIN
    
    select * into e from entity where id = in_id and entity_class = 3;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No entity found for ID %', in_id;
    END IF;
    
    select * into per FROM person WHERE entity_id = in_id;
    
    IF FOUND THEN
    
        -- do an update
        
        UPDATE person SET
            salutation = in_salutation,
            first_name = in_first_name,
            last_name = in_last_name
        WHERE
            entity_id = in_id
        AND
            id = per.id;
    
    ELSE
    
        -- Do an insert
        
        INSERT INTO person (salutation, first_name, last_name) VALUES 
            (in_salutation, in_first_name, in_last_name);
                
    
    END IF;
END;
$$ language plpgsql;

commit;
