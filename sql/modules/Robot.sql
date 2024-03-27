
set client_min_messages = 'warning';


-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

BEGIN;

CREATE OR REPLACE FUNCTION robot__get_my_entity_id() RETURNS INT AS
$$
        SELECT entity_id from users where username = SESSION_USER OR username = 'Migrator';
$$ LANGUAGE SQL;

COMMENT ON FUNCTION robot__get_my_entity_id() IS
$$ Returns the entity_id of the current, logged in user.$$;

DROP TYPE IF EXISTS robot_entity CASCADE;

CREATE TYPE robot_entity AS (
    entity_id int,
    control_code text,
    name text,
    country_id int,
    country_name text,
    first_name text,
    middle_name text,
    last_name text
);

CREATE FUNCTION robot__get(in_entity_id int)
RETURNS robot_entity AS
$$
SELECT e.id, e.control_code, e.name, e.country_id, c.name,
       p.first_name, p.middle_name, p.last_name
  FROM entity e
  JOIN country c ON c.id = e.country_id
  JOIN robot p ON p.entity_id = e.id
 WHERE e.id = $1;
$$ LANGUAGE SQL;

CREATE FUNCTION robot__get_by_cc(in_control_code text)
RETURNS robot_entity AS
$$
SELECT e.id, e.control_code, e.name, e.country_id, c.name,
       p.first_name, p.middle_name, p.last_name
  FROM entity e
  JOIN country c ON c.id = e.country_id
  JOIN robot p ON p.entity_id = e.id
 WHERE e.control_code = $1;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS robot__save (int, text, text, text, int);
CREATE OR REPLACE FUNCTION robot__save
(in_entity_id integer,
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

    select * into e from entity where id = in_entity_id;
    e_id := in_entity_id;

    IF FOUND THEN
        UPDATE entity
           SET name = in_first_name || ' ' || in_last_name,
               country_id = in_country_id
         WHERE id = in_entity_id;
    ELSE
        INSERT INTO entity (name, country_id)
        values (in_first_name || ' ' || in_last_name, in_country_id);
        e_id := currval('entity_id_seq');

    END IF;


    UPDATE robot SET
            first_name = in_first_name,
            last_name = in_last_name,
            middle_name = in_middle_name
    WHERE
            entity_id = in_entity_id;
    IF FOUND THEN
        RETURN in_entity_id;
    ELSE
        -- Do an insert

        INSERT INTO robot (first_name, last_name, entity_id)
        VALUES (in_first_name, in_last_name, e_id);

        RETURN e_id;

    END IF;
END;
$$ language plpgsql;

COMMENT ON FUNCTION robot__save
(in_entity_id integer,
in_first_name text, in_middle_name text, in_last_name text,
in_country_id integer
) IS
$$ Saves the robot with the information specified.  Returns the entity_id
of the record saved.$$;

CREATE OR REPLACE FUNCTION robot__list_notes(in_entity_id int)
RETURNS SETOF entity_note AS
$$
                SELECT *
                FROM entity_note
                WHERE ref_key = in_entity_id
                ORDER BY created
$$ LANGUAGE SQL;

COMMENT ON FUNCTION robot__list_notes(in_entity_id int) IS
$$ Returns a list of notes attached to a robot.$$;
--
update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
