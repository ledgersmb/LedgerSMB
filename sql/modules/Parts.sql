BEGIN;

CREATE OR REPLACE FUNCTION parts__search_lite
(in_partnumber text, in_description text)
RETURNS SETOF parts AS
$$
SELECT *
  FROM parts
 WHERE ($1 IS NULL OR (partnumber like $1 || '%'))
       AND ($2 IS NULL
            OR (description
                @@
                plainto_tsquery(get_default_lang()::regconfig, $2)))
       AND not obsolete
ORDER BY partnumber;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION parts__get_by_id(in_id int) RETURNS parts AS
$$
SELECT * FROM parts WHERE id = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION parts__get_by_partnumber(in_partnumber text)
RETURNS parts LANGUAGE SQL AS $$
SELECT * FROM PARTS WHERE partnumber = $1 and obsolete is not true;
$$;

CREATE OR REPLACE FUNCTION parts__get_by_partnumber(in_partnumber text)
RETURNS PARTS LANGUAGE SQL AS
$$
SELECT * FROM parts where partnumber = $1 AND NOT OBSOLETE;
$$;

CREATE OR REPLACE FUNCTION pricegroups__list() RETURNS SETOF pricegroup
LANGUAGE SQL AS $$
SELECT * FROM pricegroup;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
