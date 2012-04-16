BEGIN;

CREATE OR REPLACE FUNCTION cogs__add_for_ar(in_parts_id int, in_qty numeric)
returns numeric AS 
$$
DECLARE t_alloc numeric := 0;
        t_cogs numeric := 0;
        t_inv invoice;
BEGIN

FOR t_inv IN
    SELECT * FROM invoice 
     WHERE trans_id IN (select id from ap)
           AND qty + allocated < 0;
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
   END IF;
END LOOP;

END;
$$ LANGUAGE PLPGSQL;

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

SELECT * INTO t_cp FROM account_checkpoint ORDER BY end_date LIMIT 1;

FOR t_inv IN
    SELECT * FROM invoice 
     WHERE trans_id IN (select id from ar)
           AND qty + allocated > 0;
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
