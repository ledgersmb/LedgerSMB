
alter table transactions
  add column reversing int,
  add column reference text;

comment on column transactions.reference is
  $$For GL transactions, this field contains gl.reference;
For AR/AP transactions, this field contains the invnumber field.$$;

comment on column transactions.reversing is
  $$This transaction is a reversal transaction. This field holds
the transactions.id of the transaction being reversed.$$;

update transactions t
   set reference = ar.invnumber
       from ar
 where t.id = ar.id;

update transactions t
   set reference = ap.invnumber
       from ap
 where t.id = ap.id;

update transactions t
   set reference = gl.reference
       from gl
 where t.id = gl.id;


create unique index transactions_reversing_idx
    on transactions ( reversing ) where reversing is not null;

create view transactions_reversal as
  select t.*,
         i.id as reversed_by, i.reference as reversed_by_reference,
         j.reference as reversing_reference
    from transactions t
           left join transactions i
             on t.id = i.reversing
           left join transactions j
               on t.reversing = j.id;
