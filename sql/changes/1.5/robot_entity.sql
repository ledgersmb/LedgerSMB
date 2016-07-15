INSERT INTO entity_class (id,class)
VALUES (9,'Sub-contractor'),
       (10,'Robot');    -- Software robot for automation of user-based tasks, Migration reconciliation approval authority, for example

SELECT setval('entity_class_id_seq',10);

-- Software robot. Currently implemented as a degraded person
CREATE TABLE robot (
    id serial PRIMARY KEY,
    entity_id integer references entity(id) not null,
    first_name text check (first_name ~ '[[:alnum:] _\-\.\*]?'),
    middle_name text,
    last_name text check (last_name ~ '[[:alnum:] _\-\.\*]') NOT NULL,
    created date not null default current_date,
    unique(entity_id)
 );

COMMENT ON TABLE robot IS $$ Every robot, must have an entity to derive a common or display name. The correct way to get class information on a robot would be robot.entity_id->entity_class_to_entity.entity_id. $$;
