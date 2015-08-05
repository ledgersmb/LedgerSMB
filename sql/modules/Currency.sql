
BEGIN;

CREATE OR REPLACE FUNCTION currency__save
(in_curr text, in_description text)
RETURNS text AS $$
BEGIN
   UPDATE currency
      SET description = in_description
    WHERE curr = in_curr;

   IF NOT FOUND THEN
     INSERT INTO currency (curr, description)
          VALUES ($1, $2);
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

update defaults set value = 'yes' where setting_key = 'module_load_ok';

END;
