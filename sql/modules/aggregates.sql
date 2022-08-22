

set client_min_messages = 'warning';


BEGIN;

CREATE OR REPLACE FUNCTION compound_array(ary anyarray, elm anyarray)
RETURNS anyarray
AS $$
   SELECT array_cat(ary, elm);
$$ LANGUAGE sql;

COMMENT ON FUNCTION compound_array(anyarray, anyarray)
IS $$PostgreSQL 14 vs pre-14 compatibility measure.$$;


DROP AGGREGATE IF EXISTS compound_array(ANYARRAY) CASCADE;
CREATE AGGREGATE compound_array (
        BASETYPE = ANYARRAY,
        STYPE = ANYARRAY,
        SFUNC = COMPOUND_ARRAY,
        INITCOND = '{}'
);

COMMENT ON AGGREGATE compound_array(ANYARRAY) is
$$ Returns an n dimensional array.
$$;



update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
