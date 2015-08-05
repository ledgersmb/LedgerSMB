
BEGIN;

--- #######   Currency names

CREATE OR REPLACE FUNCTION currency__save
(in_curr text, in_description text)
RETURNS text AS $$
BEGIN
   UPDATE currency
      SET description = in_description
    WHERE curr = in_curr;

   IF NOT FOUND THEN
     INSERT INTO currency (curr, description)
          VALUES (in_curr, in_description);
   END IF;

   RETURN in_curr;
END;$$ language plpgsql;

COMMENT ON FUNCTION currency__save(text, text) IS
$$Creates a new currency if 'in_curr' doesn''t exist yet;
otherwise, updates the description.$$;


CREATE OR REPLACE FUNCTION currency__delete(in_curr text)
RETURNS void AS $$
BEGIN
   IF defaults_get_defaultcurrency() = in_curr THEN
      RAISE EXCEPTION 'Unable to delete default currency %', in_curr;
   END IF;

   -- defer the rest of the checks to the available integrity constraints
   DELETE FROM currency WHERE curr = in_curr;
END;$$ language plpgsql;

COMMENT ON FUNCTION currency__delete(text) IS
$$Removes the indicated currency, if it''s not the default currency
or subject to other integrity constraints.$$;

CREATE OR REPLACE FUNCTION currency__get(in_curr text)
RETURNS currency AS
$$
   SELECT * FROM currency WHERE curr = $1;
$$ language sql;

COMMENT ON FUNCTION currency__get(text) IS
$$Retrieves a currency and its description using the currency indicator.$$;

CREATE OR REPLACE FUNCTION currency__list()
RETURNS SETOF currency AS
$$
   SELECT * FROM currency;
$$ language sql;

COMMENT ON FUNCTION currency__list() IS
$$Returns all currencies.$$;


--- #######   Rate types

CREATE OR REPLACE FUNCTION exchangerate_type__save
(in_id numeric, in_description text)
RETURNS text AS $$
DECLARE
   t_id numeric;
BEGIN
   t_id := in_id;

   IF in_id IS NOT NULL THEN
      UPDATE exchangerate_type
         SET description = in_description
       WHERE id = in_id;
   END IF;

   IF in_id IS NULL OR NOT FOUND THEN
      INSERT INTO exchangerate_type (description)
          VALUES (in_description)
      RETURNING id INTO t_id;
   ELSE
      RAISE EXCEPTION 'Unable to update unknown exchangerate_type (%)', in_id;
   END IF;

   RETURN t_id;
END;$$ language plpgsql;

COMMENT ON FUNCTION exchangerate_type__save(numeric, text) IS
$$Creates a new exchangerate type if in_id is null doesn''t exist yet;
otherwise, updates the description.$$;


CREATE OR REPLACE FUNCTION exchangerate_type__delete(in_id numeric)
RETURNS void AS $$
BEGIN
   DELETE FROM exchangerate_type WHERE id = in_id;
END;$$ language plpgsql;

COMMENT ON FUNCTION exchangerate_type__delete(numeric) IS
$$Removes the indicated exchangerate type.$$;

CREATE OR REPLACE FUNCTION exchangerate_type__get(in_id numeric)
RETURNS exchangerate_type AS
$$
   SELECT * FROM exchangerate_type WHERE id = $1;
$$ language sql;

COMMENT ON FUNCTION exchangerate_type__get(numeric) IS
$$Retrieves an exchangerate type and its description.$$;

CREATE OR REPLACE FUNCTION exchangerate_type__list()
RETURNS SETOF exchangerate_type AS
$$
   SELECT * FROM exchangerate_type;
$$ language sql;

COMMENT ON FUNCTION exchangerate_type__list() IS
$$Returns all exchangerate types.$$;



update defaults set value = 'yes' where setting_key = 'module_load_ok';

END;
