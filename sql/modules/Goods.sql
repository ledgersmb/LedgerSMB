BEGIN;

CREATE OR REPLACE FUNCTION part__get_by_id(in_id int) returns parts
language sql as
$$
select * from parts where id = $1;
$$;


CREATE OR REPLACE FUNCTION mfg_lot__commit(in_id int)
RETURNS numeric LANGUAGE PLPGSQL AS
$$
DECLARE t_mfg_lot mfg_lot;
BEGIN
    SELECT * INTO t_mfg_lot FROM mfg_lot WHERE id = $1;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lot not found';
    END IF;

    UPDATE parts SET onhand = onhand
                              - (select t_mfg_lot.qty from mfg_lot_item
                                  WHERE parts_id = parts.id AND
                                        mfg_lot_id = $1)
     WHERE id in (select parts_id from mfg_lot_item
                   WHERE mfg_lot_id = $1);

    UPDATE parts SET onhand = onhand + t_mfg_lot.qty
     where id = t_mfg_lot.parts_id;

    INSERT INTO gl (reference, description, transdate, approved)
    values ('mfg-' || $1::TEXT, 'Manufacturing lot',
            now(), true);

    INSERT INTO invoice (trans_id, parts_id, qty, allocated)
    SELECT currval('id')::int, parts_id, qty, 0
      FROM mfg_lot_item WHERE mfg_lot_id = $1;

    PERFORM cogs__add_for_ar_line(id) FROM invoice
      WHERE trans_id = currval('id')::int;


    PERFORM * FROM invoice
      WHERE qty + allocated <> 0 AND trans_id = currval('id')::int;

    IF FOUND THEN
       RAISE EXCEPTION 'Not enough parts in stock';
    END IF;

    INSERT INTO invoice (trans_id, parts_id, qty, allocated, sellprice)
    SELECT currval('id')::int, t_mfg_lot.parts_id, t_mfg_lot.qty * -1, 0,
           sum(amount) / t_mfg_lot.qty
      FROM acc_trans
     WHERE amount < 0 and trans_id = currval('id')::int;

    PERFORM cogs__add_for_ap_line(currval('invoice_id_seq')::int);

    -- move from reverse COGS.
    INSERT INTO acc_trans(trans_id, chart_id, transdate, amount)
    SELECT trans_id, chart_id, transdate, amount * -1
      FROM acc_trans
     WHERE amount < 0 and trans_id = currval('id')::int;

    -- difference goes into inventory
    INSERT INTO acc_trans(trans_id, transdate, amount, chart_id)
    SELECT trans_id, now(), sum(amount) * -1,
           (select inventory_accno_id from parts where id = t_mfg_lot.parts_id)
      FROM acc_trans
     WHERE trans_id = currval('id')::int
  GROUP BY trans_id;


    RETURN t_mfg_lot.qty;
END;
$$;

CREATE OR REPLACE FUNCTION assembly__stock(in_parts_id int, in_qty numeric)
RETURNS numeric LANGUAGE SQL AS $$
    INSERT INTO mfg_lot(parts_id, qty) VALUES ($1, $2);
    INSERT INTO mfg_lot_item(mfg_lot_id, parts_id, qty)
    SELECT currval('mfg_lot_id_seq')::int, parts_id, qty * $2
      FROM assembly WHERE id = $1;

    SELECT mfg_lot__commit(currval('mfg_lot_id_seq')::int);
$$;

DROP TYPE IF EXISTS goods_search_result CASCADE;

CREATE TYPE goods_search_result AS (
partnumber text,
id int,
description text,
onhand numeric,
unit text,
priceupdate date,
partsgroup text,
listprice numeric,
sellprice numeric,
lastcost numeric,
avgcost numeric,
markup numeric,
bin text,
rop numeric,
weight numeric,
notes text,
image text,
drawing text,
microfische text,
make text,
model text
);

