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

COMMIT;
