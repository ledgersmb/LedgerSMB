-- VERSION 1.3.0

CREATE OR REPLACE FUNCTION setting_set (in_key varchar, in_value varchar) 
RETURNS BOOL AS
$$
BEGIN
	UPDATE defaults SET value = in_value WHERE setting_key = in_key;
        IF NOT FOUND THEN
             INSERT INTO defaults (setting_key, value) 
                  VALUES (in_setting_key, in_value);
        END IF;
	RETURNS TRUE;
END;
$$ language plpgsql;

COMMENT ON FUNCTION setting_set (in_key varchar, in_value varchar) IS
$$ sets a value in the defaults thable and returns true if successful.$$;

CREATE OR REPLACE FUNCTION setting_get (in_key varchar) RETURNS defaults AS
$$
SELECT * FROM defaults WHERE setting_key = $1;
$$ LANGUAGE sql;

COMMENT ON FUNCTION setting_get (in_key varchar) IS
$$ Returns the value of the setting in the defaults table.$$;

CREATE OR REPLACE FUNCTION setting_get_default_accounts () 
RETURNS SETOF defaults AS
$$
DECLARE
	account defaults%ROWTYPE;
BEGIN
	FOR account IN 
		SELECT * FROM defaults 
		WHERE setting_key like '%accno_id'
                ORDER BY setting_key
	LOOP
		RETURN NEXT account;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION setting_get_default_accounts () IS
$$ Returns a set of settings for default accounts.$$; 

CREATE OR REPLACE FUNCTION setting_increment (in_key varchar) returns varchar
AS
$$
DECLARE
	base_value VARCHAR;
	raw_value VARCHAR;
	increment INTEGER;
	inc_length INTEGER;
	new_value VARCHAR;
BEGIN
	SELECT value INTO raw_value FROM defaults 
	WHERE setting_key = in_key
	FOR UPDATE;

	SELECT substring(raw_value from  '(' || E'\\' || 'd*)(' || E'\\' || 'D*|<' || E'\\' || '?lsmb [^<>] ' || E'\\' || '?>)*$')
	INTO base_value;

	IF base_value like '0%' THEN
		increment := base_value::integer + 1;
		SELECT char_length(increment::text) INTO inc_length;

		SELECT overlay(base_value placing increment::varchar
			from (select char_length(base_value) 
				- inc_length + 1) for inc_length)
		INTO new_value;
	ELSE
		new_value := base_value::integer + 1;
	END IF;
	SELECT regexp_replace(raw_value, base_value, new_value) INTO new_value;
	UPDATE defaults SET value = new_value WHERE setting_key = in_key;

	return new_value;	
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION setting_increment (in_key varchar) IS
$$This function takes a value for a sequence in the defaults table and increments
it.  Leading zeroes and spaces are preserved as placeholders.  Currently <?lsmb
parsing is not supported in this routine though it may be added at a later date.
$$;

CREATE OR REPLACE FUNCTION setting__get_currencies() RETURNS text[]
AS
$$
SELECT string_to_array(value, ':') from defaults where setting_key = 'curr';
$$ LANGUAGE SQL;
-- Table schema defaults

COMMENT ON FUNCTION setting__get_currencies() is
$$ Returns an array of currencies from the defaults table.$$;

ALTER TABLE entity ALTER control_code SET default setting_increment('entity_control');