DROP FUNCTION IF EXISTS goods__search
(in_partnumber text, in_description text,
 in_partsgroup_id int, in_serial_number text, in_make text,
 in_model text, in_drawing text, in_microfiche text,
 in_status text, in_date_from date, in_date_to date,
 in_sales_invoices bool, in_purchase_invoices bool,
 in_sales_orders bool, in_purchase_orders bool, in_quotations bool,
 in_rfqs bool);

CREATE OR REPLACE FUNCTION goods__search
(in_partnumber text, in_description text,
 in_partsgroup_id int, in_serial_number text, in_make text,
 in_model text, in_drawing text, in_microfiche text,
 in_status text, in_date_from date, in_date_to date)
RETURNS SETOF goods_search_result
LANGUAGE SQL STABLE AS $$
       SELECT p.partnumber,
              p.id, p.description, p.onhand, p.unit::text, p.priceupdate,
              pg.partsgroup,
              p.listprice, p.sellprice, p.lastcost, p.avgcost,
              CASE WHEN p.lastcost = 0 THEN NULL
                   ELSE ((p.sellprice / p.lastcost) - 1) * 100
              END as markup,
              p.bin, p.rop, p.weight, p.notes, p.image, p.drawing, p.microfiche,
              m.make, m.model
         FROM parts p
    LEFT JOIN makemodel m ON m.parts_id = p.id
    LEFT JOIN partsgroup pg ON p.partsgroup_id = pg.id
        WHERE (in_partnumber is null or p.partnumber ilike in_partnumber || '%')
              AND (in_description is null
                  or p.description @@ plainto_tsquery(in_description))
              AND (in_partsgroup_id is null
                  or p.partsgroup_id = in_partsgroup_id )
              AND (in_make is null or m.make ilike in_make || '%')
              AND (in_model is null or m.model  ilike in_model || '%')
              AND (in_drawing IS NULL OR p.drawing ilike in_drawing || '%')
              AND (in_microfiche IS NULL
                  OR p.microfiche ilike in_microfiche || '%')
              AND (in_serial_number IS NULL OR p.id IN
                      (select parts_id from invoice
                        where in_serial_number is not null
                              and serialnumber = in_serial_number))
              AND ((in_status = 'active' and not p.obsolete)
                   OR (in_status = 'obsolete' and p.obsolete)
                   OR (in_status = 'short' and p.onhand <= p.rop)
                   OR (in_status = 'unused'
                      AND NOT EXISTS (select 1 FROM invoice
                                       WHERE parts_id = p.id
                                       UNION
                                      SELECT 1 FROM orderitems
                                       WHERE parts_id = p.id)));
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

DROP TYPE IF EXISTS inv_activity_line CASCADE;
CREATE TYPE inv_activity_line AS (
   id int,
   description text,
   partnumber text,
   sold numeric,
   revenue numeric,
   receivable numeric,
   payable numeric
);

CREATE OR REPLACE FUNCTION inventory__activity
(in_from_date date, in_to_date date, in_partnumber text, in_description text)
RETURNS SETOF inv_activity_line LANGUAGE SQL AS
$$
    SELECT p.id, p.description, p.partnumber,
           SUM(CASE WHEN transtype = 'ar' THEN i.qty ELSE 0 END) AS sold,
           SUM(CASE WHEN transtype = 'ar' THEN i.sellprice * i.qty ELSE 0 END)
           AS receivable,
           SUM(CASE WHEN transtype = 'ap' THEN i.qty * -1 ELSE 0 END)
           AS payable,
           SUM(CASE WHEN transtype = 'ap' THEN -1 * i.sellprice * i.qty ELSE 0
                END) AS expenses
      FROM invoice i
      JOIN parts p ON (i.parts_id = p.id)
      JOIN (select id, approved, transdate, 'ar' as transtype FROM ar
             UNION
            SELECT id, approved, transdate, 'ap' as transdate FROM ap) a
            ON (a.id = i.trans_id AND a.approved)
     WHERE ($1 IS NULL OR a.transdate >= $1)
           AND ($2 IS NULL OR a.transdate <= $2)
           AND ($3 IS NULL OR p.partnumber ilike $3 || '%')
           AND ($4 IS NULL OR p.description @@ plainto_tsquery($4))
  GROUP BY p.id, p.description, p.partnumber
