BEGIN;

DROP TYPE IF EXISTS goods_search_result CASCADE;

CREATE TYPE goods_search_result AS (
   invnumber text,
   trans_id int,
   ordnumber text,
   ord_id int,
   quonumber text,
   partnumber text,
   id int,
   description text,
   onhand numeric,
   qty numeric,
   unit varchar,
   price_updated date,
   partsgroup text,
   listprice numeric,
   sellprice numeric,
   lastcost numeric,
   avgcost numeric,
   linetotal numeric, 
   markup numeric,
   bin text,
   rop numeric,
   weight numeric,
   notes text,
   image text,
   drawing text,
   microfiche text,
   make text,
   model text,
   curr char(3),
   serialnumber text,
   module text
);

CREATE OR REPLACE FUNCTION goods__search 
(in_partnumber text, in_description text,
 in_partsgroup_id int, in_serial_number text, in_make text,
 in_model text, in_drawing text, in_microfiche text,
 in_status text, in_date_from date, in_date_to date,
 in_sales_invoices bool, in_purchase_invoices bool,
 in_sales_orders bool, in_purchase_orders bool, in_quotations bool, 
 in_rfqs bool)
RETURNS SETOF goods_search_result 
LANGUAGE PLPGSQL STABLE AS $$
BEGIN

-- Trying a CTE here to cut down on left joins.
RETURN QUERY 
         WITH orders (invnumber, id, ordnumber, quonumber, qty, sellprice, 
              serialnumber, recordtype, oe_class_id, parts_id, curr) as 
      (SELECT a.invnumber, a.id, null::text, null::text, i.qty, i.sellprice, 
              i.serialnumber, a.recordtype, null::int, i.parts_id, a.curr
         FROM (SELECT id, invnumber, 'is'::text as recordtype, transdate, curr
                 FROM ar WHERE in_sales_invoices
                UNION
               SELECT id, invnumber, 'ir'::text as recordtype, transdate, curr
                 FROM ap WHERE in_purchase_invoices
              ) a
         JOIN invoice i ON i.trans_id = a.id
        WHERE (in_date_from is null or in_date_from >= a.transdate) and
              (in_date_to is null or in_date_to <= a.transdate)
        UNION
       SELECT null::text, o.id, o.ordnumber, o.quonumber, i.qty, i.sellprice, 
              i.serialnumber, 'oe', oe_class_id, i.parts_id, o.curr
         FROM oe o
         JOIN orderitems i ON o.id = i.trans_id
        WHERE (o.oe_class_id = 1 AND in_sales_orders)
              OR (o.oe_class_id = 2 AND in_purchase_orders)
              OR (o.oe_class_id = 3 AND in_quotations)
              OR (o.oe_class_id = 4 AND in_rfqs)
              AND((in_date_from is null or in_date_from >= o.transdate) and
              (in_date_to is null or in_date_to <= o.transdate))
       )
       SELECT o.invnumber, 
              CASE WHEN o.recordtype in ('ir', 'is') THEN o.id ELSE NULL END, 
              o.ordnumber, 
              CASE WHEN o.recordtype = 'oe' THEN o.id ELSE NULL END, 
              o.quonumber, p.partnumber, 
              p.id, p.description, p.onhand, o.qty, p.unit, p.priceupdate, 
              pg.partsgroup,
              p.listprice, p.sellprice, p.lastcost, p.avgcost, 
              o.qty * o.sellprice as linetotal, 
              CASE WHEN p.lastcost = 0 THEN NULL
                   ELSE ((p.sellprice / p.lastcost) - 1) * 100 
              END as markup,
              p.bin, p.rop, p.weight, p.notes, p.image, p.drawing, p.microfiche,
              m.make, m.model, o.curr,
              o.serialnumber, o.recordtype
         FROM parts p
    LEFT JOIN orders o ON o.parts_id = p.id
    LEFT JOIN makemodel m ON m.parts_id = p.id
    LEFT JOIN partsgroup pg ON p.partsgroup_id = pg.id
        WHERE (in_partnumber is null or p.partnumber ilike in_partnumber || '%')
              AND (in_description is null 
                  or p.description @@ plainto_tsquery(in_description))
              AND (in_partsgroup_id is null 
                  or p.partsgroup_id = in_partsgroup_id )
              AND (in_serial_number is null
                  or o.serialnumber = in_serial_number)
              AND (in_make is null or m.make ilike in_make || '%')
              AND (in_model is null or m.model  ilike in_model || '%')
              AND (in_drawing IS NULL OR p.drawing ilike in_drawing || '%')
              AND (in_microfiche IS NULL
                  OR p.microfiche ilike in_microfiche || '%')
              AND ((in_status = 'active' and not p.obsolete) 
                   OR (in_status = 'obsolete' and p.obsolete)
                   OR (in_status = 'short' and p.onhand <= p.rop)
                   OR (in_status = 'unused'
                      AND NOT EXISTS (select 1 FROM invoice 
                                       WHERE parts_id = p.id
                                       UNION
                                      SELECT 1 FROM orderitems
                                       WHERE parts_id = p.id)));
END;
$$;

DROP FUNCTION IF EXISTS partsgroups__list_all();

CREATE OR REPLACE FUNCTION partsgroup__search(in_pricegroup text)
RETURNS SETOF partsgroup LANGUAGE SQL STABLE AS $$
  SELECT * FROM partsgroup 
   WHERE $1 is null or partsgroup ilike $1 || '%'
ORDER BY partsgroup;
$$;

CREATE OR REPLACE FUNCTION pricegroup__search(in_pricegroup text)
RETURNS SETOF pricegroup LANGUAGE SQL STABLE AS $$
  SELECT * FROM pricegroup
   WHERE $1 IS NULL OR pricegroup ilike $1 || '%'
ORDER BY pricegroup;
$$;


COMMIT;
