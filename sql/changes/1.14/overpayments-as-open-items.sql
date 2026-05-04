
/*
 *
 *  THIS FILE NEEDS TO BE EXECUTED *BEFORE*
 *
 *   payments-first-order.sql
 *
 *
 *  because it assumes overpayments do not exist,
 *  which is what this file is all about.
 */

alter table open_item
  drop constraint open_item_item_type_check;
alter table open_item
  add constraint open_item_item_type_check check(item_type = ANY(ARRAY['gl', 'ar', 'ap', 'op']::text[]));

create table overpayment (
  id int primary key generated always as identity,
  open_item_id int not null references open_item(id),
  eca_id int not null references entity_credit_account(id)
  );


comment on table overpayment is
  $$Extends overpayments open items (item_type = 'op'), storing overpayment specific attributes. $$;
comment on column overpayment.id is
  $$Unique identification; may be dropped in the future in favor of 'open_item_id'. $$;
comment on column overpayment.open_item_id is
  $$ID of the open item this overpayment is an extension of. $$;
comment on column overpayment.eca_id is
  $$ID of the entity credit account for which the open item is tracking the overpayment. $$;

/*
 * The overpayment_migration table excludes overpayment reversals,
 * because those do not use payment_links; instead, they insert a payment
 * record with a 'reversing' column set to the original and a GL transaction
 * to link the acc_trans rows.
 *
 * A voucher is inserted and linked to the gl transaction too, with batch class 4 or 7.
 * Regular 4 or 7 batch class vouchers are linked to acc_trans, where the transaction
 * is an 'ar' or 'ap' type. Since the transaction here is a 'gl' type, this is the defining
 * difference (in addition to the 'reversing' column referring to an payment with 'trans_id'
 * set and payment_links of types 2 and 0).
 */

create temporary table overpayment_migration
  as
  select nextval('overpayment_id_seq') as overpayment_id, pl.entry_id,
         entity_credit_id as eca_id, reference, p.id as payment_id, reversing,
         nextval('open_item_id_seq') as open_item_id,
         ac.chart_id as account_id
    from payment_links pl
         join payment p
              on p.id = pl.payment_id
         join acc_trans ac
              on pl.entry_id = ac.entry_id
         join account_link al
              on ac.chart_id = al.account_id
  where pl.type = 2
    and al.description in ('AR_overpayment', 'AP_overpayment');

insert into open_item (
  id, item_number, item_type, account_id
)
            overriding system value
select om.open_item_id, 'overpay-' || reference, 'op', om.account_id
  from overpayment_migration om;

insert into overpayment (
  id, open_item_id, eca_id
)
            overriding system value
select overpayment_id, open_item_id, eca_id
  from overpayment_migration;


update account a
   set open_item_managed = true
       from account_link al
 where a.id = al.account_id
       and al.description in ('AR_overpayment', 'AP_overpayment');

alter table acc_trans
  disable trigger acc_trans_prevent_closed;


/*
  select ac.*, pl.*, om.open_item_id
  from acc_trans ac
  join payment_links pl
  on ac.entry_id = pl.entry_id
  join overpayment_migration om
  on om.payment_id = pl.payment_id
  where ac.chart_id = om.account_id
  order by om.open_item_id, ac.trans_id, ac.entry_id;
 */
update acc_trans ac
   set open_item_id = om.open_item_id
       from overpayment_migration om
            join payment_links pl
                 on om.payment_id = pl.payment_id
 where pl.entry_id = ac.entry_id
   and ac.chart_id = om.account_id;

alter table acc_trans
  enable trigger acc_trans_prevent_closed;


/* This is where we need to reconstruct the overpayment reversal.
 *
 * First of all, we need to find the open_item_id*s* to set the reversal to:
 * the original overpayment can have multiple rows of overpayment account hits
 * which we need to match with the original overpayment generation. The idea
 * to prevent a cartesian product is to sort the transactions both by
 * chart_id and amount followed by numbering the rows (within the transaction).
 * The join between the original transaction and the reversal will not result
 * in a cartesian product because the rows are uniquely numbered.
 *
 * Then, the open_item_id can safely be copied between the rows, because even
 * with exactly the same amounts, the row numbers and the open_item_ids will
 * be different (triggered by the 'type=2' condition on the original).
 */

create temporary table numbered_reversed as
  select payment_id, ac.entry_id, ac.open_item_id,
         row_number() over (partition by payment_id
                            order by ac.chart_id, ac.amount_bc) as row_num
    from acc_trans ac
           join payment_links pl
               on ac.entry_id = pl.entry_id
   where payment_id in (select reversing
                          from overpayment_migration);

create temporary table numbered_reversing as
  select reversing as payment_id, ac.entry_id,
         row_number() over (partition by payment.id
                            order by ac.chart_id, ac.amount_bc) as row_num
    from acc_trans ac
           join payment
               on ac.trans_id = payment.trans_id
   where reversing in (select payment_id
                         from overpayment_migration);


alter table acc_trans
  disable trigger acc_trans_prevent_closed;

update acc_trans ac
   set open_item_id = red.open_item_id
       from numbered_reversing ring
            join numbered_reversed red
              on ring.payment_id = red.payment_id
                 and ring.row_num = red.row_num
 where ring.entry_id = ac.entry_id;

alter table acc_trans
  enable trigger acc_trans_prevent_closed;

-- don't need to delete from numbered_reversing:
--   reversed overpayments don't use payment links...
delete from payment_links pl
 where exists (select 1
                 from overpayment_migration om
                where pl.payment_id = om.payment_id);


delete from payment p
 where exists (select 1
                 from numbered_reversing nr
                where p.id = nr.payment_id);

delete from payment p
 where exists (select 1
                 from overpayment_migration om
                where p.id = om.payment_id);


-- set the NULL values in the 'type' column
-- to '1' for payments that reverse a regular payment (type = 1)
update payment_links pl
   set type = 1
       from payment p
 where pl.payment_id = p.id
   and type is null
   and exists (select 1
                 from payment
                        join payment_links
                            on payment.id = payment_links.payment_id
                where payment.id = p.reversing
                  and payment_links.type = 1);

-- we really, really should prevent anything else
alter table payment_links
  alter column type set not null,
  add constraint check_payment_links_type check(type = 1);

-- any rows added with a trans_id is part of an overpayment...
alter table payment
  add constraint check_payment_trans_id_null check(trans_id is null);

drop table overpayment_migration;
