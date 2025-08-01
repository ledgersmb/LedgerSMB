
set client_min_messages = 'warning';


-- COGS routines for LedgerSMB 1.4.
-- This file is licensed under the terms of the GNU General Public License
-- Version 2 or at your option any later version.

-- This module implements FIFO COGS.  One could use it as a template to provide
-- other forms of inventory valuation as well.  With FIFO valuation, the best
-- way I can see this is to suggest that all reversals only affect the AP rows,
-- but all COGS amounts get posted to AR rows.  This means that AR rows do not
-- save the data here, but the AP transaction cogs calcuation alone( does) add to
-- AR rows.


/*

# Data structure

Each purchase or sale records inventory change in the `invoice` table. Returns
and reversals are recorded too. The number of items involved is recorded in
the `qty` column. The `qty` columns holds positive values for sales (and
purchase reversals) and negative values for purchases (and sales returns and
reversals). Effective purchase and sales prices are recorded in the
`sellprice` column.

In FIFO COGS calculation, each item bought will be assigned to a sale,
resulting in the COGS expense amount for the sale. Whether or not an item
has been used for COGS expenses is tracked in the `allocated` column in the
`invoice` table. It has an opposite sign of the `qty` of the record. Allocation
is both tracked on the purchase and on the sale side: it's possible that
sales are recorded (and invoiced) where the items on the invoice are placed
in back-order. This is modelled by a sales `invoice` record with 0 (zero)
`allocated` field. In this case, there is no inventory to allocate to the sale,
meaning that COGS calculation will be delayed until the back-ordered items are
received -- at which time the COGS are retro-actively calculated and posted.


# FIFO process

The regular process to process for the FIFO inventory is to keep a list of
all items added to inventory, adding to the end of the list upon purchase
and taking from the front on sales.

In case of reversals and returns (of sales), these are returned to the front
of the list. In case of reversals and returns (of purchases), these are taken
from the end of the list.


*/


BEGIN;



CREATE OR REPLACE FUNCTION cogs__reverse_ar(in_parts_id int, in_qty numeric)
RETURNS NUMERIC[] AS
$$
DECLARE t_alloc numeric := 0; -- qty to reverse (negative)
        t_cogs numeric := 0;
        t_inv invoice;
        t_reversed numeric;
        t_reallocated numeric;
BEGIN

IF in_qty = 0 THEN
   RETURN ARRAY[0, 0];
END IF;

-- First satisfy invoices in back-order
FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (SELECT id, approved, transdate FROM ar
            UNION
            SELECT id, approved, transdate FROM gl) a ON a.id = i.trans_id
     WHERE qty + allocated > 0 and a.approved and parts_id = in_parts_id
   ORDER BY a.transdate ASC, a.id ASC, i.id ASC
LOOP
   t_reallocated := least(t_alloc - in_qty, t_inv.qty + t_inv.allocated);
   UPDATE invoice
      SET allocated = allocated - t_reallocated
    WHERE id = t_inv.id;
   t_alloc := t_alloc - t_reallocated;

   IF t_alloc < in_qty THEN
      RAISE EXCEPTION 'TOO MANY ALLOCATED (1)';
   ELSIF t_alloc = in_qty THEN
      RETURN ARRAY[t_alloc, 0];
   END IF;
END LOOP;

-- No (more) invoices in back-order?
-- * Reverse allocation from AP invoices
FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (select id, approved, transdate from ap
            union
            select id, approved, transdate from gl) a ON a.id = i.trans_id
     WHERE allocated > 0 and a.approved and parts_id = in_parts_id
           -- the sellprice check is here because of github issue #4791:
           -- when a negative number of assemblies has been "stocked",
           -- reversal of a sales invoice for that part, fails.
           and sellprice is not null
  ORDER BY a.transdate DESC, a.id DESC, i.id DESC
LOOP
   t_reversed := least((in_qty - t_alloc) * -1, t_inv.allocated);
   UPDATE invoice SET allocated = allocated - t_reversed
    WHERE id = t_inv.id;
   t_cogs := t_cogs - t_reversed * t_inv.sellprice;
   t_alloc := t_alloc - t_reversed;

   IF t_alloc < in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       RETURN ARRAY[t_alloc, t_cogs];
   END IF;
END LOOP;

