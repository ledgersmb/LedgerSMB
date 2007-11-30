CREATE OR REPLACE FUNCTION business_type__list() RETURNS SETOF business AS
$$
DECLARE out_row business%ROWTYPE;
BEGIN
	FOR out_row IN SELECT * FROM business LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
