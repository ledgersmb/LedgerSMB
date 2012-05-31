-- COGS routines for LedgerSMB 1.4.
-- This file is licensed under the terms of the GNU General Public License 
-- Version 2 or at your option any later version.

-- This module implements FIFO COGS.  One could use it as a template to provide
-- other forms of inventory valuation as well.  With FIFO valuation, the best 
-- way I can see this is to suggest that all reversals only affect the AP rows,
-- but all COGS amounts get posted to AR rows.  This means that AR rows do not
-- save the data here, but the AP transaction cogs calcuation alone does add to
-- AR rows.


BEGIN;



CREATE OR REPLACE FUNCTION cogs__reverse_ar(in_parts_id int, in_qty numeric)
RETURNS NUMERIC[] AS
$$
DECLARE t_alloc numeric := 0;
        t_cogs numeric := 0;
        t_inv invoice;
BEGIN

RAISE NOTICE 'reversing ar';
FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (select id, approved, transdate from ap 
            union
            select id, approved, transdate from gl) a ON a.id = i.trans_id
     WHERE qty + allocated < 0 and a.approved
  ORDER BY a.transdate DESC, a.id DESC, i.id DESC
LOOP
   IF t_alloc > qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       RETURN ARRAY[t_alloc, t_cogs];
   ELSIF (in_qty - t_alloc) <= -1 * (t.qty + t_inv.allocated) THEN
       UPDATE invoice SET allocated = allocated - (in_qty - t_alloc)
        WHERE id = t_inv.id;
       t_cogs := t_cogs + (in_qty - t_alloc) * t_inv.sellprice;
       return ARRAY[t_alloc, t_cogs];
   ELSE
       UPDATE invoice SET allocated = 0
        WHERE id = t_inv.id;
       t_alloc := t_alloc + t_inv.allocated * -1;
       t_cogs := t_cogs + -1 * (t_inv.qty + t_inv.allocated) * t_inv.sellprice;
   END IF;
END LOOP;

RAISE EXCEPTION 'TOO FEW TO REVERSE';

END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION cogs__reverse_ar(in_parts_id int, in_qty numeric) IS 
$$This function accepts a part id and quantity to reverse.  It then iterates 
backwards over AP related records, calculating COGS.  This does not save COGS
but rather returns it to the application to save.

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

RAISE NOTICE 'adding for ar';

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN (select id, approved, transdate from ap
             union
            select id, approved, transdate from gl) a ON a.id = i.trans_id
     WHERE qty + allocated < 0 AND i.parts_id = in_parts_id
  ORDER BY a.transdate asc, a.id asc, i.id asc
LOOP
   t_avail := (t_inv.qty + t_inv.allocated) * -1;
   RAISE NOTICE 'id: %, qty: %, allocated: %, requested %, needed %, avail %, cogs so far %', 
                  t_inv.id, t_inv.qty, t_inv.allocated, in_qty, 
                  in_qty + t_alloc, t_avail, t_cogs;
   IF t_alloc > in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return ARRAY[t_alloc, t_cogs];
   ELSIF (in_qty + t_alloc) <= t_avail THEN
       RAISE NOTICE 'partial allocation: % @ % + %', in_qty - t_alloc, t_inv.sellprice, t_cogs;
       UPDATE invoice SET allocated = allocated + (in_qty - t_alloc)
        WHERE id = t_inv.id;
       t_cogs := t_cogs + (in_qty - t_alloc) * t_inv.sellprice;
       t_alloc := in_qty;
       RAISE NOTICE 'cogs %, allocated %, left %', t_cogs, t_alloc, in_qty - t_alloc;
       return ARRAY[t_alloc, t_cogs];
   ELSE
       RAISE NOTICE 'full allocation';
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
application to attach to the current transaction.

Return values are an array of {allocated, cogs}.
$$;

CREATE OR REPLACE FUNCTION cogs__reverse_ap
(in_parts_id int, in_qty numeric) RETURNS numeric AS
$$
DECLARE t_alloc numeric;
        t_inv invoice;
BEGIN

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN ap a ON a.id = i.trans_id
     WHERE allocated > 0
  ORDER BY a.transdate, a.id, i.id
LOOP
   IF t_alloc > in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return t_alloc;
   ELSIF (in_qty - t_alloc) <= -1 * (t_inv.qty + t_inv.allocated) THEN
       UPDATE invoice SET allocated = allocated + (in_qty - t_alloc)
        WHERE id = t_inv.id;
       return t_alloc;
   ELSE
       UPDATE invoice SET allocated = qty * -1
        WHERE id = t_inv.id;
   END IF;
END LOOP;

RETURN 0;

