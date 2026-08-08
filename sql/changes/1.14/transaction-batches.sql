
/*
 * Implement ADR 0112 for GL and Upgrade vouchers
 */


alter table transactions
  add column batch_id int references batch(id);

comment on column transactions.batch_id is
  $$The id of the batch this transaction is part of; see ADR 0112$$;

alter table transactions
  disable trigger transactions_prevent_closed;

update transactions txn
   set batch_id = v.batch_id
       from voucher v
 where txn.id = v.trans_id
   and v.batch_class in (5, 10); -- gl, upgrade

alter table transactions
  enable trigger transactions_prevent_closed;

alter table acc_trans
  disable trigger acc_trans_prevent_closed;

update acc_trans
   set voucher_id = null
       from voucher v
 where v.batch_class in (5, 10);

alter table acc_trans
  enable trigger acc_trans_prevent_closed;

delete from voucher
 where batch_class in (5, 10);
