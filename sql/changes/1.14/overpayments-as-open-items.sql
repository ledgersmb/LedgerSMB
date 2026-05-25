
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


insert into trans_type (code, description)
values ('uo', 'The transaction allocates (uses) an overpayment to pay an invoice');


/*
 * Data migration needs to account for 4 cases:
 *
 * 1. Payments which are overpayments
 * 2. Reversal of (1)
 * 3. Payments which are a use of overpayments
 * 4. Reversal of (3)
 *
 *
 * IDENTIFICATION OF CASE 1 (creation of overpayment)
 *
 * This case is recorded in the payment_links table with a 'type = 2' value and
 * a value for the 'gl_id' field pointing to a gl table record for the overpayment.
 *
 * IDENTIFICATION OF CASE 2 (reversal of overpayment creation)
 *
 * This case is recorded as a voucher with a batch_class of 4 or 7. The payment
 * table has a 'reversing' field containing the id value of the (over)payment
 * being reversed. This case does not have payment_links inserted.
 *
 * The link between an overpayment reversal and an overpayment is established
 * using the gl.reference field.
 *
 * IDENTIFICATION OF CASE 3 (use of overpayment)
 *
 * This case is recorded both as a payment (type = 1) *and* as a
 * "use overpayment" (type = 0) payment_link for the same acc_trans line (but
 * with different payments).
 *
 * IDENTIFICATION OF CASE 4 (reversal of overpayment use)
 *
 * The code does not support this use-case: applied overpayments can't be
 * reversed through the UI.
 */

/*
 * MIGRATION OF CASE 1 (creation of overpayment)
 *
 * The overpayment_migration table excludes overpayment reversals,
 * because those do not use payment_links; instead, they insert a payment
 * record with a 'reversing' column set to the original and a GL transaction
 * to link the acc_trans rows. See below for migration of reversals.
 *
 */

create temporary table overpayment_migration
  as
  select nextval('overpayment_id_seq') as overpayment_id, pl.entry_id,
         entity_credit_id as eca_id, reference, p.id as payment_id,
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


-- this sets the open_item_id for both the type = 2 and type = 0 payment_links
-- that is: for the 'use overpayments' case as well
update acc_trans ac
   set open_item_id = om.open_item_id
       from overpayment_migration om
            join payment_links pl
                 on om.payment_id = pl.payment_id
 where pl.entry_id = ac.entry_id
   and ac.chart_id = om.account_id;

alter table acc_trans
  enable trigger acc_trans_prevent_closed;


/*
 * MIGRATION OF CASE 2 (reversal of overpayment)
 *
 * Reversals of overpayments don't have a 'payment' record: they have
 * vouchers of classes 4 or 7 (which invoice payment reversals have too).
 * The difference is that the transactions of regular payments are of
 * 'trans_type_code' == 'ar' or 'ap'.
 *
 * We need to find the open_item_ids (multiple) to set the reversal
 * to: the original overpayment can have multiple rows of overpayment
 * accounts which we need to match with the original overpayment
 * generation. The idea to prevent a cartesian product is to sort the
 * transactions both by chart_id and amount followed by numbering the rows
 * (within the transaction). The join between the original transaction and
 * the reversal will not result in a cartesian product because the rows are
 * uniquely numbered.
 *
 * Then, the open_item_id can safely be copied between the rows, because even
 * with exactly the same amounts: the row numbers and the open_item_ids will
 * be different.
 *
 * For additional complexity, there can also be multiple cash accounts. The
 * approach above addresses this use-case too.
 *
 * Note 1: 1.8+ have a 'reversing' field in the payment, but that field isn't
 * filled for overpayments, so we use the 'reference' to do the lookup.
 *
 * Note 2: at some point after 1.4 'payment' records stopped being created
 * for overpayment reversals. We may need to create (some of) them.
 */

-- step 1: find the payment records which have an associated reversal
create temporary table reversed_overpayments as
  select x.payment_id, x.trans_id, x.reversing_trans_id,
         coalesce(x.reversing_payment_id, nextval('payment_id_seq')) as reversing_payment_id,
         (x.reversing_payment_id is null) as needs_creation
    from (
      select id as payment_id, trans_id, (
        select txn.id
          from transactions txn
                 join voucher v
                     on txn.id = v.trans_id
         where v.batch_class = 4
           and txn.reference = p.reference || '-reversal'
      ) as reversing_trans_id, (
        select rp.id
          from payment rp
         where rp.reference = p.reference || '-reversal'
      ) as reversing_payment_id
        from payment p
       where trans_id is not null -- overpayment
         and payment_class = 1
    ) x
   where reversing_trans_id is not null
         union all
  select x.payment_id, x.trans_id, x.reversing_trans_id,
         coalesce(x.reversing_payment_id, nextval('payment_id_seq')) as reversing_payment_id,
         (x.reversing_payment_id is null) as needs_creation
    from (
      select id as payment_id, trans_id, (
        select txn.id
          from transactions txn
                 join voucher v
                     on txn.id = v.trans_id
         where v.batch_class = 7
           and txn.reference = p.reference || '-reversal'
      ) as reversing_trans_id, (
        select rp.id
          from payment rp
         where rp.reference = p.reference || '-reversal'
      ) as reversing_payment_id
        from payment p
       where trans_id is not null -- overpayment
         and payment_class = 2
    ) x
   where reversing_trans_id is not null;

