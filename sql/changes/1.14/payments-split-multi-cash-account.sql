
/*
  In the payments-first-order migration, each payment is linked to exactly
  one cash account. Historically, it was possible to record payments against
  multiple cash accounts in one payment. (Which is impossible, because it
  can never be a single transaction if it affects multiple accounts.
  The scope of this migration is restricted to 'single payments': the bulk
  payments functionality doesn't allow selection of multiple cash accounts
  in a single payment.

  Single payments generate pairs (or with fx triplets) of journal lines,
  one on the AR/AP line and one on the cash account (and fx gain/loss account).
  By grouping the pairs using their cash account, payments can be split
  without modifying or creating data.

  Complicating factors:
  1. Payment reversals
  2. Overpayments
  3. Mixtures of payments and overpayments
  4. payment_links.type = 0

  Payment reversals refer to the original payment they reverse. It's assumed
  that if payment reversals are being split, so is the original (and vice
  versa). Reversal records being split need to look up the payment id of the
  record being split based on the original payment_id and the cash account in
  the reversal (which should match the cash account in the original).

  Overpayments can be generated across multiple cash accounts just as regular
  payments. Overpayments don't re-use invoice 'trans_id' values, but have
  their own 'gl_id' (gl.id). Splitting needs to create a new GL transaction.
  Split payments need to refer to the correct new gl.id. There is an additional
  challenge because all overpayment journal lines belong to the same gl
  transaction and payment. Neither can be used as discriminating factor
  as they are with regular payments.
  Overpayments are posted with all journals in two groups: cash account journal
  lines and overpayment account journal lines grouped (*not* grouping per
  payment with journal lines alternating cash/overpayment accounts).


  Mixtures of payments and overpayments need to consider the case where
  overpayments are posted only on a subset of the cash accounts. In this case
  the GL transaction should only be duplicated for any split payments which
  include overpayments.

  Payment links type = 0 are used to register use of an overpayment (allocation
  to an invoice). Links of type = 0 should be moved to split payments, if they
  relate to an overpayment that is split. The 'entry_id' is the linking field.
 */

-- Add additional data integrity control to help assure correct
-- calculation and data generation below
alter table payment_links
  alter column payment_id set not null,
  alter column entry_id set not null;

--  Select payments with more than one cash account (AR_paid/AP_paid)
create temporary table payments_split as
  with filtered_links as (
  select pl.payment_id, ac.chart_id, ac.trans_id
    from payment_links pl
           join acc_trans ac using(entry_id)
           join account_link al on al.account_id = ac.chart_id
   where al.description in ('AR_paid', 'AP_paid')
  ),
  counted_payments as (
    select distinct gl_id, payment_id, chart_id, trans_id,
                    (select count(distinct chart_id)
                       from filtered_links fl2
                      where fl2.payment_id = fl.payment_id) as chart_count
      from filtered_links fl
             join payment p
                 on p.id = fl.payment_id
  )
  select payment_id as orig_payment_id, null::int as new_payment_id,
         gl_id as orig_gl_id, null::int as new_gl_id,
         chart_id, trans_id,
         dense_rank() over (partition by payment_id order by chart_id) as chart_seq,
         null::int gl_id_seq
    from counted_payments
   where chart_count > 1;



/*
  the query below groups overpayment rows into original payment rows and
  cash account sequences which need to be used to split the overpayments.

  the query needs to be integrated with the payments_split above and possibly
  needs to store entry_id values to be linked to cash_seq for moving the
  relevant journal lines into the correct new GL transactions
 */

create temporary table overpayments_split_entries as
  with enriched as (
    select ac.*, pl.payment_id, p.gl_id,
           exists (select 1
                     from account_link al
                    where description in ('AR_paid', 'AP_paid')
                      and al.account_id = ac.chart_id) as cash_account
      from acc_trans ac
             join payment_links pl
                 using(entry_id)
             join payment p
                 on p.id = pl.payment_id
     where pl.type <> 0
  ),
  grouped as (
    /*
      The *payment_group* answers the question which lines in a payment are
      debit/credit pairs. For regular payments the answer to this question
      is easy: they're split by the invoice they are allocated to. For
      overpayments, the answer isn't easy: nothing indicates the grouping.
      The solution here is that overpayments are posted as 2 groups of
      journal lines - cash accounts first and overpayment accounts second.
      By matching the first line of the first group with the first line of
      the second group, the 'payment_group' helps determine which lines need
      to be sorted into which overpayment transaction.

      The *gl_id_seq* answers the question to which gl transaction the lines
      of the overpayment need to be copied. As this field is generated per
      cash account, it's replicated to the overpayment account in the
      *payment_group_gl_id_seq* field.

      Please note that when a payment is a mixture of a regular payment and
      overpayment, the *gl_id_seq* needs not be the same as *chart_id_seq*:
      cash accounts used for regular payment but not for overpayment will
      cause these numbers to differ.
     */
    select payment_id, trans_id, chart_id, entry_id, amount_bc,
           cash_account, gl_id as orig_gl_id,
           dense_rank() over (partition by trans_id, cash_account
                              order by entry_id)
             as payment_group,
           case when cash_account and trans_id = gl_id
             then dense_rank() over (partition by trans_id, cash_account order by chart_id)
           else null
           end as gl_id_seq -- counts the number of different cash accounts involved in overpayment
      from enriched
  ),
  group_expanded as (
    select g.*, max(gl_id_seq) over (partition by trans_id, payment_group) as payment_group_gl_id_seq,
           max(chart_id) filter (where cash_account)
             over (partition by trans_id, payment_group) as payment_group_cash_chart_id
      from grouped g
  )
  select g.*, ps.chart_seq
  from group_expanded g
           join payments_split ps
               on g.trans_id = ps.trans_id
                   and g.payment_group_cash_chart_id = ps.chart_id
                   and g.payment_id = ps.orig_payment_id
  order by trans_id, payment_group, entry_id;


