

alter table account_checkpoint
  alter column amount_bc not null,
  alter column amount_tc not null,
  alter column curr not null,
  add constraint account_checkpoint_curr_fkey
        foreign key (curr) references currency (curr);

alter table account_checkpoint
  drop constraint account_checkpoint_pkey;

alter table account_checkpoint
  add primary key (end_date, account_id, curr);



alter table entity_credit_account
--  alter column curr not null,
  add constraint entity_credit_account_curr_fkey
        foreign key (curr) references currency (curr);


alter table journal_line
  alter column amount_tc not null check (amount_tc <> 'NaN'),
  alter column curr not null,
  add constraint journal_line_curr_fkey
        foreign key (curr) references currency (curr);


 alter table acc_trans
  alter column amount_bc not null,
  alter column amount_tc not null,
  alter column curr not null,
  add constraint acc_trans_curr_fkey
        foreign key (curr) references currency (curr);


alter table ar
  alter column curr
        check ( (amount_bc IS NULL AND curr IS NULL)
                OR (amount_bc IS NOT NULL AND curr IS NOT NULL)),
  add constraint ar_curr_fkey
        foreign key (curr) references currency (curr);


alter table ap
  alter column curr
        check ( (amount_bc IS NULL AND curr IS NULL)
                OR (amount_bc IS NOT NULL AND curr IS NOT NULL)),
  add constraint ap_curr_fkey
        foreign key (curr) references currency (curr);


alter table oe
  add constraint oe_curr_fkey
        foreign key (curr) references currency (curr);


alter table budget_line
  alter column amount_tc not null,
  alter column curr not null,
  add constraint budget_line_curr_fkey
        foreign key (curr) references currency (curr);


alter table partsvendor
  alter column curr not null,
  add constraint partsvendor_curr_fkey
        foreign key (curr) references currency (curr);


alter table partscustomer
  alter column curr not null,
  add constraint partscustomer_curr_fkey
        foreign key (curr) references currency (curr);


alter table jcitems
  alter column curr not null,
  add constraint jcitems_curr_fkey
        foreign key (curr) references currency (curr);


