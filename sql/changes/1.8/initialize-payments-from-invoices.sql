
-- Reconciliation depends on payments data that pre-1.8 never generated
-- on payments entered in the invoice screen. 1.8 *does* generate those
-- payments; we're creating the payment records here as they would have
-- by 1.8, for unreconciled data only.


/* We'll create a table with all acc_trans lines
   which are not reconciled yet and are not part of a batch
   and that are related to payment accounts and belong to AR/AP transactions */

create temporary table need_payment as
select trans_id, transdate, entry_id, chart_id,
       amount_bc, amount_tc, curr
  from acc_trans a
 where not exists (select 1 from cr_report_line_links crll
                    where crll.entry_id = a.entry_id)
       and not exists (select 1 from payment_links pl
                        where pl.entry_id = a.entry_id)
       and (exists (select 1 from ar where ar.id = a.trans_id)
            or exists (select 1 from ap where ap.id = a.trans_id))
       and a.chart_id in (select id from account join account_link al
                              on account.id = al.account_id
                           where al.description in ('AR_paid', 'AP_paid'))
       and a.voucher_id is null;

create temporary table trans_arap_acc as
select distinct trans_id, chart_id
  from acc_trans a
 where exists (select 1 from need_payment np where a.trans_id = np.trans_id)
       and chart_id in (select id from account join account_link al
                            on account.id = al.account_id
                         where al.description in ('AR', 'AP'));

/* We need to generate a payment for each line in the 'needs_payment' table;
   we'll do that by finding an opposing amount in the AR/AP account from the
   one that's in the 'needs_payment' table, which is associated with the same
   day and the same trans_id *and* has not been used in a prior payment! */

/* By doing this in descending order, we're most likely to match the
   data in the order it was actually added to the database; using ascending
   order will likely attach the initial AR/AP account line (the 'opening line')
   to the payment instead of a later one which is more likely to be the actual
   payment... */

DO language plpgsql $gen_payments$
DECLARE
  t_row record;
BEGIN
  FOR t_row IN
  SELECT * FROM need_payment ORDER BY entry_id DESC
  LOOP
    DECLARE
      arap_entry_id int;
      arap_entry_amount_bc numeric;
      fx_entry_id int;
    BEGIN
      fx_entry_id := null;

      select entry_id, amount_bc into arap_entry_id, arap_entry_amount_bc
        from acc_trans a
       where a.trans_id = t_row.trans_id
             and a.amount_tc = -1*t_row.amount_tc
             and a.transdate = t_row.transdate
             and a.chart_id = (select chart_id from trans_arap_acc taa
                                where t_row.trans_id = taa.trans_id)
             and not exists (select 1 from payment_links pl
                              where pl.entry_id = a.entry_id)
      order by entry_id desc
      limit 1;

      if not found then
         continue; -- no matching payment amount found... skip this one.
      end if;

      if t_row.amount_bc + arap_entry_amount_bc <> 0 then
        -- ok, so we need to find an fx entry to balance the transaction...

        select entry_id into fx_entry_id
          from acc_trans a
         where a.trans_id = t_row.trans_id
               and a.amount_bc + t_row.amount_bc + arap_entry_amount_bc = 0
               and a.transdate = t_row.transdate
               and a.chart_id in (select "value"::int from defaults
                                   where setting_key in ('fxgain_accno_id',
                                                         'fxloss_accno_id'))
               and not exists (select 1 from payment_links pl
                                where pl.entry_id = a.entry_id)
        order by entry_id desc
        limit 1;

        if not found then
          continue; -- can't find a line which balances the payment...
        end if;
      end if;

      INSERT INTO payment (reference, payment_class, payment_date,
                           currency, notes, entity_credit_id)
        VALUES ( 'payment-migration-' || t_row.trans_id,
                 (select 2 from ar where ar.id = t_row.trans_id
                  union
                  select 1 from ap where ap.id = t_row.trans_id),
                 t_row.transdate,
                 t_row.curr,
                 'This payment was created by the automated migration procedure executed at ' || now(),
                 (select entity_credit_account from ar where ar.id = t_row.trans_id
                  union
                  select entity_credit_account from ap where ap.id = t_row.trans_id) );

      INSERT INTO payment_links (payment_id, entry_id, type)
        VALUES (currval('payment_id_seq'), t_row.entry_id, 1),
               (currval('payment_id_seq'), arap_entry_id, 1);

      IF fx_entry_id is not null THEN
        INSERT INTO payment_links (payment_id, entry_id, type)
          VALUES (currval('payment_id_seq'), t_row.entry_id, 1);
      END IF;

    END;
  END LOOP;
END;
$gen_payments$;

