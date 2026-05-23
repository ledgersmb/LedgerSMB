
drop function if exists account__save
(in_id int, in_accno text, in_description text, in_category char(1),
in_gifi_accno text, in_heading int, in_heading_negative_balance int,
in_contra bool, in_tax bool, in_link text[], in_obsolete bool, in_is_temp bool);

drop function if exists payment_post(
  in_datepaid date, in_account_class integer, in_entity_credit_id integer,
  in_curr character, in_exchangerate numeric, in_notes text, in_gl_description text,
  in_cash_account_id integer[], in_amount numeric[], in_source text[], in_memo text[],
  in_transaction_id integer[], in_op_amount numeric[], in_op_cash_account_id integer[],
  in_op_source text[], in_op_memo text[], in_op_account_id integer[],
  in_ovp_payment_id integer[], in_approved boolean);


create table open_item (
  id int generated always as identity primary key,
  item_number text not null unique,
  item_type char(2) not null check(item_type = ANY(ARRAY['gl', 'ar', 'ap']::text[])),
  account_id int not null references account(id)
  );

alter table acc_trans
  add column open_item_id int references open_item (id);

create index idx_acc_trans_open_item_id on acc_trans (open_item_id)
  where open_item_id is not null;

alter table account
  add column open_item_managed boolean not null default false;

alter table ar
  rename column id to trans_id;

comment on column ar.trans_id is
  $$References the transaction representing the invoice or AR transaction.

  This is the transaction responsible for creating or adding to the debtors
  balance under Accounts Receivable (unless the transaction voids an invoice or
  is a credit invoice or note).$$;

alter table ar
  add column open_item_id int references open_item(id);


alter table ap
  rename column id to trans_id;

comment on column ar.trans_id is
  $$References the transaction representing the invoice or AP transaction.

  This is the transaction responsible for creating or adding to the creditors
  balance under Accounts Payable (unless the transaction voids an invoice or
  is a debit invoice or note).$$;

alter table ap
  add column open_item_id int references open_item(id);


-- because ar and ap no longer have an 'id' column:
CREATE OR REPLACE FUNCTION gl_audit_trail_append()
RETURNS TRIGGER AS
$$
DECLARE
   t_reference text;
   t_row RECORD;
   t_id int;
BEGIN

IF TG_OP = 'INSERT' then
   t_row := NEW;
ELSE
   t_row := OLD;
END IF;

IF TG_TABLE_NAME IN ('ar', 'ap') THEN
    t_reference := t_row.invnumber;
    t_id := t_row.trans_id;
ELSE
    t_reference := t_row.reference;
    t_id := t_row.id;
END IF;

INSERT INTO audittrail (trans_id,tablename,reference, action, person_id)
values (t_id,TG_TABLE_NAME,t_reference, TG_OP, person__get_my_entity_id());

return null; -- AFTER TRIGGER ONLY, SAFE
END;
$$ language plpgsql security definer;



comment on table open_item is
  $$Allows tracking of items to be cleared/handled in subsequent transactions. $$;

comment on column open_item.id is
  $$Internal identifier for the open item. $$;
comment on column open_item.item_number is
  $$Identifier as presented in the user interface. $$;
comment on column open_item.item_type is
  $$Type of open item; currently 'gl','ar' or 'ap'. $$;
comment on column acc_trans.open_item_id is
  $$The open item this journal line is linked to; this indicates an allocation (reduction) of the open item, unless the entry_id of this line item is the lowest entry_id in the set, in which case it is the opening balance. $$;
comment on column account.open_item_managed is
  $$Indicates whether postings on this account will be tracked using open items.$$;



create or replace function trigger_open_item_maintenance () returns trigger
as $$
begin
  return new;
end;
  $$ language plpgsql;


create trigger trigger_open_item_maintenance
  before insert or update on acc_trans
  for each row
    execute function trigger_open_item_maintenance();


/*
  *
  * Data migration
  *
 */

insert into open_item (
  item_number, item_type, account_id
)
select al.description || '-' || aa.trans_id, lower(al.description), chart_id
  from acc_trans
         join (select trans_id, invnumber
                 from ar
                union
               select trans_id, invnumber
                 from ap) aa
             on acc_trans.trans_id = aa.trans_id
         join account_link al
             on acc_trans.chart_id = al.account_id
 where al.description in ('AR', 'AP')
 group by al.description, aa.trans_id, lower(al.description), chart_id;

insert into open_item (
  item_number, item_type, account_id
)
select 'AR-' || trans_id, 'ar', (select id
                                   from account
                                  where exists (select 1
                                                  from account_link al
                                                 where description = 'AR'
                                                   and al.account_id = account.id)
                                  order by accno
                                  limit 1)
  from ar
 where not exists (select 1
                     from acc_trans ac
                            join account_link l
                                on ac.chart_id = l.account_id
                    where l.description = 'AR'
                      and ar.trans_id = ac.trans_id);

insert into open_item (
  item_number, item_type, account_id
)
select 'AP-' || trans_id, 'ap', (select id
                                   from account
                                  where exists (select 1
                                                  from account_link al
                                                 where description = 'AP'
                                                   and al.account_id = account.id)
                                  order by accno
                                  limit 1)
  from ap
 where not exists (select 1
                     from acc_trans ac
                            join account_link l
                                on ac.chart_id = l.account_id
                    where l.description = 'AP'
                      and ap.trans_id = ac.trans_id);


update ar
   set open_item_id = oi.id
       from open_item oi
 where oi.item_number = 'AR-' || ar.trans_id;

update ap
   set open_item_id = oi.id
       from open_item oi
 where oi.item_number = 'AP-' || ap.trans_id;

update account
   set open_item_managed = exists (select 1
                                     from account_link al
                                    where al.description in ('AR', 'AP')
                                      and al.account_id = account.id);

alter table ar
  alter column open_item_id set not null;

alter table ap
  alter column open_item_id set not null;


update acc_trans ac
   set open_item_id = oi.id
       from open_item oi
 where ac.chart_id = oi.account_id
   and (oi.item_number = 'AR-' || ac.trans_id
        or oi.item_number = 'AP-' || ac.trans_id);
