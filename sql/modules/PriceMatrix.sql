
set client_min_messages = 'warning';


BEGIN;

CREATE OR REPLACE FUNCTION pricematrix__for_vendor(in_credit_id int, in_parts_id int)
returns SETOF partsvendor LANGUAGE SQL AS
$$
SELECT *
  FROM partsvendor
 WHERE parts_id = in_parts_id
       AND credit_id = in_credit_id;
$$;

DROP FUNCTION IF EXISTS pricematrix__for_customer
(in_credit_id int, in_parts_id int, in_transdate date, in_qty numeric);
CREATE OR REPLACE FUNCTION pricematrix__for_customer
(in_credit_id int, in_parts_id int, in_transdate date, in_qty numeric, in_currency text)
RETURNS SETOF partscustomer LANGUAGE SQL AS
$$
   SELECT p.*
     FROM partscustomer p
     JOIN entity_credit_account eca ON eca.id = in_credit_id
LEFT JOIN pricegroup pg ON eca.pricegroup_id = pg.id
    WHERE p.parts_id = in_parts_id
        AND coalesce(p.validfrom, in_transdate) <=
            in_transdate
        AND coalesce(p.validto, in_transdate) >=
            in_transdate
        AND (p.credit_id = eca.id OR p.pricegroup_id = pg.id
             OR (p.credit_id is null and p.pricegroup_id is null))
        AND coalesce(qty, 0) <= coalesce(in_qty, 0)
        AND coalesce(p.curr, defaults_get_defaultcurrency()) =
            coalesce(in_currency, defaults_get_defaultcurrency())
  ORDER BY case WHEN p.credit_id = eca.id THEN 1
                WHEN p.pricegroup_id = pg.id THEN 2
                ELSE 3
            end asc, qty desc;

$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
