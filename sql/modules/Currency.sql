
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

DROP FUNCTION IF EXISTS currency__delete(in_curr text);
CREATE OR REPLACE FUNCTION currency__delete(in_curr CHAR(3))
RETURNS void AS $$
BEGIN
   IF defaults_get_defaultcurrency() = in_curr THEN
      RAISE EXCEPTION 'Unable to delete default currency %', in_curr;
   END IF;

   -- defer the rest of the checks to the available integrity constraints
   DELETE FROM currency WHERE curr = in_curr;
END;$$ language plpgsql;

COMMENT ON FUNCTION currency__delete(CHAR(3)) IS
$$Removes the indicated currency, if it''s not the default currency
or subject to other integrity constraints.$$;

CREATE OR REPLACE FUNCTION currency__get(in_curr text)
RETURNS currency AS
$$
   SELECT * FROM currency WHERE curr = $1;
$$ language sql;

COMMENT ON FUNCTION currency__get(text) IS
$$Retrieves a currency and its description using the currency indicator.$$;

CREATE OR REPLACE FUNCTION currency__is_used(in_curr text)
RETURNS BOOLEAN AS $$
BEGIN
  BEGIN
    delete from currency where curr = in_curr;
    raise sqlstate 'P0004'; -- cause rollback
  EXCEPTION
    WHEN foreign_key_violation THEN
      return true;
    WHEN assert_failure THEN
      return false;
  END;
END;$$ language plpgsql security definer;

COMMENT ON FUNCTION currency__is_used(text) IS
$$Returns true if currency 'in_curr' is used within the current commpany
database. Returns false otherwise.$$;

DROP TYPE IF EXISTS currency_list CASCADE;
CREATE TYPE currency_list AS (
  curr CHARACTER(3),
  description TEXT,
  is_used BOOLEAN
);

DROP FUNCTION IF EXISTS currency__list();
CREATE OR REPLACE FUNCTION currency__list(in_check_use boolean)
RETURNS SETOF currency_list AS
$$
  select c.curr, c.description,
         case when in_check_use then currency__is_used(c.curr)
              else null end as is_used
    from currency c
    left join (select value as curr from defaults where setting_key = 'curr') d
         on c.curr = d.curr
   order by case when c.curr = d.curr then 1 else 2 end, c.curr;
$$ language sql;

COMMENT ON FUNCTION currency__list(boolean) IS
$$Returns all currencies, default currency first.$$;


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

CREATE OR REPLACE FUNCTION exchangerate_type__is_used
(in_id integer)
RETURNS BOOLEAN AS $$
BEGIN
   RETURN EXISTS (SELECT 1 FROM exchangerate_default WHERE rate_type = in_id);
END;$$ language plpgsql;

COMMENT ON FUNCTION exchangerate_type__is_used(integer) IS
$$Returns true if exchangerate_type with id 'in_id' is used within the current commpany
database. Returns false otherwise.$$;

DROP TYPE IF EXISTS exchangerate_type_list CASCADE;
CREATE TYPE exchangerate_type_list AS (
  id INTEGER,
  description TEXT,
  builtin BOOLEAN,
  is_used BOOLEAN
);

DROP FUNCTION IF EXISTS exchangerate_type__list();
CREATE OR REPLACE FUNCTION exchangerate_type__list()
RETURNS SETOF exchangerate_type_list AS
$$
   SELECT id, description, builtin, exchangerate_type__is_used(id)
   FROM exchangerate_type;
$$ language sql;

COMMENT ON FUNCTION exchangerate_type__list() IS
$$Returns all exchangerate types.$$;


--- #######   Exchange rates

CREATE OR REPLACE FUNCTION exchangerate__save
(in_curr text, in_rate_type numeric, in_valid_from date, in_rate numeric)
RETURNS exchangerate_default AS $$
DECLARE
   t_row exchangerate_default;
BEGIN
   UPDATE exchangerate_default
      SET rate = in_rate
    WHERE curr = in_curr
          AND rate_type = in_rate_type
          AND valid_from = in_valid_from
   RETURNING * INTO t_row;

   IF NOT FOUND THEN
      INSERT INTO exchangerate_default (curr, rate_type, valid_from, rate)
          VALUES (in_curr, in_rate_type, in_valid_from, in_rate)
      RETURNING * INTO t_row;
   END IF;

   RETURN t_row;
END;$$ language plpgsql;

COMMENT ON FUNCTION exchangerate__save(text, numeric, date, numeric) IS
$$Creates a new exchangerate if one keyed on (curr,type,valid_from) doesn''t
exist yet; otherwise, updates the rate.$$;


CREATE OR REPLACE FUNCTION exchangerate__delete(in_curr text,
       in_rate_type numeric, in_valid_from date)
RETURNS void AS $$
BEGIN
   DELETE FROM exchangerate_default
         WHERE curr = in_curr
               AND rate_type = in_rate_type
               AND valid_from = in_valid_from;
END;$$ language plpgsql;

COMMENT ON FUNCTION exchangerate__delete(text, numeric, date) IS
$$Removes the indicated exchangerate.$$;

CREATE OR REPLACE FUNCTION exchangerate__get(in_curr text,
       in_type numeric, in_date date)
RETURNS exchangerate_default AS
$$
   SELECT * FROM exchangerate_default
     WHERE curr = $1
           AND rate_type = $2
           AND ($3 >= valid_from AND $3 < valid_to)
   ORDER BY valid_from DESC
   LIMIT 1;
$$ language sql;

COMMENT ON FUNCTION exchangerate__get(text, numeric, date) IS
$$Retrieves an exchangerate of currency in_curr and rate type in_type
applicable on date in_date.

Note: the returned record''s 'valid_from' may not be equal to the
requested date because of rates being applicable in intervals and not
solely on a single day.$$;

CREATE OR REPLACE FUNCTION exchangerate__list(in_curr text,
       in_rate_type numeric, in_valid_from_start date,
       in_valid_from_end date, in_offset numeric, in_limit numeric)
RETURNS SETOF exchangerate_default AS
$$
   SELECT * FROM exchangerate_default
    WHERE ($1 IS NULL OR curr = $1)
          AND ($2 IS NULL OR rate_type = $2)
          AND ($3 IS NULL OR valid_from >= $3)
          AND ($4 IS NULL OR valid_from <= $4)
   ORDER BY valid_from DESC
   OFFSET coalesce( $5, 0 )
   LIMIT $6;
$$ language sql;

COMMENT ON FUNCTION exchangerate__list(text,numeric,
        date,date,numeric,numeric) IS
$$Returns all exchangerates of currency in_curr and rate type in_rate_type
optionally restricting records with a valid_from betwer in_valid_from_start
and in_valid_from_end and skipping the first in_offset records and
limiting the number of returned records to in_limit.$$;




update defaults set value = 'yes' where setting_key = 'module_load_ok';

END;