RAISE EXCEPTION 'TOO FEW TO ALLOCATE';
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION cogs__reverse_ar(in_parts_id int, in_qty numeric) IS
$$This function accepts a part id and quantity to reverse.  It then iterates
backwards over AP related records, calculating COGS.  This does not save COGS
but rather returns it to the application to save. It does however, modify the
`invoice` records.

Return values are an array of {allocated, cogs}.
$$;

CREATE OR REPLACE FUNCTION cogs__add_for_ar(in_parts_id int, in_qty numeric)
returns numeric[] AS
$$
DECLARE t_alloc numeric := 0;
        t_cogs numeric := 0;
        t_inv invoice;
        t_avail numeric;
BEGIN


FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (select id, approved, transdate from ap
             union
            select id, approved, transdate from gl) a ON a.id = i.trans_id
     WHERE qty + allocated < 0 AND i.parts_id = in_parts_id AND a.approved
  ORDER BY a.transdate asc, a.id asc, i.id asc
LOOP
   t_avail := (t_inv.qty + t_inv.allocated) * -1;
   IF t_alloc > in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return ARRAY[t_alloc, t_cogs];
   ELSIF (in_qty - t_alloc) <= t_avail THEN
       UPDATE invoice SET allocated = allocated + (in_qty - t_alloc)
        WHERE id = t_inv.id;
       t_cogs := t_cogs + (in_qty - t_alloc) * t_inv.sellprice;
       t_alloc := in_qty;
       return ARRAY[t_alloc, t_cogs];
   ELSE
       UPDATE invoice SET allocated = qty * -1
        WHERE id = t_inv.id;
       t_cogs := t_cogs + (t_avail * t_inv.sellprice);
       t_alloc := t_alloc + t_avail;
   END IF;
END LOOP;

RETURN ARRAY[t_alloc, t_cogs];

END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION cogs__add_for_ar(in_parts_id int, in_qty numeric) IS
$$ This function accepts a parts_id and a quantity, and iterates through AP
records in order, calculating COGS on a FIFO basis and returning it to the
application to attach to the current transaction. Modifies the `invoice`
records `allocated` values.

Return values are an array of {allocated, cogs}.
$$;

CREATE OR REPLACE FUNCTION cogs__reverse_ap
(in_parts_id int, in_qty numeric) RETURNS numeric[] AS
$$
DECLARE t_alloc numeric :=0;
        t_realloc numeric;
        t_reversed numeric;
        t_inv invoice;
        t_cogs numeric :=0;
        retval numeric[];
BEGIN

-- Move allocation to other purchase lines
FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (select id, approved, transdate from ap
             union
            select id, approved, transdate from gl) a
           ON a.id = i.trans_id
     WHERE qty + allocated < 0 AND parts_id = in_parts_id AND a.approved
  ORDER BY a.transdate, a.id, i.id
LOOP
   t_realloc := least(in_qty - t_alloc, -1 * (t_inv.allocated + t_inv.qty));
   UPDATE invoice SET allocated = allocated + t_realloc
    WHERE id = t_inv.id;
   t_alloc := t_alloc + t_realloc;
   t_cogs := t_cogs + t_realloc * t_inv.sellprice;

   IF t_alloc > in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return ARRAY[-1 * t_alloc, t_cogs];
   END IF;
END LOOP;

-- No more items in stock to move allocation to?
-- * Put AR invoices in back-order
FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (select id, approved, transdate from ar
            union
            select id, approved, transdate from gl) a ON a.id = i.trans_id
     WHERE allocated < 0 and a.approved and parts_id = in_parts_id
  ORDER BY a.transdate, a.id, i.id
LOOP
   t_reversed := least(in_qty - t_alloc, -1 * t_inv.allocated);
   UPDATE invoice SET allocated = allocated + t_reversed
    WHERE id = t_inv.id;
   t_alloc := t_alloc + t_reversed;

   IF t_alloc > in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       RETURN ARRAY[-1 * t_alloc, t_cogs];
   END IF;
END LOOP;


RAISE EXCEPTION 'TOO FEW TO ALLOCATE';
END;
$$ LANGUAGE PLPGSQL;


COMMENT ON FUNCTION cogs__reverse_ap (in_parts_id int, in_qty numeric) IS
$$ This function iterates through invoice rows attached to ap transactions and
allocates to them on a first-in first-out basis.  The sort of pseudo-"COGS"
value is returned to the application for further handling.$$;

-- Not concerned about performance on the function below.  It is possible that
-- large AP purchases which add COGS to a lot of AR transactions could pose
-- perforance problems but this is a rare case and so we can worry about tuning
-- that if someone actually needs it.  --CT

