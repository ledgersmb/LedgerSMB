
set client_min_messages = 'warning';

BEGIN;


CREATE OR REPLACE FUNCTION preference__set (in_name text, in_value text, in_global boolean = false)
RETURNS BOOL AS
$$
BEGIN
  IF in_global THEN
    IF in_value IS NULL THEN
      DELETE FROM user_preference
       WHERE "name" = in_name AND user_id IS NULL;

      RETURN true;
    END IF;

    INSERT INTO user_preference (user_id, "name", "value")
         VALUES (NULL, in_name, in_value)
      ON CONFLICT (coalesce(user_id, 0), "name")
    DO
      UPDATE SET "value" = in_value;

    RETURN true;
  END IF;

  IF in_value IS NULL THEN
     DELETE FROM user_preference
      WHERE user_id = (select id from users where username=SESSION_USER)
            AND "name" = in_name;
     RETURN true;
  END IF;

  INSERT INTO user_preference (user_id, "name", "value")
       VALUES ((select id from users
                 where username=SESSION_USER), in_name, in_value)
    ON CONFLICT (coalesce(user_id, 0), "name")
  DO
    UPDATE SET "value" = in_value;

  RETURN true;
END;
$$ language plpgsql;


COMMENT ON FUNCTION preference__set (in_name text, in_value text, in_global boolean) IS
$$ sets a value in the defaults thable and returns true if successful.$$;


CREATE OR REPLACE FUNCTION preference__get (in_name text) RETURNS text AS
$$
  SELECT "value" FROM user_preference
   WHERE "name" = in_name
         AND (user_id is null
              OR user_id = (select id from users
                             where username = session_user)
                             )
  order by user_id
  limit 1
$$ LANGUAGE sql;

COMMENT ON FUNCTION preference__get (in_key text) IS
$$ Returns the value of the setting in the defaults table.$$;



update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
