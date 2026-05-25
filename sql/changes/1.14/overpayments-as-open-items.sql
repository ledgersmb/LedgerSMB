
/*
 *
 *  THIS FILE NEEDS TO BE EXECUTED *BEFORE*
 *
 *   payments-first-order.sql
 *
 *
 *  because it assumes overpayment-use does not exist,
 *  which is what this file achieves.
 */

-- Add overpayment use transaction type
insert into trans_type (code, details_table, description)
values ('oa', null, 'The transaction is an allocation of overpayment balance');

-- Add overpayment open items
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
 *                                    MIGRATION
 *
 * ADR 0111 (~/doc/adr/0111-payment-overpayment-terminology.md) has a table describing the
 * migration performed below. That is: the migration below realizes the step from the
 * "Current" to the "Intermediate" state columns. The "Target" is realized by the migration
 * of Payments.
 *
 *
 *                                Required changes
 *
 * The migration impact table from ADR 0111 lists the following changes:
 *
 * - Introduction of overpayment open items for tracking overpayment balance (per
 *   overpayment, similar to tracking of open invoices). [Rows 5, 6 and 11]
 *
 * - Introduction of an overpayment-use transaction. [Rows 6 and 7]
 *
 *
 *                                   Approach
 *
 * The migration needs to be executed in three steps:
 *
 * 1. Add Overpayment open items to Overpayment creation (GL) transactions (exclude reversing ones!)
 *    --> These journal lines are in their own GL transactions, with payment_links.type == 2,
 *        which incidentally automatically excludes reversing ones, because those don't have payment links
 * 2. Reduce overpayment open items using overpayment creation reversal transactions
 *    --> These journal lines are in their own GL transactions
 *    --> Note: these journal lines are *not* linked to the payment using payment_links, which means
 *          we need to do clever matching of reversed and reversing payments
 * 3. Reduce overpayment open items using overpayment-allocation journal lines and collect these journal
 *    lines into new "overpayment allocation" transactions (moving them from the current AR/AP transactions)
 *    --> The overpayment to be reduced is indicated by payment_links.type == 0 on the journal line
 *        which created the overpayment (this line has the open item ID to reduce)
 *    --> These journal lines need to be collected into new "overpayment use" transactions: they are
 *        now part of AR/AP transactions.
 *
 * Each of these can be identified in the data as follows:
 * 1. A 'payment' record with non-NULL 'gl_id' and a NULL 'reversing' id
 * 2. A 'payment' record with non-NULL 'gl_id' and a non-NULL 'reversing' id
 *    to journal lines with trans_id == 'gl_id'
 * 3. A 'payment' record with a NULL gl_id and where a 'type' == 0 payment_link exists
 *
 * Note 1: It should be noted that payments may be a combination of allocation to overpayment as
 *   well as allocation to invoices. This matters for the payments migration, but does not affect
 *   the overpayments migration.
 *
 * Note 2: Overpayments exist only as single payments, although overpayment reversal does
 *   involve vouchers and batches.
 *
 * Note 3: Overpayments created or used from accounts not marked as AR/AP_overpayment do *not* get
 *   an overpayment open item created. They must be moved to their own transaction during the payment
 *   migration, however.
 */


-- STEP 1 : Overpayment creation migration

create temporary table overpayment_creation_migration
  as
  select nextval('overpayment_id_seq') as overpayment_id, pca.chart_id,
         entity_credit_id as eca_id, reference, p.id as payment_id, reversing,
         nextval('open_item_id_seq') as open_item_id,
         pca.chart_id as account_id
    from payment p
         join (select distinct pl.payment_id, ac.chart_id
                 from payment_links pl
                        join acc_trans ac
                            on pl.entry_id = ac.entry_id
                        join account_link al
                            on ac.chart_id = al.account_id
                where pl.type = 2
                  and al.description in ('AR_overpayment', 'AP_overpayment')) pca
              on p.id = pca.payment_id;


insert into open_item (
  id, item_number, item_type, account_id
)
            overriding system value
select om.open_item_id, 'overpay-' || reference, 'op', om.account_id
  from overpayment_creation_migration om;

insert into overpayment (
  id, open_item_id, eca_id
)
            overriding system value
select overpayment_id, open_item_id, eca_id
  from overpayment_creation_migration;