$$;


--- INVENTORY ADJUSTMENT LOGIC

DROP TYPE IF EXISTS part_at_date CASCADE;
CREATE TYPE part_at_date AS (
  parts_id int,
  partnumber text,
  expected numeric
);

-- for now treating assemblies only as bundled deals not as manufactured
-- items.  We need a good manufacturing solution. --CT

DROP VIEW IF EXISTS invoice_sum CASCADE;
DROP VIEW IF EXISTS order_sum CASCADE;

-- since we are dealing with physical counts care must be taken with the
-- approval process during inventory counting.
CREATE VIEW invoice_sum AS
SELECT a.transdate, sum(i.qty) as qty, i.parts_id
  FROM invoice i
  JOIN (select id, transdate from ar WHERE APPROVED
         union
        select id, transdate FROM ap WHERE APPROVED) a ON i.trans_id = a.id
 GROUP BY a.transdate, i.parts_id;

CREATE VIEW order_sum AS
SELECT oe.transdate,
       sum(oi.ship * case when oe_class_id = 1 THEN 1 ELSE -1 END) as qty,
       oi.parts_id
  FROM orderitems oi
  JOIN oe ON oe.closed is false and oe_class_id in (1, 2)
 GROUP BY oe.transdate, oi.parts_id;

CREATE OR REPLACE FUNCTION inventory__search_part
(in_parts_id int, in_partnumber text, in_counted_date date)
RETURNS part_at_date language sql as
$$
WITH RECURSIVE assembly_comp (a_id, parts_id, qty) AS (
     SELECT id, parts_id, qty FROM assembly
      UNION ALL
     SELECT ac.a_id, a.parts_id, ac.qty * a.qty
       FROM assembly a JOIN assembly_comp ac ON a.parts_id = ac.parts_id
)
     SELECT p.id, p.partnumber,
            sum((coalesce(i.qty, 0) + coalesce(oi.qty, 0)) * a.qty )
       FROM parts p
  LEFT JOIN assembly_comp a ON a.a_id = p.id
  LEFT JOIN invoice_sum i ON i.parts_id = p.id OR a.parts_id = i.parts_id
  LEFT JOIN order_sum oi ON oi.parts_id = p.id OR a.parts_id = i.parts_id
      WHERE p.id = $1 OR p.partnumber = $2
            OR (p.id IN (select parts_id FROM makemodel WHERE barcode = $2)
               AND NOT EXISTS (select id from parts
                                where partnumber = $2 AND NOT obsolete
            ))
            and (i.transdate is null or i.transdate <= $3)
            AND (oi.transdate IS NULL OR oi.transdate <= $3)
   GROUP BY p.id, p.partnumber;
$$;

CREATE OR REPLACE FUNCTION inventory_adjust__save_line
(in_adjust_id int, in_parts_id int,
in_counted numeric, in_expected numeric, in_variance numeric)
RETURNS inventory_report_line
LANGUAGE SQL AS
$$
INSERT INTO inventory_report_line
       (adjust_id, parts_id, counted, expected, variance)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;
$$;

CREATE OR REPLACE FUNCTION inventory_adjust__save_info
(in_transdate date, in_source text)
RETURNS inventory_report
LANGUAGE SQL AS
$$
INSERT INTO inventory_report(transdate, source)
VALUES ($1, $2)
RETURNING *;
$$;

CREATE OR REPLACE FUNCTION inventory_adjust__approve(in_id int)
RETURNS inventory_report_line language plpgsql as
$$
DECLARE inv inventory_report;
        t_ar ar;
        t_ap ap;
