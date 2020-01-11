

-- From Payment.sql

-- Currently (and to support earlier data) we define a payment as a collection
-- of acc_trans records against the same credit account and cash account, on
-- the same day with the same source number, and optionally the same voucher id.


-- There's no need to handle overpayments here, because they already have
-- a record in the payment table.


create temporary table payment_migration (
  payment_id            int,
  payment_class         int, -- follows eca.entity_class; 1=payment, 2=receipt
  entity_credit_account int,
  account_id            int,
  payment_date          date,
  voucher_id            int,
  source                text,
  curr                  varchar(3),
  entries               int[]
);


-- Identify synthetic payments as payments__search would have
insert into payment_migration (
  entity_credit_account, payment_class, account_id, payment_date, voucher_id,
  source, curr, entries
  )
select c.id, c.entity_class, a.id, al.transdate, v.id, al.source,
  arap.curr, array_agg(al.entry_id)
from entity_credit_account c
join ( select entity_credit_account, id, curr from ar
       union
       select entity_credit_account, id, curr from ap
       ) arap on arap.entity_credit_account = c.id
join acc_trans al on arap.id = al.trans_id
join account a on al.chart_id = a.id
left join (select * from voucher where batch_class in (3,4,6,7)) v
          on v.id = al.voucher_id
where (a.id in (select account_id from account_link
                 where description in ('AR_paid', 'AP_paid')))
      and not exists (select 1 from payment_links
                       where payment_links.entry_id = al.entry_id)
group by c.id, a.id, al.transdate, v.id, al.source,
      -- above define the payment
      -- below are required to set up the payment record
      c.entity_class, arap.curr;



update payment_migration
   set payment_id = nextval('payment_id_seq');


-- Generate synthetic payments from payments__search-simulated payments
insert into payment (id, reference, payment_class, payment_date,
                     entity_credit_id, employee_id, currency, notes)
  select payment_id, 'payment-migration-' || payment_id,
         payment_class, payment_date, entity_credit_account, null, curr,
         'This payment was synthesized during migration of "voucher" records
to "payment_links"'
    from payment_migration;


-- Note that both payment_links type '0' and '2' are overpayment related,
-- which have always had their own special handling; they *must* already
-- be in the table, which means they're filtered out by the criterion in
-- the acc_trans lines selection "entry_id must not already be in
-- payment_links"
insert into payment_links (payment_id, entry_id, type)
  select payment_id, unnest(entries), 1
    from payment_migration;