CREATE OR REPLACE FUNCTION cogs__add_for_ap
(in_parts_id int, in_qty numeric, in_lastcost numeric, in_transdate date default null)
returns numeric AS
$$
DECLARE t_alloc numeric := 0;
        t_cogs numeric := 0;
        t_inv invoice;
        t_cp_end_date date;
        t_transdate date;
        t_avail numeric;
BEGIN

IF in_qty > 0 THEN
   return (cogs__reverse_ap(in_parts_id, in_qty * -1))[1] * in_lastcost;
END IF;

SELECT end_date INTO t_cp_end_date FROM account_checkpoint ORDER BY end_date DESC LIMIT 1;

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (select id, approved, transdate from ar
             union
            select id, approved, transdate from gl) a
           ON a.id = i.trans_id AND a.approved
     WHERE qty + allocated > 0 and parts_id  = in_parts_id
  ORDER BY a.transdate, a.id, i.id
LOOP
   t_avail := t_inv.qty + t_inv.allocated;
   SELECT coalesce(in_transdate, transdate) INTO t_transdate FROM transactions
    WHERE id = t_inv.trans_id;
   IF t_alloc < in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return t_alloc;
   ELSIF (in_qty + t_alloc) * -1 <=  t_avail  THEN
       UPDATE invoice SET allocated = allocated + (in_qty + t_alloc)
        WHERE id = t_inv.id;

       INSERT INTO acc_trans
              (chart_id, transdate, amount_bc, curr, amount_tc, invoice_id, approved, trans_id)
       SELECT expense_accno_id,
              CASE WHEN t_transdate > coalesce(t_cp_end_date, t_transdate - 1)
                   THEN t_transdate
                   ELSE t_cp_end_date + '1 day'::interval
               END,
               (in_qty + t_alloc) * in_lastcost,
               defaults_get_defaultcurrency(),
               (in_qty + t_alloc) * in_lastcost,
               t_inv.id, true,
              t_inv.trans_id
         FROM parts
       WHERE  id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL
       UNION
       SELECT inventory_accno_id,
              CASE WHEN t_transdate > coalesce(t_cp_end_date, t_transdate - 1)
                   THEN t_transdate
                   ELSE t_cp_end_date + '1 day'::interval
               END,
               -1*(in_qty + t_alloc) * in_lastcost,
               defaults_get_defaultcurrency(),
               -1*(in_qty + t_alloc) * in_lastcost,
               t_inv.id, true,
              t_inv.trans_id
         FROM parts
       WHERE  id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL;

       t_cogs := t_cogs + (in_qty + t_alloc) * in_lastcost;
       return in_qty * -1;
   ELSE
       UPDATE invoice SET allocated = qty * -1
        WHERE id = t_inv.id;
       t_cogs := t_cogs + t_avail * in_lastcost;

       INSERT INTO acc_trans
              (chart_id, transdate, amount_bc, curr, amount_tc, invoice_id, approved, trans_id)
       SELECT expense_accno_id,
              CASE WHEN t_transdate > coalesce(t_cp_end_date, t_transdate - 1)
                   THEN t_transdate
                   ELSE t_cp_end_date + '1 day'::interval
               END,
               -1*t_avail * in_lastcost,
               defaults_get_defaultcurrency(),
               -1*t_avail * in_lastcost,
              t_inv.id, true, t_inv.trans_id
         FROM parts
       WHERE  id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL
       UNION
       SELECT inventory_accno_id,
              CASE WHEN t_transdate > coalesce(t_cp_end_date, t_transdate - 1)
                   THEN t_transdate
                   ELSE t_cp_end_date + '1 day'::interval
               END,
               t_avail * in_lastcost,
               defaults_get_defaultcurrency(),
               t_avail * in_lastcost,
               t_inv.id, true, t_inv.trans_id
         FROM parts
       WHERE  id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL;
       t_alloc := t_alloc + t_avail;
       t_cogs := t_cogs + t_avail * in_lastcost;
   END IF;

END LOOP;

RETURN t_alloc;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION cogs__add_for_ar_line(in_invoice_id int)
RETURNS numeric AS
$$
DECLARE
   t_cogs numeric[];
   t_inv invoice;
   t_part parts;
   t_ar ar;
   t_transdate date;
   t_override_cogs int;
BEGIN

