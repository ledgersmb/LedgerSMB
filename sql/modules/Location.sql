-- VERSION 1.3.0

BEGIN;

DROP TYPE IF EXISTS location_class_item CASCADE;
CREATE TYPE location_class_item AS (
id int,
class text,
authoritative bool,
entity_classes int[]
);

DROP FUNCTION IF EXISTS location_list_class();
CREATE OR REPLACE FUNCTION location_list_class()
RETURNS SETOF location_class_item AS
$$
		SELECT l.*, as_array(e.entity_class)
                  FROM location_class l
                  JOIN location_class_to_entity_class e
                       ON (l.id = e.location_class)
              GROUP BY l.id, l.class, l.authoritative
              ORDER BY l.id;
$$ language sql;

COMMENT ON FUNCTION location_list_class() IS
$$ Lists location classes, by default in order entered.$$;

CREATE OR REPLACE FUNCTION location_list_country()
RETURNS SETOF country AS
$$
		SELECT * FROM country ORDER BY name;
$$ language sql;

COMMENT ON FUNCTION location_list_country() IS
$$ Lists countries, by default in alphabetical order.$$;

CREATE OR REPLACE FUNCTION location_save
(in_location_id int, in_address1 text, in_address2 text, in_address3 text,
	in_city text, in_state text, in_zipcode text, in_country int)
returns integer AS
$$
DECLARE
	location_id integer;
	location_row RECORD;
BEGIN

	IF in_location_id IS NULL THEN
	    SELECT id INTO location_id FROM location
	    WHERE line_one = in_address1 AND line_two = in_address2
	          AND line_three = in_address3 AND in_city = city
	          AND in_state = state AND in_zipcode = mail_code
	          AND in_country = country_id
	    LIMIT 1;

	    IF NOT FOUND THEN
	    -- Straight insert.
	    location_id = nextval('location_id_seq');
	    INSERT INTO location (
	        id,
	        line_one,
	        line_two,
	        line_three,
	        city,
	        state,
	        mail_code,
	        country_id)
	    VALUES (
	        location_id,
	        in_address1,
	        in_address2,
	        in_address3,
	        in_city,
	        in_state,
	        in_zipcode,
	        in_country
	        );
	    END IF;
	    return location_id;
	ELSE
	    RAISE NOTICE 'Overwriting location id %', in_location_id;
	    -- Test it.
	    SELECT * INTO location_row FROM location WHERE id = in_location_id;
	    IF NOT FOUND THEN
	        -- Tricky users are lying to us.
	        RAISE EXCEPTION 'location_save called with nonexistant location ID %', in_location_id;
	    ELSE
	        -- Okay, we're good.

	        UPDATE location SET
	            line_one = in_address1,
	            line_two = in_address2,
	            line_three = in_address3,
	            city = in_city,
	            state = in_state,
	            mail_code = in_zipcode,
	            country_id = in_country
	        WHERE id = in_location_id;
	        return in_location_id;
	    END IF;
	END IF;
END;
$$ LANGUAGE PLPGSQL;


COMMENT ON function location_save
(in_location_id int, in_address1 text, in_address2 text, in_address3 text,
	in_city text, in_state text, in_zipcode text, in_country int) IS
$$ Note that this does NOT override the data in the database unless in_location_id is specified.
Instead we search for locations matching the desired specifications and if none
are found, we insert one.  Either way, the return value of the location can be
used for mapping to other things.  This is necessary because locations are
only loosly coupled with entities, etc.$$;

CREATE OR REPLACE FUNCTION location__get (in_id integer) returns location AS
$$
	SELECT * FROM location WHERE id = in_id;
$$ language sql;

COMMENT ON FUNCTION location__get (in_id integer) IS
$$ Returns the location specified by in_id.$$;

CREATE OR REPLACE FUNCTION location_delete (in_id integer) RETURNS VOID AS
$$
	DELETE FROM location WHERE id = in_id;
$$ language sql;

COMMENT ON FUNCTION location_delete (in_id integer)
IS $$ DELETES the location specified by in_id.  Does not return a value.$$;

DROP TYPE IF EXISTS location_result CASCADE;

CREATE TYPE location_result AS (
        id int,
        line_one text,
        line_two text,
        line_three text,
        city text,
        state text,
        mail_code text,
        country_id int,
        country text,
        location_class int,
        class text
);

CREATE OR REPLACE FUNCTION location__deactivate(in_id int)
RETURNS location AS
$$

UPDATE location set active = false, inactive_date = now()
 WHERE id = $1;

SELECT * FROM location WHERE id = 1;

$$ language sql;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
