
set client_min_messages = 'warning';


BEGIN;

DROP TYPE IF EXISTS lsmb_date_fields CASCADE;

CREATE TYPE lsmb_date_fields AS (
    century double precision,
    decade double precision,
    year double precision,
    month double precision,
    day double precision,
    hour double precision,
    minute double precision,
    second double precision,
    quarter double precision,
    doy double precision,
    dow double precision,
    week double precision,
    epoch double precision,
    as_date date,
    as_time time
);

CREATE OR REPLACE FUNCTION lsmb__decompose_timestamp
(in_timestamp timestamptz)
RETURNS lsmb_date_fields language sql AS
$$
SELECT extract('century' from $1) as century,
       extract('decade' from $1) as decade,
       extract('year' from $1) as year,
       extract('month' from $1) as month,
       extract('day' from $1) as day,
       extract('hour' from $1) as hour,
       extract('minute' from $1) as minute,
       extract('second' from $1) as second,
       extract('quarter' from $1) as quarter,
       extract('doy' from $1) as doy,
       extract('dow' from $1) as dow,
       extract('week' from $1) as week,
       extract('epoch' from $1) as epoch,
       $1::date as as_date,
       $1::time as as_time;
$$;

CREATE OR REPLACE FUNCTION parse_date(in_date date) returns date AS
$$ select $1; $$ language sql;

COMMENT ON FUNCTION parse_date(in_date date) IS $$ Simple way to cast a Perl string to a
date format of known type. $$;

CREATE OR REPLACE FUNCTION get_default_lang() RETURNS text AS
$$ SELECT coalesce((select description FROM language
    WHERE code = (SELECT substring(value, 1, 2) FROM defaults
                   WHERE setting_key = 'default_language')), 'english');
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION language__is_used(in_code text)
RETURNS BOOLEAN AS $$
BEGIN
  PERFORM 1 FROM user_preference
  WHERE (name = 'language' AND value = in_code)
  OR in_code = 'en'  -- entity_credit_account uses this as a default
  LIMIT 1;

  IF FOUND THEN RETURN TRUE; END IF;

  BEGIN
    DELETE FROM language WHERE code = in_code;
    RAISE SQLSTATE 'P0004'; -- cause rollback
  EXCEPTION
    WHEN FOREIGN_KEY_VIOLATION THEN
      RETURN TRUE;
    WHEN ASSERT_FAILURE THEN
      RETURN FALSE;
  END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION language__is_used(text) IS
$$Returns true if language having code 'in_code' is used within the
current commpany database. This includes related tables, user language
preference settings and the 'en' language code used as a default in the
entity_credit_account table.

Returns false if the 'in_code' is not used.$$;

CREATE OR REPLACE FUNCTION warehouse__list_all() RETURNS SETOF warehouse AS
$$
SELECT * FROM warehouse order by description;
$$ language sql;

DROP FUNCTION IF EXISTS invoice__get_by_vendor_number(text, text);

CREATE OR REPLACE FUNCTION invoice__get_by_vendor_number
(in_meta_number text, in_invoice_number text)
RETURNS ap AS
$$
        SELECT * FROM ap WHERE entity_credit_account =
                (select id from entity_credit_account where entity_class = 1
                AND meta_number = in_meta_number)
                AND invnumber = in_invoice_number;
$$ LANGUAGE SQL;

DROP TYPE if exists tree_record CASCADE;
CREATE TYPE tree_record AS (t int[]);

CREATE OR REPLACE FUNCTION in_tree
(in_node_id int, in_search_array tree_record[])
RETURNS BOOL IMMUTABLE LANGUAGE SQL AS
$$
SELECT CASE WHEN count(*) > 0 THEN true ELSE false END
  FROM unnest($2) r
 WHERE t @> array[$1];
$$;

CREATE OR REPLACE FUNCTION in_tree
(in_node_id int[], in_search_array tree_record[])
RETURNS BOOL IMMUTABLE LANGUAGE SQL AS
$$
SELECT bool_and(in_tree(e, $2))
  FROM unnest($1) e;
$$;

CREATE OR REPLACE FUNCTION array_splice_to(element anyelement, arr anyarray)
  RETURNS anyarray AS
$BODY$
   select $2[1:i]
     from generate_subscripts($2,1) as i
    where $2[i] = $1
   order by i
   limit 1;
 $BODY$
  LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION array_splice_from(elem anyelement, arr anyarray)
  RETURNS anyarray AS
$BODY$
    select $2[i:array_upper($2,1)]
      from generate_subscripts($2,1) as i
     where $2[i] = $1
     order by i
     limit 1;
  $BODY$
  LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION array_endswith(elem anyelement, arr anyarray)
  RETURNS boolean
  LANGUAGE SQL
AS $$
   SELECT $2[array_upper($2,1)]=$1;
$$ IMMUTABLE;

DROP OPERATOR IF EXISTS ~*~ (text, text);

CREATE OR REPLACE FUNCTION lsmb__min_date() RETURNS date
LANGUAGE SQL AS
$$ SELECT min(transdate) from acc_trans; $$;

CREATE OR REPLACE FUNCTION lsmb__max_date() RETURNS date
LANGUAGE SQL AS
$$ SELECT max(transdate) FROM acc_trans; $$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
