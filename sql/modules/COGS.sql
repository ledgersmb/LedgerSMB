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
RETURNS NUMERIC AS
$$
DECLARE t_alloc numeric := 0;
        t_cogs := 0;
        t_inv invoice;
BEGIN

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN ap a ON a.id = i.trans_id
     WHERE qty + allocated < 0
  ORDER BY a.transdate DESC, a.id DESC, i.id DESC
LOOP
   IF t_alloc > qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       RETURN t_cogs;
   ELSIF (in_qty - t_alloc) <= -1 * (t.qty + t_inv.allocated) THEN
       UPDATE invoice SET allocated = allocated - (in_qty - t_alloc)
        WHERE id = t_inv.id;
       t_cogs := t_cogs + (in_qty - t_alloc) * t_inv.sellprice;
       return t_cogs;
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
but rather returns it to the application to save.$$;

CREATE OR REPLACE FUNCTION cogs__add_for_ar(in_parts_id int, in_qty numeric)
returns numeric AS 
$$
DECLARE t_alloc numeric := 0;
        t_cogs numeric := 0;
        t_inv invoice;
BEGIN

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN ap a ON a.id = i.trans_id
     WHERE qty + allocated < 0
  ORDER BY a.transdate, a.id, i.id
LOOP
   IF t_alloc > qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return t_cogs;
   ELSIF (in_qty - t_alloc) <= -1 * (t_inv.qty + t_inv.allocated) THEN
       UPDATE invoice SET allocated = allocated + (in_qty - t_alloc)
        WHERE id = t_inv.id;
       t_cogs := t_cogs + (in_qty - t_alloc) * t_inv.sellprice;
       return t_cogs;
   ELSE
       UPDATE invoice SET allocated = qty * -1
        WHERE id = t_inv.id;
       t_cogs := t_cogs + -1 * (t_inv.qty + t_inv.allocated) * t_inv.sellprice;
       t_alloc := t_alloc + -1 + (t_inv.qty + t_inv.allocated);
   END IF;
END LOOP;

END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION cogs__add_for_ar(in_parts_id int, in_qty numeric) IS
$$ This function accepts a parts_id and a quantity, and iterates through AP 
records in order, calculating COGS on a FIFO basis and returning it to the 
application to attach to the current transaction.$$;

CREATE OR REPLACE FUNCTION cogs__reverse_ap
(in_parts_id int, in_qty numeric) AS
$$
DECLARE t_alloc numeric;
        t_inv inventory;
BEGIN

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN ap a ON a.id = i.trans_id
     WHERE allocated > 0
  ORDER BY a.transdate, a.id, i.id
LOOP
   IF t_alloc > qty THEN
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
        t_inv inventory;
        t_cp account_checkpoint;
BEGIN

IF in_qty < 0 THEN
   return cogs__reverse_ap(in_parts_id, in_qty * -1) * in_lastcost;
END IF;

SELECT * INTO t_cp FROM account_checkpoint ORDER BY end_date LIMIT 1;

FOR t_inv IN
    SELECT i.*
      FROM invoice i
      JOIN ar a ON a.id = i.trans_id
     WHERE qty + allocated > 0
  ORDER BY a.transdate, a.id, i.id
LOOP

   IF t_alloc > qty THEN
       RAISE EXCEPTION 'TOO MANY ALLOCATED';
   ELSIF t_alloc = in_qty THEN
       return t_cogs;
   ELSIF (in_qty - t_alloc) <= (t_inv.qty + t_inv.allocated) THEN
       UPDATE invoice SET allocated = allocated + (in_qty - t_alloc)
        WHERE id = t_inv.id;

       INSERT INTO acc_trans 
              (chart_id, transdate, amount, invoice, approved, project_id)
       SELECT expense_accno_id, 
              CASE WHEN t_inv.transdate > t_cp.end_date THEN t_inv.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END, -1 * (in_qty - t_alloc) * in_lastcost, t_inv.id, true, 
              t_inv.project_id
         FROM parts 
       WHERE  parts_id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL
       UNION
       SELECT income_accno_id,
              CASE WHEN t_inv.transdate > t_cp.end_date THEN t_inv.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END, (in_qty - t_alloc) * in_lastcost, t_inv.id, true,
              t_inv.project_id
         FROM parts 
       WHERE  parts_id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL;
                                    
       t_cogs := t_cogs + (in_qty - t_alloc) * in_lastcost;
       return t_cogs;
   ELSE
       UPDATE invoice SET allocated = qty
        WHERE id = t_inv.id;
       t_cogs := t_cogs + (t_inv.qty + t_inv.allocated) * in_lastcost;

       
       INSERT INTO acc_trans
              (chart_id, transdate, amount, invoice, approved, project_id)
       SELECT expense_accno_id,
              CASE WHEN t_inv.transdate > t_cp.end_date THEN t_inv.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END, -1 * (t_inv.qty + t_inv.allocated) * in_lastcost, 
              t_inv.id, true, t_inv.project_id
         FROM parts
       WHERE  parts_id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL
       UNION
       SELECT income_accno_id,
              CASE WHEN t_inv.transdate > t_cp.end_date THEN t_inv.transdate
                   ELSE t_cp.end_date + '1 day'::interval
               END, (t_inv.qty + t_inv.allocated) * in_lastcost, t_inv.id, true,
              t_inv.project_id
         FROM parts
       WHERE  parts_id = t_inv.parts_id AND inventory_accno_id IS NOT NULL
              AND expense_accno_id IS NOT NULL;

   END IF;


END LOOP;

END;
$$ LANGUAGE PLPGSQL;

COMMIT;
