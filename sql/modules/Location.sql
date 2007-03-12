-- VERSION 1.3.0
CREATE OR REPLACE FUNCTION location_save
(in_id int, in_companyname text, in_address1 text, in_address2 text, 
	in_city text, in_state text, in_zipcode text, in_country text) 
returns integer AS
$$
DECLARE
	location_id integer;
BEGIN
	UPDATE locations
	SET companyname = in_companyname,
		address1 = in_address1,
		address2 = in_address2,
		city = in_city,
		state = in_state,
		zipcode = in_zipcode,
		country = in_country
	WHERE id = in_id;
	IF FOUND THEN
		return in_id;
	END IF;
	INSERT INTO location 
	(companyname, address1, address2, city, state, zipcode, country)
	VALUES
	(in_companyname, in_address1, in_address2, in_city, in_state,
		in_zipcode, in_country);
	SELECT lastval('location_id_seq') INTO location_id;
	return location_id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION location_get (in_id integer) returns locations AS
$$
DECLARE
	location locations%ROWTYPE;
BEGIN
	SELECT * INTO location FROM locations WHERE id = in_id;
	RETURN location;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION location_search 
(in_companyname varchar, in_address1 varchar, in_address2 varchar, 
	in_city varchar, in_state varchar, in_zipcode varchar, 
	in_country varchar)
RETURNS SETOF locations
AS
$$
DECLARE
	location locations%ROWTYPE;
BEGIN
	FOR location IN
		SELECT * FROM locations 
		WHERE companyname ilike '%' || in_companyname || '%'
			AND address1 ilike '%' || in_address1 || '%'
			AND address2 ilike '%' || in_address2 || '%'
			AND in_city ilike '%' || in_city || '%'
			AND in_state ilike '%' || in_state || '%'
			AND in_zipcode ilike '%' || in_zipcode || '%'
			AND in_country ilike '%' || in_country || '%'
	LOOP
		RETURN NEXT location;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION location_list_all () RETURNS SETOF locations AS
$$
DECLARE 
	location locations%ROWTYPE;
BEGIN
	FOR location IN
		SELECT * FROM locations 
		ORDER BY company_name, city, state, country
	LOOP
		RETURN NEXT location;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION location_delete (in_id integer) RETURNS VOID AS
$$
BEGIN
	DELETE FROM locations WHERE id = in_id;
END;
$$ language plpgsql;

