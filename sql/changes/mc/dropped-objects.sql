
alter table account_checkpoint
  drop column amount;

alter table acc_trans
  drop column amount cascade,
  drop column fx_transaction cascade;

alter table ar
  drop column amount cascade,
  drop column netamount cascade;

alter table ap
  drop column amount cascade,
  drop column netamount cascade;

drop index exchangerate_ct_key;
drop table exchangerate;

