-- COPYRIGHT (C) 2012 The LedgerSMB Core Team.  This file may be used under the
-- terms of the GNU General Public License version 2 or at your option any later
-- version.  Please see the included license.txt for more information.


BEGIN;

DROP TYPE IF EXISTS order_search_line CASCADE;

CREATE TYPE order_search_line AS (
    id int,
    ordnumber text,
    transdate date,
    reqdate date,
    amount numeric,
    legal_name text,
    netamount numeric,
    entity_credit_account int,
    closed bool,
    quonumber text,
    shippingpoint text,
    exchangerate numeric,
    shipvia text,
    employee text, 
    manager text,
    curr char(3),
    ponumber text,
    meta_number text,
    entity_id int
);

CREATE OR REPLACE FUNCTION order__search 
(in_oe_class_id int, in_meta_number text, in_legal_name text, in_ponumber text,
 in_ordnumber text, in_open bool, in_closed bool, in_shipvia text, 
 in_description text, in_date_from date, in_date_to date, in_shippable bool,
 in_buisness_units int[])
RETURNS SETOF order_search_line
LANGUAGE PLPGSQL AS $$

DECLARE retval order_search_line;

BEGIN

FOR retval IN
       SELECT o.id, 
              CASE WHEN oe_class_id IN (1, 2) THEN o.ordnumber
                   WHEN oe_class_id IN (3, 4) THEN o.quonumber
                   ELSE NULL
               END as ordnumber, o.transdate, o.reqdate,
              o.amount, c.legal_name AS name, o.netamount, 
              o.entity_credit_account, o.closed, o.quonumber, o.shippingpoint,
              CASE WHEN ct.entity_class = 2 THEN ex.buy ELSE ex.sell END
              AS exchangerate, o.shipvia, pe.first_name || ' ' || pe.last_name 
              AS employee, pm.first_name || ' ' || pm.last_name AS manager, 
              o.curr, o.ponumber, ct.meta_number, c.entity_id
         FROM oe o
         JOIN entity_credit_account ct ON (o.entity_credit_account = ct.id)
         JOIN company c ON (c.entity_id = ct.entity_id)
    LEFT JOIN person pe ON (o.person_id = pe.id)
    LEFT JOIN entity_employee e ON (pe.entity_id = e.entity_id)
    LEFT JOIN person pm ON (e.manager_id = pm.id)
    LEFT JOIN entity_employee m ON (pm.entity_id = m.entity_id)
    LEFT JOIN exchangerate ex 
              ON (ex.curr = o.curr AND ex.transdate = o.transdate)
        WHERE o.oe_class_id = in_oe_class_id
             AND (in_meta_number IS NULL 
                   or ct.meta_number ILIKE in_meta_number || '%')
             AND (in_legal_name IS NULL OR
                     c.legal_name @@ plainto_tsquery(in_legal_name))
             AND (in_ponumber IS NULL OR o.ponumber ILIKE in_ponumber || '%')
            AND (in_ordnumber IS NULL 
                     OR o.ordnumber ILIKE in_ordnumber || '%')
             AND (in_open is true or o.closed is not true)
             AND (in_closed is true or o.closed is not false)
             AND (in_shipvia IS NULL 
                      OR o.shipvia @@ plainto_tsquery(in_shipvia))
             AND (in_description IS NULL AND in_shippable IS NULL OR
                     EXISTS (SELECT 1 
                               FROM orderitems oi 
                               JOIN parts p ON p.id = oi.parts_id
                              WHERE trans_id = o.id
                                    AND (in_description IS NULL OR 
                                        oi.description 
                                        @@ plainto_tsquery(in_description))
                                    AND (in_shippable IS NULL OR
                                         p.assembly OR 
                                         p.inventory_accno_id IS NOT NULL))
                 )
             AND (in_date_from IS NULL OR o.transdate >= in_date_from)
             AND (in_date_to IS NULL OR o.transdate <= in_date_to)
                                    
LOOP
   RETURN NEXT retval;
END LOOP;
END;
$$;


COMMIT;