-- step 2: create a payment record for the reversing overpayment
insert into payment (
  id, reference, payment_class, payment_date,
  entity_credit_id, employee_id, currency,
  reversing, trans_id
  )
            overriding system value
select reversing_payment_id, p.reference || '-reversal', p.payment_class, p.payment_date,
       p.entity_credit_id, p.employee_id, p.currency,
       payment_id, reversing_trans_id
  from reversed_overpayments rop
         join payment p
             on rop.payment_id = p.id
 where rop.needs_creation;

-- it's no use inserting payment links,
--  because those would be removed at the end of this script

-- step 3: create two tables mapping transaction rows to open_item_ids
create temporary table numbered_reversed as
  select p.id as payment_id, ac.entry_id, ac.open_item_id,
         row_number() over (partition by p.id
                            order by ac.chart_id, ac.amount_bc) as row_num
    from acc_trans ac
           join payment p
               on p.trans_id = ac.trans_id
   where exists (
     select 1
       from reversed_overpayments rop
      where rop.payment_id = p.id
   );

create temporary table numbered_reversing as
  select p.id as payment_id, ac.entry_id, ac.open_item_id,
         row_number() over (partition by p.id
                            order by ac.chart_id, ac.amount_bc) as row_num
    from acc_trans ac
           join payment p
               on p.trans_id = ac.trans_id
   where exists (
     select 1
       from reversed_overpayments rop
      where rop.reversing_payment_id = p.id
   );

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


/*
 * MIGRATION OF CASE 3 (use of overpayment)
 */

-- step 1: identify all payments which have a 'use overpayment' acc_trans line
--         and are not overpayment creations themselves (because the "use overpayment" line
--         links to the "create overpayment" payment; not to the using payment itself)
create table overpaymentuse_payments as
  select p.id as payment_id, nextval('transactions_id_seq') as trans_id,
         reference, payment_date, employee_id
    from payment p
   where exists (
     select 1
       from payment_links
      where type = 0 -- use overpayment
        and entry_id in (
          select entry_id
            from payment_links pl
           where pl.payment_id = p.id
        )
   )
     and p.reversing is null
     and not exists (select 1   -- not an overpayment creation
                       from payment_links pl
                      where type = 2
                        and pl.payment_id = p.id);

-- step 2: convert the overpayment-use-payment to a gl transaction 'taking' from the
--         overpayment open item and 'moving to' ar/ap open item.
--         The good part here is that the ar/ap open item should already be converted
--         before this schema change and the use of the overpayment has been converted
--         to an overpayment-open-item. Which basically means we need to convert payments
--         to transactions here, but everything else has already been done.

alter table transactions
  disable trigger transactions_prevent_closed;

insert into transactions (
  id, trans_type_code, transdate, reference, approved, entered_by
)
            overriding system value
select trans_id, 'uo', payment_date, reference,
       (select bool_and(ac.approved)
          from acc_trans ac
                 join payment_links pl
                     on ac.entry_id = pl.entry_id
         where pl.payment_id = opup.payment_id) as approved,
       (select entity_id
          from person
         where person.id = employee_id) as entered_by
  from overpaymentuse_payments opup;

alter table transactions
  enable trigger transactions_prevent_closed;


-- step 3: collect acc_trans lines into newly created transactions
--         note that the payment conversion for use of overpayments
--         created open items, but that's wrong: we need to use
--         Note: The resulting transactions have lines with different
--               open_item_id values, because one is the AR/AP item
--               and the other is the overpayment
--         No need to set the open_item_id on the transaction line,
--         because the overpayment creation (above) already did so for
--         both 'creation' (type=2) and 'use' (type=0) lines
alter table acc_trans
  disable trigger acc_trans_prevent_closed;

update acc_trans ac
   set trans_id = opup.trans_id
       from overpaymentuse_payments opup
            join payment_links pl
                 on pl.payment_id = opup.payment_id
 where ac.entry_id = pl.entry_id;

alter table acc_trans
  enable trigger acc_trans_prevent_closed;

/*
 *
 * CLEANUP
 *
 */

-- no need to delete from numbered_reversing:
--   reversed overpayments don't use payment links...
delete from payment_links pl
 where exists (select 1
                 from overpayment_migration om
                where pl.payment_id = om.payment_id);

delete from payment_links pl
 where exists (select 1
                 from overpaymentuse_payments opup
                where pl.payment_id = opup.payment_id);

-- use of an overpayment is itself not a payment
-- but was modeled as one up to now; remove these non-payments
delete from payment p
 where exists (select 1
                 from overpaymentuse_payments opup
                where p.id = opup.payment_id);

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

drop table numbered_reversed;
drop table numbered_reversing;
drop table reversed_overpayments;
drop table overpayment_migration;