BEGIN

SELECT * INTO inv FROM inventory_report where id = in_id;

INSERT INTO ar (entity_credit_account, invnumber, invoice, approved,
                amount, netamount, transdate)
VALUES (setting__get('inventory_ar_eca'), setting_increment('sinumber'),
        't', 'f', 0, 0, inv.transdate);

SELECT * INTO t_ar FROM ar WHERE id = currval('id');

UPDATE inventory_report
   set ar_trans_id = t_ar.id,
       ar_invnumber = t_ar.invnumber
 WHERE id = in_id;

INSERT INTO invoice (trans_id, parts_id, description, qty, sellprice, precision,
                    discount)
SELECT t_ar.id, p.id, p.description, l.variance * -1, p.sellprice, 3, 1
  FROM parts p
  JOIN inventory_report_line l ON p.id = l.parts_id
 WHERE l.adjust_id = in_id;

INSERT INTO ap (entity_credit_account, invnumber, invoice, approved, amount,
                netamount, transdate)
SELECT setting__get('inventory_ap_eca'), setting_increment('vinumber'),
       't', 'f', sum(l.variance * p.sellprice), sum(l.variance * p.sellprice),
       inv.transdate
  FROM parts p
  JOIN inventory_report_line l ON p.id = l.parts_id
 WHERE l.adjust_id = in_id;

SELECT * INTO t_ap FROM ap WHERE id = currval('id');

UPDATE inventory_report
   set ap_trans_id = t_ap.id,
       ap_invnumber = t_ap.invnumber
 WHERE id = in_id;

INSERT INTO invoice (trans_id, parts_id, description, qty, sellprice, precision,
                    discount, transdate)
SELECT t_ap.id, p.id, p.description, l.variance * -1, p.sellprice, 3, 0
  FROM parts p
  JOIN inventory_report_line l ON p.id = l.parts_id
 WHERE l.adjust_id = in_id;

INSERT INTO acc_trans (trans_id, chart_id, amount, transdate, approved)
SELECT t_ap.id, p.expense_accno_id, sum(l.variance * -1 * p.lastcost),
       inv.transdate, true
  FROM parts p
  JOIN inventory_report_line l ON p.id = l.parts_id
 WHERE l.adjust_id = in_id
 GROUP BY p.expense_accno_id
 UNION
SELECT t_ap.id, eca.ar_ap_accno_id, sum(l.variance * -1 * p.lastcost),
       inv.transdate, true
  FROM parts p
  JOIN inventory_report_line l ON p.id = l.parts_id
  JOIN entity_credit_account eca on eca_id = t_ap.entity_credit_account
 WHERE l.adjust_id = in_id
 GROUP BY eca.ar_ap_accno_id;

SELECT * INTO inv FROM inventory_report where id = in_id;

RETURN inv;

END;
$$;

CREATE OR REPLACE FUNCTION inventory_adjust__delete(in_id int)
RETURNS BOOL LANGUAGE PLPGSQL AS
$$
DECLARE inv inventory_report;
BEGIN
SELECT * INTO inv FROM inventory_report where id = in_id;
IF NOT FOUND THEN
   RETURN FALSE;
ELSIF inv.ap_trans_id IS NOT NULL OR inv.ar_trans_id IS NOT NULL THEN
   RAISE EXCEPTION 'Set is Already Approved!';
END IF;

DELETE FROM inventory_report_line where adjust_id = in_id;
DELETE FROM inventory_report where id = in_id;

RETURN TRUE;

END;
$$;

CREATE OR REPLACE FUNCTION inventory_adjust__list
(in_from_date date, in_to_date date, in_approved bool)
RETURNS SETOF inventory_report language sql as $$

SELECT * FROM inventory_report
 WHERE ($1 is null or transdate >= $1)
       AND ($2 IS NULL OR transdate <= $2)
       AND ($3 IS NULL OR $3 = (ar_trans_id IS NULL AND ap_trans_id IS NULL));

