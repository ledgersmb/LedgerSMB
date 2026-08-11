
/*
 * The 1.8 upgrade created payment_link records for cases where the
 * pre-1.8 code base wouldn't have; by doing so, the bank reconciliation
 * did not have to contain pre-1.8 code, putting compatibility on one-off
 * migration code.
 *
 * One problem (which is the one we're solving here): the migration *only*
 * created payment_link records on cash accounts. The other half of the
 * payment wasn't identified (which wasn't necessary at the time).
 *
 * The code below closes the gap: it identifies the remainder of the
 * payment, which consists of a line on an AR/AP account and -for fx-
 * optionally a line on a gain/loss account.
 */

do $$
declare
  adjustments int;
  payment_issue record;
  default_curr text;
  fxgain_id integer;
  fxloss_id integer;
begin
  adjustments := 0;
  select value into default_curr
    from defaults
   where setting_key = 'curr';
  select value::integer into fxgain_id
    from defaults
   where setting_key = 'fxgain_accno_id';
  select value::integer into fxloss_id
    from defaults
   where setting_key = 'fxloss_accno_id';

  for payment_issue in
    select payment_id, trans_id, count(*), count(distinct chart_id), sum(amount_bc)
      from payment_links pl
             join acc_trans
                 using(entry_id)
     where pl.type <> 0
       and not exists (select 1
                         from payment_links pln
                        where pl.type = 2
                          and pln.payment_id = pl.payment_id)
     group by payment_id, trans_id
    having abs(sum(amount_bc))>0.005
     order by payment_id desc, trans_id desc
              loop
    declare
      payment_line record;
      aa_line record;
      fx_line_count integer;
    begin
      select * into payment_line
        from acc_trans ac
               join payment_links pl
                   using(entry_id)
       where trans_id = payment_issue.trans_id
         and payment_id = payment_issue.payment_id;

      raise notice 'Finding match for %', payment_line;

      <<transaction_lines>>
      for aa_line in
        select *
          from acc_trans ac
                 left join payment_links pl
                     using (entry_id)
         where trans_id = payment_issue.trans_id
           and payment_id is null -- don't use lines allocated to payments
           and exists (select 1
                         from account_link al
                        where al.description in ('AR', 'AP')
                          and al.account_id = ac.chart_id)
         order by (payment_line.transdate = ac.transdate) desc, ac.entry_id desc
        loop
        raise notice 'aa_line: %', aa_line;

        select count(*) into fx_line_count
          from acc_trans ac
                 left join payment_links pl
                     using (entry_id)
         where trans_id = payment_issue.trans_id
           and payment_id is null -- don't use lines allocated to payments
           and chart_id in (fxgain_id, fxloss_id);

        if aa_line.curr <> default_curr and fx_line_count > 0 then
          declare
            fx_line record;
          begin
            for fx_line in
              select *
                from acc_trans ac
                       left join payment_links pl
                           using (entry_id)
               where trans_id = payment_issue.trans_id
                 and payment_id is null -- don't use lines allocated to payments
                 and chart_id in (fxgain_id, fxloss_id)
               order by (payment_line.transdate = ac.transdate) desc, ac.entry_id desc
            loop
              if abs(payment_line.amount_bc + aa_line.amount_bc + fx_line.amount_bc) < 0.005 then
                raise notice 'inserting % % % %', payment_issue.payment_id, aa_line.entry_id, 1, aa_line.amount_bc;
                raise notice 'inserting (fx) % % % %', payment_issue.payment_id, fx_line.entry_id, 1, fx_line.amount_bc;
                adjustments := adjustments + 1;
                insert into payment_links (payment_id, entry_id, "type")
                values (payment_issue.payment_id, aa_line.entry_id, 1);
                insert into payment_links (payment_id, entry_id, "type")
                values (payment_issue.payment_id, fx_line.entry_id, 1);
                exit transaction_lines;
              end if;
            end loop;
          end;
        else
          if abs(payment_line.amount_bc + aa_line.amount_bc) < 0.005 then
            raise notice 'inserting % % % %', payment_issue.payment_id, aa_line.entry_id, 1, aa_line.amount_bc;
            adjustments := adjustments + 1;
            insert into payment_links (payment_id, entry_id, "type")
            values (payment_issue.payment_id, aa_line.entry_id, 1);
            exit transaction_lines;
          end if;
        end if;
      end loop;
    end;
  end loop;
end;

$$ language plpgsql;
