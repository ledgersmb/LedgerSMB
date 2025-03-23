
set client_min_messages = 'warning';


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
LANGUAGE SQL AS $$

       SELECT o.id,
              CASE WHEN oe_class_id IN (1, 2) THEN o.ordnumber
                   WHEN oe_class_id IN (3, 4) THEN o.quonumber
                   ELSE NULL
               END as ordnumber, o.transdate, o.reqdate,
              o.amount_tc, c.name, o.netamount_tc,
              o.entity_credit_account, o.closed, o.quonumber, o.shippingpoint,
              o.shipvia, pe.first_name || ' ' || pe.last_name
              AS employee, pm.first_name || ' ' || pm.last_name AS manager,
              o.curr, o.ponumber, ct.meta_number, c.id
         FROM oe o
         JOIN entity_credit_account ct ON (o.entity_credit_account = ct.id)
         JOIN entity c ON (c.id = ct.entity_id)
    LEFT JOIN person pe ON (o.person_id = pe.id)
    LEFT JOIN entity_employee e ON (pe.entity_id = e.entity_id)
    LEFT JOIN person pm ON (e.manager_id = pm.id)
    LEFT JOIN entity_employee m ON (pm.entity_id = m.entity_id)
        WHERE o.oe_class_id = in_oe_class_id
             AND (in_meta_number IS NULL
                   or ct.meta_number ILIKE in_meta_number || '%')
             AND (in_legal_name IS NULL
                  OR c.name ilike '%' || in_legal_name || '%'
                  OR c.name @@ plainto_tsquery(in_legal_name))
             AND (in_ponumber IS NULL OR o.ponumber ILIKE in_ponumber || '%')
             AND (in_ordnumber IS NULL
                  OR (oe_class_id IN (1, 2) AND o.ordnumber ILIKE in_ordnumber || '%')
                  OR oe_class_id IN (3, 4) AND o.quonumber ILIKE in_ordnumber || '%')
             AND ((in_open is true and o.closed is false)
                 OR (in_closed is true and o.closed is true))
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
             AND (in_date_to IS NULL OR o.transdate <= in_date_to);

$$;


CREATE OR REPLACE FUNCTION order__combine(in_ids int[])
RETURNS SETOF oe LANGUAGE PLPGSQL AS
$$

DECLARE retval oe;
        ordercount int;
        ids int[];
        loop_info record;
        settings text[];
        my_person_id int;
BEGIN

SELECT id INTO my_person_id
  FROM person
 WHERE entity_id = person__get_my_entity_id();

settings := ARRAY['sonumber', 'ponumber', 'sqnumber', 'rfqnumber'];
ids := array[]::int[];

-- This approach of looping through insert/select operations will break down
-- if overly complex order consolidation jobs are run (think, hundreds of
-- combined orders in the *output*
--
-- The tradeoff is that if we address the huge complex runs here, then we have
-- the possibility of having to lock the whole table which poses other issues.
-- For that reason, I am going with this approach for now. --CT

FOR loop_info IN
       SELECT max(id) as id, taxincluded, entity_credit_account, oe_class_id,
              curr
         FROM oe WHERE id = any(in_ids)
     GROUP BY taxincluded, entity_credit_account, oe_class_id, curr
LOOP

INSERT INTO oe
       (ordnumber, transdate,   amount_tc,     netamount_tc,
        reqdate,   taxincluded, shippingpoint, notes,
        curr,      person_id,   closed,        quotation,
        quonumber, intnotes,    shipvia,       language_code,
        ponumber,  terms,       oe_class_id,   entity_credit_account)
SELECT CASE WHEN oe_class_id IN (1, 2)
            THEN setting_increment(settings[oe_class_id])
            ELSE NULL
        END,          now()::date,        sum(amount_tc),  sum(netamount_tc),
        min(reqdate), taxincluded,        min(shippingpoint), '',
        curr,         my_person_id, false, false,
        CASE WHEN oe_class_id IN (3, 4)
            THEN setting_increment(settings[oe_class_id])
            ELSE NULL
        END,          NULL,      NULL,          NULL,
        null,       min(terms),  oe_class_id,  entity_credit_account
  FROM oe
 WHERE id = any (in_ids)
       AND taxincluded = loop_info.taxincluded
       AND entity_credit_account = loop_info.entity_credit_account
       AND oe_class_id = loop_info.oe_class_id
 GROUP BY curr, taxincluded, oe_class_id, entity_credit_account;


INSERT INTO orderitems
       (trans_id,      parts_id,        description,         qty,
        sellprice,     precision,       discount,            unit,
        reqdate,       ship,            serialnumber,        notes)
SELECT currval('oe_id_seq'), oi.parts_id, oi.description,     oi.qty,
       oi.sellprice,   oi.precision,    oi.discount,         oi.unit,
       oi.reqdate,     oi.ship,         oi.serialnumber,     oi.notes
  FROM orderitems oi
  JOIN oe ON oi.trans_id = oe.id
 WHERE oe.id = any (in_ids)
       AND taxincluded = loop_info.taxincluded
       AND entity_credit_account = loop_info.entity_credit_account
       AND oe_class_id = loop_info.oe_class_id;

ids := ids || currval('oe_id_seq')::int;

END LOOP;

UPDATE oe SET closed = true WHERE id = any(in_ids);

FOR retval IN select * from oe WHERE id =any(ids)
LOOP
   RETURN NEXT retval;
END LOOP;

END;
$$;


update defaults set value = 'yes' where setting_key = 'module_load_ok';


COMMIT;
