

DROP AGGREGATE IF EXISTS as_array(anyelement) CASCADE;
DROP AGGREGATE IF EXISTS concat_colon(text) CASCADE;

DROP FUNCTION IF EXISTS lsmb_append_array(anyarray, anyelement);
DROP FUNCTION IF EXISTS concat_colon(text, text);

