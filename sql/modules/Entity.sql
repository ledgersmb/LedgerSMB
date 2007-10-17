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
        
        IF NOT FOUND THEN
            -- do the insert magic.
            e_id = nextval('entity_id_seq');
            insert into entity (id, name, entity_class) values 
                (e_id,
                in_name,
                in_entity_class
                );
            return e_id;
            
        ELSIF FOUND THEN
            
            update 
                entity 
            SET
                name = in_name
                entity_class = in_entity_class
            WHERE
                id = in_entity_id;
            return in_entity_id;
        END IF;
    END;

$$ language 'plpgsql';

commit;