RAISE EXCEPTION 'TOO FEW TO ALLOCATE';
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION cogs__reverse_ap (in_parts_id int, in_qty numeric) IS
$$ This function iterates through invoice rows attached to ap transactions and 
allocates them on a first-in first-out basis.  The sort of pseudo-"COGS" value 
is returned to the application for further handling.$$;

-- Not concerned about performance on the function below.  It is possible that 
-- large AP purchases which add COGS to a lot of AR transactions could pose 
-- perforance problems but this is a rare case and so we can worry about tuning
-- that if someone actually needs it.  --CT

CREATE OR REPLACE FUNCTION cogs__add_for_ap
(in_parts_id int, in_qty numeric, in_lastcost numeric)
returns numeric AS
$$
DECLARE t_alloc numeric := 0;
        t_cogs numeric := 0;
        t_inv invoice;
        t_cp account_checkpoint;
        t_ar ar;
        t_avail numeric;
BEGIN


IF in_qty > 0 THEN
   return cogs__reverse_ap(in_parts_id, in_qty * -1) * in_lastcost;
END IF;

SELECT * INTO t_cp FROM account_checkpoint ORDER BY end_date DESC LIMIT 1;

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN ar a ON a.id = i.trans_id
     WHERE qty + allocated > 0 and parts_id  = in_parts_id
  ORDER BY a.transdate, a.id, i.id
LOOP
   t_avail := t_inv.qty + t_inv.allocated;
   SELECT * INTO t_ar FROM ar WHERE id = t_inv.trans_id;
   IF t_alloc < in_qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return t_alloc;
   ELSIF (in_qty + t_alloc) * -1 <=  t_avail  THEN
       UPDATE invoice SET allocated = allocated + (in_qty + t_alloc)
        WHERE id = t_inv.id;

       INSERT INTO acc_trans 
              (chart_id, transdate, amount, invoice_id, approved, trans_id)
       SELECT expense_accno_id, 
              CASE WHEN t_ar.transdate > t_cp.end_date THEN t_ar.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END, (in_qty + t_alloc) * in_lastcost, t_inv.id, true,
              t_inv.trans_id
         FROM parts 
       WHERE  id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL
       UNION
       SELECT income_accno_id,
              CASE WHEN t_ar.transdate > t_cp.end_date THEN t_ar.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END, -1 * (in_qty + t_alloc) * in_lastcost, t_inv.id, true,
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
              (chart_id, transdate, amount, invoice_id, approved, trans_id)
       SELECT expense_accno_id,
              CASE WHEN t_ar.transdate > t_cp.end_date THEN t_ar.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END,  -1 * t_avail * in_lastcost, 
              t_inv.id, true, t_inv.trans_id
         FROM parts
       WHERE  id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL
       UNION
       SELECT income_accno_id,
              CASE WHEN t_ar.transdate > t_cp.end_date THEN t_ar.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END, -t_avail * in_lastcost, t_inv.id, true, t_inv.trans_id
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
BEGIN

SELECT CASE WHEN qty > 0 THEN cogs__add_for_ar(parts_id, qty)
            ELSE cogs__reverse_ar(parts_id, qty)
       END
  INTO t_cogs 
  FROM invoice WHERE id = in_invoice_id;

RAISE NOTICE 'cogs function returned %', t_cogs;

UPDATE invoice set allocated = allocated - t_cogs[1]
 WHERE id = in_invoice_id;

SELECT * INTO t_inv FROM invoice WHERE id = in_invoice_id;
SELECT * INTO t_part FROM parts WHERE id = t_inv.parts_id;
SELECT * INTO t_ar FROM ar WHERE id = t_inv.trans_id;

SELECT CASE WHEN t_ar.transdate > max(end_date) THEN t_ar.transdate
            ELSE max(end_date) + '1 day'::interval
        END INTO t_transdate
  from account_checkpoint td; 
INSERT INTO acc_trans 
       (trans_id, chart_id, approved, amount, transdate,  invoice_id)
VALUES (t_inv.trans_id, CASE WHEN t_inv.qty < 0 AND t_ar.is_return 
                           THEN t_part.returns_accno_id
                           ELSE t_part.expense_accno_id
                      END, TRUE, t_cogs[2] * -1, t_transdate, t_inv.id),
       (t_inv.trans_id, t_part.inventory_accno_id, TRUE, t_cogs[2], 
       t_transdate, t_inv.id);

RETURN t_cogs[1];

END;

$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION cogs__add_for_ap_line(in_invoice_id int)
RETURNS numeric AS
$$

DECLARE retval numeric;

BEGIN

SELECT cogs__add_for_ap(i.parts_id, i.qty, i.sellprice) INTO retval
  FROM invoice i
  JOIN parts p ON p.id = i.parts_id
 WHERE i.id = $1;

UPDATE invoice 
   SET allocated = allocated + retval
 WHERE id = $1;


RETURN retval;

END;

$$ LANGUAGE PLPGSQL;

COMMIT;
