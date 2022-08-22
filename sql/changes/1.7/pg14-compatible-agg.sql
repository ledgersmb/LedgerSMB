

drop aggregate as_array(anyelement) cascade;
drop aggregate compound_array(anyarray) cascade;



CREATE OR REPLACE FUNCTION lsmb_array_append(ary anyarray, elm anyelement)
RETURNS anyarray
AS $$
   SELECT array_append(ary, elm);
$$ LANGUAGE sql;

COMMENT ON FUNCTION lsmb_array_append(anyarray, anyelement)
IS $$PostgreSQL 14 vs pre-14 compatibility measure.$$;

CREATE AGGREGATE as_array (
        BASETYPE = ANYELEMENT,
        STYPE = ANYARRAY,
        SFUNC = LSMB_ARRAY_APPEND,
        INITCOND = '{}'
);

COMMENT ON AGGREGATE as_array(ANYELEMENT) IS
$$ A basic array aggregate to take elements and return a one-dimensional array.

Example:  SELECT as_array(id) from entity_class;
$$;


CREATE OR REPLACE FUNCTION compound_array(ary anyarray, elm anyarray)
RETURNS anyarray
AS $$
   SELECT array_cat(ary, elm);
$$ LANGUAGE sql;

COMMENT ON FUNCTION compound_array(anyarray, anyarray)
IS $$PostgreSQL 14 vs pre-14 compatibility measure.$$;


CREATE AGGREGATE compound_array (
        BASETYPE = ANYARRAY,
        STYPE = ANYARRAY,
        SFUNC = COMPOUND_ARRAY,
        INITCOND = '{}'
);

COMMENT ON AGGREGATE compound_array(ANYARRAY) is
$$ Returns an n dimensional array.

Example: SELECT as_array(ARRAY[id::text, class]) from contact_class
$$;
