
alter table transactions
  add column reversing int;

create unique index transactions_reversing_idx
    on transactions ( reversing ) where reversing is not null;

create view transactions_reversal as
  select t.*, (select i.id from transactions i
                where i.approved and i.reversing = t.id) as reversed_by
    from transactions t;

