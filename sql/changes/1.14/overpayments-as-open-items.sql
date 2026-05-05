
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


delete from payment_links pl
 where exists (select 1
                 from overpayment_migration om
                where pl.payment_id = om.payment_id);

delete from payment p
 where exists (select 1
                 from overpayment_migration om
                where p.id = om.payment_id);


-- we really, really should prevent anything else
alter table payment_links
  add constraint check_payment_links_type check(type = 1);

-- any rows added with a trans_id is part of an overpayment...
alter table payment
  add constraint check_payment_trans_id_null check(trans_id is null);

drop table overpayment_migration;
