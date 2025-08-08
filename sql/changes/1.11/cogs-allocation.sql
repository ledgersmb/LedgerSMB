/*
  This file contains a fix to be run when ./sql/consistency/00050-cogs-allocated-consistency.sql
  reports failed lines.
 */


create or replace function pg_temp.drop_ar_allocation(in_parts_id int, in_excess numeric)
  returns numeric language plpgsql as
  $$
  DECLARE
    t_inv RECORD;
    correction NUMERIC;
BEGIN
  IF in_excess = 0 THEN
    RETURN 0;
  END IF;

  FOR t_inv IN
    SELECT i.*
      FROM invoice i
           JOIN transactions t
                ON i.trans_id = t.id
     WHERE i.allocated <> 0
       AND i.qty > 0
       AND t.approved
     ORDER BY t.transdate DESC, i.id DESC
  LOOP
    -- AR 'allocated' numbers are negative!
    correction := GREATEST(t_inv.allocated, in_excess);
    UPDATE invoice
       SET allocated = t_inv.allocated - correction
     WHERE id = t_inv.id;

    in_excess := in_excess - correction;
    IF in_excess >= 0 THEN
      RETURN 0;
    END IF;
  END LOOP;
  RAISE WARNING 'Dropped all available ar allocation for part %; % remaining', in_parts_id, in_excess;
  RETURN -1;
END;
  $$;


create or replace function pg_temp.drop_ap_allocation(in_parts_id int, in_excess numeric)
  returns numeric language plpgsql as
  $$
  DECLARE
    t_inv RECORD;
    correction NUMERIC;
BEGIN
  IF in_excess = 0 THEN
    RETURN 0;
  END IF;

  FOR t_inv IN
    SELECT i.*
      FROM invoice i
           JOIN transactions t
                ON i.trans_id = t.id
     WHERE i.allocated <> 0
       AND i.qty < 0
       AND t.approved
     ORDER BY t.transdate DESC, i.id DESC
  LOOP
    -- AP 'allocated' numbers are positive!
    correction := LEAST(t_inv.allocated, in_excess);
    UPDATE invoice
       SET allocated = t_inv.allocated - correction
     WHERE id = t_inv.id;

    in_excess := in_excess - correction;
    IF in_excess <= 0 THEN
      RETURN 0;
    END IF;
  END LOOP;
  RAISE WARNING 'Dropped all available ap allocation for part %; % remaining', in_parts_id, in_excess;
  RETURN -1;
END;
  $$;


-- Start by fixing the cogs allocated amounts
CREATE TEMPORARY TABLE allocated_balances AS
  SELECT parts_id,
         sum(case when qty<0 then allocated else 0 end) as allocated_purchased,
         -1*sum(case when qty>0 then allocated else 0 end) as allocated_sold
    FROM invoice i
         JOIN transactions t
              ON i.trans_id = t.id
   WHERE t.approved
  GROUP BY parts_id;

-- Only store anything in this table if we're going to run the correction below
-- Copying the entire invoice table is a bit overkill, but then again, using
-- triggers is much more complex
CREATE TABLE invoice_before_cogs_allocation_fix AS
  SELECT *
    FROM invoice
   WHERE (select count(*)
            from allocated_balances
           where allocated_purchased <> allocated_sold) > 0;

SELECT CASE WHEN allocated_purchased > allocated_sold THEN pg_temp.drop_ap_allocation(parts_id, allocated_purchased - allocated_sold)
       ELSE pg_temp.drop_ar_allocation(parts_id, allocated_purchased - allocated_sold)
       END
  FROM allocated_balances
 WHERE allocated_purchased <> allocated_sold;

-- Delete the lines which were not changed
DELETE FROM invoice_before_cogs_allocation_fix ibf
 WHERE EXISTS (select 1
                 from invoice i
                where i.id = ibf.id
                  and i.allocated = ibf.allocated);

/*
  In the degenerate case, we need to allocate COGS. Envision a scenario where a sales invoice has
  been created at 450 units of a part, sold short (not in inventory). A purchase invoice is created
  at 300 units. The purchase invoice is saved twice, allocating 450 units to the sales invoice (this bug).
  This results in 150 units allocated in the purchase invoice and 150 unallocated.

  When the above runs, the allocation in the sales invoice is reduced to 150 to align the purchased and
  sold allocated balances, resulting in 300 units needing allocation in the sales invoice and 150 units
  available for allocation in the purchase invoice.

  Concluding: to fix COGS in this scenario, an adjustment of 150 units allocated to the sales invoice
  is required, consuming all purchased units (and leaving another 150 units to be purchased and allocated
  to the invoice at a later point in time).

  Similarly, envision a scenario where a purchase invoice has been created at 450 units of a part and a
  sales invoice has been created at 300 units. The sales invoice is saved twice, allocating 450 units in
  the purchase invoice (but only allocating 150 units of the sales invoice).

  When the above runs, the allocation in the purchase invoice is reduced to 150 to align the sold and
  purchased allocated balances, resulting in 150 units in the sales invoice needing allocation (with
  300 available from the purchase invoice).

  Concluding: to fix COGS in this scenario, an adjustment of 150 units allocated to the sales invoice
  is required, consuming 150 of the 300 available purchased units.


  Both scenarios leave the cost of purchased units available and in need of allocation to sales invoices.
  The routine cogs__add_for_ap_line() serves this purpose. For this COGS fix, we want a slightly different
  version: the regular version posts COGS at the transaction date of the invoice; here, we want it to post
  on "today" rather than the closest date possible to the posting date of the invoice.

 */

DO $$
BEGIN
  IF EXISTS (select 1 from invoice_before_cogs_allocation_fix) THEN
    INSERT INTO defaults (setting_key, "value")
       SELECT 'post-upgrade-run:cogs-allocation' AS setting_key,
              jsonb_build_object('action', 'cogs-allocation',
                                 'args', jsonb_build_object('parts_ids', jsonb_agg(parts_id)))
         FROM allocated_balances;

    INSERT INTO defaults (setting_key, "value")
    VALUES ('post-upgrade-run:cogs-allocation-cleanup',
            jsonb_build_object('action', 'cogs-allocation-cleanup',
                               'run-after', (CURRENT_DATE + '5 years'::interval)::date::text,
                               'args', null));

  ELSE
    DROP TABLE invoice_before_cogs_allocation_fix;

  END IF;
END;
$$ LANGUAGE plpgsql;

-- Drop routines which are updated with new function signatures in this fix
DROP FUNCTION IF EXISTS cogs__add_for_ap(
  in_parts_id int,
  in_qty numeric,
  in_lastcost numeric
);

DROP FUNCTION IF EXISTS cogs__add_for_ap_line(
  in_invoice_id int
);

