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
(in_location_id int, in_address1 text, in_address2 text, in_address3 text,
	in_city text, in_state text, in_zipcode text, in_country int) 
returns integer AS
$$
DECLARE
	location_id integer;
	location_row RECORD;
BEGIN
	
	IF in_location_id IS NULL THEN
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
	    return location_id;
	ELSE
	    -- Test it.
	    SELECT * INTO location_row WHERE id = in_location_id;
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
	country text
);

CREATE OR REPLACE FUNCTION location__get(in_id int) returns location_result AS $$

declare
    l_row location_result;
begin
    FOR l_row IN 
        SELECT 
            l.id,                   
            l.line_one,             
            l.line_two,             
            l.line_three,           
            l.city,                 
            l.state,                
            l.mail_code,            
            c.name as country,      
            NULL
        FROM location l
        JOIN country c on l.country_id = c.id
        WHERE l.id = in_id
    LOOP
    
        return l_row;
    END LOOP;
END;
$$ language plpgsql ;
