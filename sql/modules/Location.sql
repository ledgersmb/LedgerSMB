-- VERSION 1.3.0

CREATE OR REPLACE FUNCTION location_list_class()
RETURNS SETOF location_class AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT * FROM location_class ORDER BY id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION location_list_country()
RETURNS SETOF country AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT * FROM country ORDER BY name
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION location_save
(in_address1 text, in_address2 text, in_address3 text,
	in_city text, in_state text, in_zipcode text, in_country int) 
returns integer AS
$$
DECLARE
	location_id integer;
	location_row RECORD;
BEGIN
	
	SELECT * INTO location_row FROM location
	WHERE line_one = in_address1 AND
		coalesce(line_two, '') = coalesce(in_address2, '') AND
		coalesce(line_three, '') = coalesce(in_address3, '') AND
		city = in_city AND
		coalesce(state, '') = coalesce(in_state, '') AND
		coalesce(mail_code, '') = coalesce(in_zipcode, '') AND
		country_id = in_country
	LIMIT 1;
	IF FOUND THEN
		return location_row.id;
	END IF;
	INSERT INTO location 
	(line_one, line_two, line_three, city, state, mail_code, country_id,
		created)
	VALUES
	(in_address1, in_address2, in_address3, in_city, in_state,
		in_zipcode, in_country, now());
	SELECT currval('location_id_seq') INTO location_id;
	return location_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON function location_save
(in_companyname text, in_address1 text, in_address2 text, 
	in_city text, in_state text, in_zipcode text, in_country int) IS
$$ Note that this does NOT override the data in the database.
Instead we search for locations matching the desired specifications and if none 
are found, we insert one.  Either way, the return value of the location can be
used for mapping to other things.  This is necessary because locations are 
only loosly coupled with entities, etc.$$;

CREATE OR REPLACE FUNCTION location_get (in_id integer) returns location AS
$$
DECLARE
	out_location location%ROWTYPE;
BEGIN
	SELECT * INTO out_location FROM location WHERE id = in_id;
	RETURN out_location;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION location_search 
(in_companyname varchar, in_address1 varchar, in_address2 varchar, 
	in_city varchar, in_state varchar, in_zipcode varchar, 
	in_country varchar)
RETURNS SETOF location
AS
$$
DECLARE
	out_location location%ROWTYPE;
BEGIN
	FOR out_location IN
		SELECT * FROM location 
		WHERE companyname ilike '%' || in_companyname || '%'
			AND address1 ilike '%' || in_address1 || '%'
			AND address2 ilike '%' || in_address2 || '%'
			AND in_city ilike '%' || in_city || '%'
			AND in_state ilike '%' || in_state || '%'
			AND in_zipcode ilike '%' || in_zipcode || '%'
			AND in_country ilike '%' || in_country || '%'
	LOOP
		RETURN NEXT out_location;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION location_list_all () RETURNS SETOF location AS
$$
DECLARE 
	out_location location%ROWTYPE;
BEGIN
	FOR out_location IN
		SELECT * FROM location 
		ORDER BY company_name, city, state, country
	LOOP
		RETURN NEXT out_location;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION location_delete (in_id integer) RETURNS VOID AS
$$
BEGIN
	DELETE FROM location WHERE id = in_id;
END;
$$ language plpgsql;

CREATE TYPE location_result AS (
	id int,
	line_one text,
	line_two text,
	line_three text,
	city text,
	state text,
        mail_code text,
	country text,
	class text
);

