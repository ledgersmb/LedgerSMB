CREATE OR REPLACE FUNCTION business_type__list() RETURNS SETOF business AS
$$
DECLARE out_row business%ROWTYPE;
BEGIN
	FOR out_row IN SELECT * FROM business ORDER BY description LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON function business_type__list() IS 
$$Returns a list of all business types. Ordered by description by default.$$;
