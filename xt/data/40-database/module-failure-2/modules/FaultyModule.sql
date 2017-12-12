
BEGIN;

CREATE FUNCTION fail_me() RETURNS defaults LANGUAGE sql AS
$$
  SELECT * FROM defaults;
$$;

-- Double creation of the function is intentional (to get an error)
CREATE FUNCTION fail_me() RETURNS defaults LANGUAGE sql AS
$$
  SELECT * FROM defaults;
$$;


UPDATE defaults
   SET value = 'yes'
 WHERE setting_key = 'module_load_ok';

END;