SELECT * INTO t_inv FROM invoice WHERE id = in_invoice_id;
SELECT * INTO t_part FROM parts WHERE id = t_inv.parts_id;
SELECT * INTO t_ar FROM ar WHERE id = t_inv.trans_id;
SELECT transdate INTO t_transdate FROM transactions WHERE id = t_inv.trans_id;

IF t_ar.is_return THEN
   t_override_cogs = (setting_get('ar_return_account_id')).value::int;
END IF;

IF t_part.inventory_accno_id IS NULL THEN
   RETURN 0;
END IF;

IF t_inv.qty + t_inv.allocated = 0 THEN
   return 0;
END IF;

IF t_inv.qty > 0 THEN
   t_cogs := cogs__add_for_ar(t_inv.parts_id, t_inv.qty + t_inv.allocated);
ELSE
   t_cogs := cogs__reverse_ar(t_inv.parts_id, t_inv.qty + t_inv.allocated);
END IF;


UPDATE invoice set allocated = allocated - t_cogs[1]
 WHERE id = in_invoice_id;

SELECT CASE WHEN t_transdate > coalesce(max(end_date), t_transdate - 1)
            THEN t_transdate
            ELSE max(end_date) + '1 day'::interval
        END
  INTO t_transdate
  from account_checkpoint td;


INSERT INTO acc_trans
       (trans_id, chart_id, approved, amount_bc,
        curr, amount_tc, transdate,  invoice_id)
VALUES (t_inv.trans_id, COALESCE(t_override_cogs,
                                 CASE WHEN t_inv.qty < 0 AND t_ar.is_return
                                      THEN t_part.returns_accno_id
                                      ELSE t_part.expense_accno_id
                                      END), TRUE, t_cogs[2] * -1,
        defaults_get_defaultcurrency(), t_cogs[2] * -1, t_transdate, t_inv.id),
       (t_inv.trans_id, t_part.inventory_accno_id, TRUE, t_cogs[2],
        defaults_get_defaultcurrency(), t_cogs[2], t_transdate, t_inv.id);

RETURN t_cogs[1];

END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION cogs__add_for_ap_line(in_invoice_id int,
                                                 in_transdate date default null)
RETURNS numeric AS
$$
DECLARE retval numeric;
        r_cogs numeric[];
        t_inv invoice;
        t_adj numeric;
        t_transdate date;
BEGIN

SELECT * INTO t_inv FROM invoice
 WHERE id = in_invoice_id;

IF t_inv.qty + t_inv.allocated = 0 THEN
   return 0;
END IF;

PERFORM 1 FROM parts
         WHERE t_inv.parts_id = parts.id
               AND parts.inventory_accno_id IS NOT NULL;

IF NOT FOUND THEN
   -- the part doesn't have an associated inventory account: it's a service.
   return 0;
END IF;

IF t_inv.qty < 0 THEN -- normal COGS

    SELECT cogs__add_for_ap(i.parts_id, i.qty + i.allocated, i.sellprice, in_transdate)
      INTO retval
      FROM invoice i
      JOIN parts p ON p.id = i.parts_id
     WHERE i.id = $1;

    UPDATE invoice
       SET allocated = allocated + retval
     WHERE id = $1;
ELSE -- reversal

   r_cogs := cogs__reverse_ap(t_inv.parts_id, t_inv.qty + t_inv.allocated);

   UPDATE invoice
      SET allocated = allocated + r_cogs[1]
    WHERE id = in_invoice_id;

   t_adj := t_inv.sellprice * r_cogs[1] + r_cogs[2];

   SELECT coalesce(in_transdate, transdate) INTO t_transdate FROM transactions
    WHERE id = t_inv.trans_id;

   INSERT INTO acc_trans
          (chart_id, trans_id, approved,  amount_bc, curr, amount_tc, transdate, invoice_id)
   SELECT p.inventory_accno_id, t_inv.trans_id, true, t_adj,
          defaults_get_defaultcurrency(), t_adj, t_transdate,
          in_invoice_id
     FROM parts p
    WHERE id = t_inv.parts_id
    UNION
   SELECT p.expense_accno_id, t_inv.trans_id, true, t_adj * -1,
          defaults_get_defaultcurrency(), t_adj * -1, t_transdate,
          in_invoice_id
     FROM parts p
    WHERE id = t_inv.parts_id;
   retval := r_cogs[1];

END IF;

RETURN retval;

END;

$$ LANGUAGE PLPGSQL;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