update account a
   set open_item_managed = true
       from account_link al
 where a.id = al.account_id
       and al.description in ('AR_overpayment', 'AP_overpayment');


alter table acc_trans
  disable trigger acc_trans_prevent_closed;

update acc_trans ac
   set open_item_id = om.open_item_id
       from overpayment_creation_migration om
            join payment_links pl
                 on om.payment_id = pl.payment_id
 where pl.entry_id = ac.entry_id
   and om.chart_id = ac.chart_id;

alter table acc_trans
  enable trigger acc_trans_prevent_closed;



-- STEP 2 : Overpayment reversals


/*
 * Overpayment reversal doesn't construct its own overpayment:
 * it closes the overpayment which already exists.
 */


alter table acc_trans
  disable trigger acc_trans_prevent_closed;

update acc_trans ac
   set open_item_id = om.open_item_id
       from overpayment_creation_migration om
            join payment_links pl
                 on om.reversing = pl.payment_id
 where ac.entry_id = pl.entry_id
   and om.chart_id = ac.chart_id;

alter table acc_trans
  enable trigger acc_trans_prevent_closed;



-- STEP 3 : Overpayment allocation

create or replace function pg_temp.create_workflow(in_approved boolean)
returns int as
$sql$
  with new_workflow_item (workflow_id) as (
    insert into workflow (workflow_id, type, state, last_update)
    values (nextval('workflow_seq'), 'Payment', case when in_approved then 'POSTED' else 'SAVED' end, now())
    returning workflow_id
  )
  insert into workflow_history (
    workflow_hist_id,
    workflow_id,
    action, description,
    state, workflow_user,
    history_date, workflow_entity_id
  )
  values (
    nextval('workflow_history_seq'),
    (select workflow_id from new_workflow_item),
    'migrate', 'created during payments-as-first-order-transactions migration',
    case when in_approved then 'POSTED' else 'SAVED' end, SESSION_USER,
    now(), person__get_my_entity_id())
  returning workflow_id;
$sql$ language sql;


create temporary table overpayment_allocation_migration
  as
  select p.id as payment_id, p.reference, paf.chart_id, paf.open_item_id
    from payment p
           join (select distinct pl.payment_id, ocm.chart_id, ocm.open_item_id
                   from payment_links pl -- payment link
                          join payment_links pc -- payment creation
                              on pl.entry_id = pc.entry_id
                          join overpayment_creation_migration ocm
                              on ocm.payment_id = pc.payment_id
                        -- pl.type = 1 is the 'use overpayment'
                  where pl.type = 1
                        -- pc.type = 0 is the overpayment being allocated from
                    and pc.type = 0) paf
              on paf.payment_id = p.id;


create temporary table overpayment_allocation_transactions
  as
  select distinct nextval('transactions_id_seq') as trans_id, payment_id, reference
  from overpayment_allocation_migration oam;


alter table transactions
  disable trigger transactions_prevent_closed;

insert into transactions (id, approved, transdate,
                          workflow_id, reference, description, trans_type_code)
select oat.trans_id, true,
       (select min(transdate)
          from acc_trans ac
                 join payment_links pl
                     on ac.entry_id = pl.entry_id
         where pl.payment_id = oat.payment_id),
       pg_temp.create_workflow(true),
       reference,
       'Transaction generated during payment migration',
       'oa'
  from overpayment_allocation_transactions oat;

alter table transactions
  enable trigger transactions_prevent_closed;


alter table acc_trans
  disable trigger acc_trans_prevent_closed;

update acc_trans ac
   set trans_id = oat.trans_id
       from overpayment_allocation_transactions oat
              join payment_links pl
                on oat.payment_id = pl.payment_id
 where pl.entry_id = ac.entry_id;

alter table acc_trans
  enable trigger acc_trans_prevent_closed;

-- remove the 'allocated from' payment links
-- they identify the lines of the payment allocation
-- but mention the payment ID of the overpayment creation
delete from payment_links pl
 where pl.type = 0;

delete from payment_links pl
            using overpayment_allocation_transactions oat
 where pl.payment_id = oat.payment_id;

delete from payment p
            using overpayment_allocation_transactions oat
 where p.id = oat.payment_id;


--###TODO verify that all acc_trans lines on the overpayment accounts
-- have open_item_ids set.
