--
BEGIN;

CREATE OR REPLACE FUNCTION entity_save(
    in_entity_id int, in_name text, in_entity_class INT
) RETURNS INT AS $$

    DECLARE
        e entity;
        e_id int;
        
    BEGIN
    
        select * into e from entity where id = in_entity_id;
        
            
        update 
            entity 
        SET
            name = in_name,
            entity_class = in_entity_class
        WHERE
            id = in_entity_id;
        IF NOT FOUND THEN
            -- do the insert magic.
            e_id = nextval('entity_id_seq');
            insert into entity (id, name, entity_class) values 
                (e_id,
                in_name,
                in_entity_class
                );
            return e_id;
        END IF;
        return in_entity_id;
            
    END;

$$ language 'plpgsql';


CREATE OR REPLACE FUNCTION entity__get_entity (
    in_entity_id int
) RETURNS setof entity AS $$

declare
    v_row entity;
BEGIN
    SELECT * INTO v_row FROM entity WHERE id = in_entity_id;
    IF NOT FOUND THEN
        raise exception 'Could not find entity with ID %', in_entity_id;
    ELSE
        return next v_row;
    END IF;
END;

$$ language plpgsql;



commit;
