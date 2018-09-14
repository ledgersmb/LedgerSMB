

DO  language plpgsql $migrate$
DECLARE
  prev_set boolean;
  prev record;
  line record;
  lines CURSOR FOR
     SELECT acc.*
       FROM acc_trans acc
      WHERE EXISTS (SELECT 1 FROM acc_trans exi
                     WHERE fx_transaction AND acc.trans_id = exi.trans_id)
     ORDER BY entry_id
     FOR UPDATE;
  fx_accnos int[];
BEGIN
  prev_set := false;

  -- Make sure all currencies to be migrated are in the 'currency' table
  INSERT INTO currency (curr, description)
  SELECT DISTINCT curr, curr
    FROM ar
   WHERE NOT EXISTS (SELECT 1 FROM currency c WHERE ar.curr = c.curr)
         AND curr IS NOT NULL;

  INSERT INTO currency (curr, description)
  SELECT DISTINCT curr, curr
    FROM ap
   WHERE NOT EXISTS (SELECT 1 FROM currency c WHERE ap.curr = c.curr)
         AND curr IS NOT NULL;


  -- FX accounts get special treatment due to their role in
  -- AR/AP FX results and how those are recorded in 'acc_trans'
  -- (that is: with the wrong 'fx_transaction' flag)
  SELECT array_agg(value::int)::int[] INTO fx_accnos
    FROM defaults
   WHERE setting_key IN ('fxgain_accno_id', 'fxloss_accno_id');

  CREATE TEMPORARY TABLE lines_to_delete (id int);

  FOR line IN lines
  LOOP
     -- start by considering the fx_accnos: if we'd start filling
     -- the 'prev' buffer, we risk skipping the fx_accnos line,
     -- when that comes as the first line (and since there's only
     -- one of those, it will never match the 'prev' criterion)
     IF line.chart_id = ANY(fx_accnos) THEN
        UPDATE acc_trans
           SET amount_bc = amount,
               amount_tc = 0,
               curr = (select curr from ar where ar.id = acc_trans.trans_id
                       union all
                       select curr from ap where ap.id = acc_trans.trans_id)
         WHERE CURRENT OF lines;

         prev_set := false;
         CONTINUE;
     END IF;

     -- In case the 'prev' buffer isn't set, we have nothing to compare
     -- with, so, fill the buffer and continue with the next line.
     IF NOT prev_set THEN
        prev := line;
        prev_set := true;
        CONTINUE;
     END IF;

     IF prev.trans_id = line.trans_id
          AND prev.chart_id = line.chart_id
          AND prev.transdate = line.transdate
          -- deliberately skipped 'amount'
          AND ((prev.source is null and line.source is null)
               OR prev.source = line.source)
          AND ((prev.cleared is null and line.cleared is null)
               OR prev.cleared = line.cleared)
          AND (NOT coalesce(prev.fx_transaction, false)) =
              coalesce(line.fx_transaction, false)
          AND ((prev.memo is null and line.memo is null)
               OR prev.memo = line.memo)
          AND ((prev.invoice_id is null and line.invoice_id is null)
               OR prev.invoice_id = line.invoice_id)
          AND ((prev.approved is null and line.approved is null)
               OR prev.approved = line.approved)
          AND ((prev.cleared_on is null and line.cleared_on is null)
               OR prev.cleared_on = line.cleared_on)
          AND ((prev.reconciled_on is null and line.reconciled_on is null)
               OR prev.reconciled_on = line.reconciled_on)
          AND ((prev.voucher_id is null and line.voucher_id is null)
               OR prev.voucher_id = line.voucher_id)
          AND (prev.entry_id + 1) = line.entry_id THEN

        -- before potentially switching them around (loosing track of
        -- what the 'trans_id' value of the current record is), we need
        -- to make sure to remove the 'prev' line, because we'll
        -- *update* the current line (which we absolutely *don't*
        -- want to delete
        INSERT INTO lines_to_delete (id) VALUES (prev.entry_id);

        IF prev.fx_transaction THEN
           DECLARE
              temp record;
           BEGIN
              temp := prev;
              prev := line;
              line := temp;
           END;
        END IF;

        UPDATE acc_trans
           SET amount_tc = prev.amount,
               amount_bc = prev.amount + line.amount,
               curr = (select curr from ar where ar.id = acc_trans.trans_id
                       union all
                       select curr from ap where ap.id = acc_trans.trans_id)
         WHERE CURRENT OF lines;

        -- Since we consumed both this line and the 'prev' buffer,
        -- consider the 'prev' buffer to be empty
        prev_set := false;
     ELSE
        prev := line;
     END IF;
  END LOOP;

  DELETE FROM payment_links
   WHERE EXISTS (SELECT 1 FROM lines_to_delete
                  WHERE lines_to_delete.id = payment_links.entry_id);

  DELETE FROM acc_trans
   WHERE EXISTS (SELECT 1 FROM lines_to_delete
                  WHERE lines_to_delete.id = acc_trans.entry_id);

  UPDATE acc_trans
     SET amount_bc = amount,
         amount_tc = amount,
         curr = (select curr from ar where acc_trans.trans_id = ar.id)
   WHERE EXISTS (select 1 from ar where acc_trans.trans_id = ar.id)
         AND amount_bc IS NULL;


  UPDATE acc_trans
     SET amount_bc = amount,
         amount_tc = amount,
         curr = (select curr from ap where acc_trans.trans_id = ap.id)
   WHERE EXISTS (select 1 from ap where acc_trans.trans_id = ap.id)
         AND amount_bc IS NULL;

  -- since there's no currency stored with GL transactions,
  -- users will need to manually edit any GL transactions where one of
  -- the lines has an fx_transaction flag set.
  -- I seriously hope nobody ever did that!
  -- Nonetheless, we'll provide infrastructure to untangle the mess.
  UPDATE acc_trans
     SET amount_bc = amount,
         amount_tc = amount,
         curr = (select value from defaults where setting_key = 'curr')
   WHERE NOT EXISTS (select 1 from gl
                      where acc_trans.trans_id = gl.id
                            and fx_transaction)
         AND amount_bc IS NULL;


END;
$migrate$;