$$;

DROP FUNCTION IF EXISTS inventory_adjust__get(in_id int);
CREATE OR REPLACE FUNCTION inventory_adjust__get(in_id int)
RETURNS inventory_report -- only 0-1....
LANGUAGE SQL AS
$$
SELECT * FROM inventory_report WHERE id = $1;
$$;

CREATE OR REPLACE FUNCTION inventory_adjust__get_lines(in_id int)
RETURNS SETOF inventory_report_line LANGUAGE SQL AS
$$
SELECT * FROM inventory_report_line l WHERE adjust_id = $1
 ORDER BY parts_id;
$$;

CREATE OR REPLACE FUNCTION warehouse__list()
RETURNS SETOF warehouse
LANGUAGE SQL AS
$$
SELECT * FROM warehouse ORDER BY DESCRIPTION;
$$;

drop type if exists parts_history_result cascade;
CREATE TYPE parts_history_result AS (
id int,
partnumber text,
transdate date,
description text,
bin text,
ord_id int,
ordnumber text,
ordtype text,
meta_number text,
name text,
sellprice numeric,
qty numeric,
discount numeric,
serial_number text
);

CREATE OR REPLACE FUNCTION goods__history(
  in_date_from date, in_date_to date,
  in_partnumber text, in_description text, in_serial_number text,
  in_inc_po bool, in_inc_so bool, in_inc_quo bool, in_inc_rfq bool,
  in_inc_is bool, in_inc_ir bool
) RETURNS SETOF parts_history_result LANGUAGE SQL AS
$$
  SELECT p.id, p.partnumber, o.transdate, p.description, p.bin,
         o.id as ord_id, o.ordnumber, o.oe_class, eca.meta_number::text, e.name,
         i.sellprice, i.qty, i.discount, i.serialnumber
    FROM parts p
    JOIN (select id, trans_id, parts_id, sellprice, qty, discount, serialnumber,
                 'o' as i_type
            FROM orderitems
           UNION
          SELECT id, trans_id, parts_id, sellprice, qty, discount, serialnumber,
                 'i' as i_type
            FROM invoice) i ON p.id = i.parts_id
    JOIN (select o.id, 'oe' as o_table, ordnumber as ordnumber, c.oe_class,
                 o.oe_class_id, o.transdate, o.entity_credit_account
            FROM oe o
            JOIN oe_class c ON o.oe_class_id = c.id
           UNION
          SELECT id, 'ar' as o_table, invnumber as ordnumber, 'is' as oe_class,
                 null, transdate, entity_credit_account
            FROM ar
           UNION
          SELECT id, 'ap' as o_table, invnumber as ordnumber, 'ir' as oe_class,
                 null, transdate, entity_credit_account
            FROM ap) o ON o.id = i.trans_id
                          AND (o_table = 'oe') = (i_type = 'o')
    JOIN entity_credit_account eca ON o.entity_credit_account = eca.id
    JOIN entity e ON e.id = eca.entity_id
   WHERE (in_partnumber is null or p.partnumber like in_partnumber || '%')
         AND (in_description IS NULL
              OR p.description @@ plainto_tsquery(in_description))
         AND (in_date_from is null or in_date_from <= o.transdate)
         and (in_date_to is null or in_date_to >= o.transdate)
         AND (in_inc_po is not true or o.oe_class = 'Purchase Order')
         AND (in_inc_so is not true or o.oe_class = 'Sales Order')
         AND (in_inc_quo is not true or o.oe_class = 'Quotation')
         AND (in_inc_rfq is not true or o.oe_class = 'RFQ')
         AND (in_inc_ir is not true or o.oe_class = 'ir')
         AND (in_inc_is is not true or o.oe_class = 'is')
ORDER BY o.transdate desc, o.id desc;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