create temporary table overpayments_split as
  select payment_id, chart_id, trans_id, payment_group_gl_id_seq,
         case when payment_group_gl_id_seq > 1
                then nextval('id')
              when payment_group_gl_id_seq = 1
                then orig_gl_id
            else null
         end as new_gl_id
    from overpayments_split_entries
   where cash_account
     and payment_group_gl_id_seq is not null
  group by payment_id, orig_gl_id, chart_id, trans_id, payment_group_gl_id_seq;


create temporary table new_payments as
  select orig_payment_id, chart_seq, nextval('payment_id_seq') as new_id
    from payments_split
   where chart_seq > 1
   group by orig_payment_id, chart_seq
   order by orig_payment_id, chart_seq;


alter table gl
  disable trigger gl_prevent_closed;

insert into gl (
  id, reference, description,
  transdate, person_id, notes, approved,
  trans_type_code
  )
            overriding system value
select os.new_gl_id, gl.reference, gl.description,
       gl.transdate, gl.person_id, gl.notes, gl.approved,
       gl.trans_type_code
  from gl
         join overpayments_split os
             on gl.id = os.trans_id
 where os.trans_id <> os.new_gl_id;

alter table gl
  enable trigger gl_prevent_closed;


update payments_split
   set new_payment_id = nextval('payment_id_seq')
 where chart_seq > 1;

create temporary table payments_reversing_map as
  select new_payment_id, orig_payment_id, chart_seq
    from payments_split
   group by new_payment_id, orig_payment_id, chart_seq;


-- payments which are a mix of overpayments and regular payments
-- cause multiple rows in the payments_split table, which causes
-- duplicate inserts...
insert into payment (
  id, reference, gl_id, payment_class, payment_date, closed, entity_credit_id,
  employee_id, currency, notes, reversing
)
            overriding system value
select ps.new_payment_id,
       p.reference,
       null, /* overpayment gl transaction, updated below */
       p.payment_class,
       p.payment_date,
       p.closed,
       p.entity_credit_id,
       p.employee_id,
       p.currency,
       coalesce(p.notes || E'\n\n') || 'Split from ' || ps.orig_payment_id || ' because it contained multiple cash accounts',
       case
         when chart_seq = 1 then p.reversing
       else (select new_payment_id
               from payments_reversing_map prm
              where prm.chart_seq = ps.chart_seq
                and prm.orig_payment_id = p.reversing)
       end /* reversing */
  from payment p
         join payments_split ps
             on ps.orig_payment_id = p.id
 where ps.new_payment_id is not null
 -- insert reversed transactions before reversing transactions
 order by reversing nulls first;


-- by updating *all* payments, we prevent the re-used GL record to
-- be referenced twice because it wasn't applicable to the payment
-- record we retained (it was applicable to another record instead)
update payment p
   set gl_id = (select new_gl_id -- also contains the gl_id to reuse
                  from overpayments_split os
                 where os.payment_id = ps.orig_payment_id
                   and os.chart_id = ps.chart_id)
       from payments_split ps
 where ps.orig_gl_id is not null -- restrict to overpayments
   and (p.id = ps.new_payment_id
        or (ps.new_payment_id is null
            and p.id = ps.orig_payment_id));


update payment_links pl
   set payment_id = coalesce(new_payment_id, orig_payment_id)
       from payments_split ps
             join payment_links pl1
                on pl1.payment_id = ps.orig_payment_id
             join acc_trans ac
                on ac.entry_id = pl1.entry_id
 where pl.payment_id = ps.orig_payment_id
   and pl.entry_id = ac.entry_id
   and ps.trans_id = ac.trans_id;
