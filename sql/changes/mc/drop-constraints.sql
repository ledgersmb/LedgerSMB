
alter table acc_trans
   alter column amount drop not null;

alter table account_checkpoint
   alter column amount drop not null;

alter table account_checkpoint
   drop constraint account_checkpoint_pkey;
