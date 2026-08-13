
update transactions txn
   set batch_id = v.batch_id
       from voucher v
 where txn.id = v.trans_id
   and v.batch_class not in (3, 4, 6, 7); -- not a payment voucher (shouldn't happen anyway)

alter table acc_trans
  rename column voucher_id to "deprecated-voucher_id";
drop table voucher cascade;

drop function if exists voucher_get_batch(integer);
drop function if exists voucher__list(integer);
drop type if exists batch_list_item cascade;
drop type if exists voucher_list cascade;
