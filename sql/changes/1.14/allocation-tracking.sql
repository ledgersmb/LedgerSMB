
alter table acc_trans
  add column allocation int references acc_trans(entry_id);

-- the total of all 'allocation' rows should add up to the
-- original payment or overpayment amount, except when transaction
-- costs are deducted from the payment, in which case the allocated
-- amounts add up to more than the original amount... How to
-- accomodate? The text below does not cover this case yet...
comment on column acc_trans.allocation is
  $$Applies to lines which modify an outstanding AR/AP item.

  Refers to a row in the same transaction from which the amount is taken,
  thereby identifying the related payment or overpayment. This relationship
  is used a.o. to present (over)payments on the AR/AP transaction and invoice
  screens.

  See ADR 0113.$$;

with payment_line as (
  select a.trans_id, a.chart_id, a.entry_id, a.amount_bc, pl.payment_id, pl.type
    from acc_trans a
           join payment_links pl
               on a.entry_id = pl.entry_id
   where pl.type in (1, 2)
)
update acc_trans a
   set allocation = b.entry_id
    from payment_links pl
       join payment_line b
          on pl.payment_id = b.payment_id
  where a.entry_id = pl.entry_id
    and sign(a.amount_bc) <> sign(b.amount_bc)
    and b.trans_id = a.trans_id
    and a.entry_id <> b.entry_id
    and a.chart_id <> b.chart_id
    and a.chart_id in (select account_id
                         from account_link
                        where description in ('AR', 'AP', 'AR_overpayment', 'AP_overpayment'));
