

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

  CREATE TEMPORARY TABLE lines_to_delete (id int, assoc int);

  FOR line IN lines
  LOOP
     -- start by considering the fx_accnos: if we'd start filling
     -- the 'prev' buffer, we risk skipping the fx_accnos line,
     -- when that comes as the first line (and since there's only
     -- one of those, it will never match the 'prev' criterion)
     IF line.chart_id = ANY(fx_accnos) THEN
        UPDATE acc_trans
           SET amount_bc = coalesce(amount,0),
               amount_tc = 0,
               curr = (select curr from ar where ar.id = acc_trans.trans_id
                       union all
                       select curr from ap where ap.id = acc_trans.trans_id
                       union all
                       select curr from gl where gl.id = acc_trans.trans_id)
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
        INSERT INTO lines_to_delete (id, assoc)
             VALUES (prev.entry_id, line.entry_id);

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
           SET amount_tc = coalesce(prev.amount, 0),
               amount_bc = coalesce(prev.amount, 0) + coalesce(line.amount, 0),
               curr = (select curr from ar where ar.id = acc_trans.trans_id
                       union all
                       select curr from ap where ap.id = acc_trans.trans_id
                       union all
                       select curr from gl where gl.id = acc_trans.trans_id)
         WHERE CURRENT OF lines;

        -- Since we consumed both this line and the 'prev' buffer,
        -- consider the 'prev' buffer to be empty
        prev_set := false;
     ELSE
        prev := line;
     END IF;
  END LOOP;

  -- Lines which are included in a reconciliation report obviously
  -- need to remain included. If only the line to be deleted is
  -- included, switch to the line which will remain in the database.
  -- If both lines are included, we can safely delete the reconciliation
  -- line, because the content has been merged into the one which remains
  UPDATE cr_report_line crl
     SET ledger_id = (select assoc from lines_to_delete ltd
                       where crl.ledger_id = ltd.id)
   WHERE EXISTS (select 1 from cr_report_line cl
                   join lines_to_delete ltd on ltd.id = cl.ledger_id)
         AND NOT EXISTS (select 1 from cr_report_line cl
                           join lines_to_delete ltd on cl.ledger_id = ltd.assoc);
  DELETE FROM cr_report_line crl
   WHERE EXISTS (select 1 from lines_to_delete ltd
                  where ltd.id = crl.ledger_id);

  -- Same reasoning above applies to 'ac_tax_form' (which links acc_trans
  -- lines to country_tax_form
  UPDATE ac_tax_form atf
     SET entry_id = (select assoc from lines_to_delete ltd
                      where atf.entry_id = ltd.id)
   WHERE EXISTS (select 1 from ac_tax_form tf
                   join lines_to_delete ltd on ltd.id = tf.entry_id)
         AND NOT EXISTS (select 1 from ac_tax_form tf
                           join lines_to_delete ltd on tf.entry_id = ltd.assoc);
  DELETE FROM ac_tax_form atf
   WHERE EXISTS (select 1 from lines_to_delete ltd
                  where ltd.id = atf.entry_id);


  -- Same reasoning above applies to 'business_unit_ac' (which links acc_trans
  -- lines to business accounting dimensions ('reporting units')
  UPDATE business_unit_ac bua
     SET entry_id = (select assoc from lines_to_delete ltd
                      where bua.entry_id = ltd.id)
   WHERE EXISTS (select 1 from business_unit_ac ua
                   join lines_to_delete ltd on ltd.id = ua.entry_id)
         AND NOT EXISTS (select 1 from business_unit_ac ua
                           join lines_to_delete ltd on ua.entry_id = ltd.assoc);
  DELETE FROM business_unit_ac bua
   WHERE EXISTS (select 1 from lines_to_delete ltd
                  where ltd.id = bua.entry_id);


  -- Same reasoning above applies to 'payment_links' (which links acc_trans
  -- lines to various types of payments
  UPDATE payment_links pal
     SET entry_id = (select assoc from lines_to_delete ltd
                      where pal.entry_id = ltd.id)
   WHERE EXISTS (select 1 from payment_links pl
                   join lines_to_delete ltd on ltd.id = pl.entry_id)
         AND NOT EXISTS (select 1 from payment_links pl
                           join lines_to_delete ltd on pl.entry_id = ltd.assoc);
  DELETE FROM payment_links pal
   WHERE EXISTS (select 1 from lines_to_delete ltd
                  where ltd.id = pal.entry_id);


  -- Same reasoning above applies to 'payment_links' (which links acc_trans
  -- lines to various types of payments
  UPDATE tax_extended tae
     SET entry_id = (select assoc from lines_to_delete ltd
                      where tae.entry_id = ltd.id)
   WHERE EXISTS (select 1 from tax_extended te
                   join lines_to_delete ltd on ltd.id = te.entry_id)
         AND NOT EXISTS (select 1 from tax_extended te
                           join lines_to_delete ltd on te.entry_id = ltd.assoc);
  DELETE FROM tax_extended tae
   WHERE EXISTS (select 1 from lines_to_delete ltd
                  where ltd.id = tae.entry_id);


  -- Same reasoning above applies to 'cr_report' (keeps records of the
  -- highest entry_id having been considered for the reconciliation)
  -- Except that the max_ac_id simply needs to be renumbered and that
  -- no cr_report lines need to be removed
  UPDATE cr_report crr
     SET max_ac_id = (select assoc from lines_to_delete ltd
                      where crr.max_ac_id = ltd.id)
   WHERE EXISTS (select 1 from cr_report cr
                   join lines_to_delete ltd on ltd.id = cr.max_ac_id);



  DELETE FROM payment_links
   WHERE EXISTS (SELECT 1 FROM lines_to_delete
                  WHERE lines_to_delete.id = payment_links.entry_id);

  DELETE FROM acc_trans
   WHERE EXISTS (SELECT 1 FROM lines_to_delete
                  WHERE lines_to_delete.id = acc_trans.entry_id);


  -- Update all lines which
  -- a. are not related to an fx transaction; or
  -- b. *are* related to an fx transaction, but haven't been matched and
  --    consolidated into a single line
  UPDATE acc_trans
     SET amount_bc = coalesce(amount, 0),
         amount_tc = case fx_transaction then 0 else coalesce(amount, 0) end,
         curr = (select curr from ar where acc_trans.trans_id = ar.id)
   WHERE EXISTS (select 1 from ar where acc_trans.trans_id = ar.id)
         AND amount_bc IS NULL;


  UPDATE acc_trans
     SET amount_bc = coalesce(amount, 0),
         amount_tc = case fx_transaction then 0 else coalesce(amount, 0) end,
         curr = (select curr from ap where acc_trans.trans_id = ap.id)
   WHERE EXISTS (select 1 from ap where acc_trans.trans_id = ap.id)
         AND amount_bc IS NULL;

  UPDATE acc_trans
     SET amount_bc = coalesce(amount, 0),
         amount_tc = case fx_transaction then 0 else coalesce(amount, 0) end,
         curr = (select curr from gl where gl.id = acc_trans.trans_id)
   WHERE EXISTS (select 1 from gl where acc_trans.trans_id = gl.id)
         AND amount_bc IS NULL;

END;
$migrate$;

