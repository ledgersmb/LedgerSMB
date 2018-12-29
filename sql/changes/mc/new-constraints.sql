

alter table account_checkpoint
  alter column amount_bc set not null,
  alter column amount_tc set not null,
  alter column curr set not null,
  add constraint account_checkpoint_curr_fkey
        foreign key (curr) references currency (curr);

alter table account_checkpoint
  add primary key (end_date, account_id, curr);



alter table entity_credit_account
  add constraint entity_credit_account_req_curr
        check (entity_class_id IN (1, 2, 3) AND curr IS NOT NULL),
  add constraint entity_credit_account_curr_fkey
        foreign key (curr) references currency (curr);


alter table journal_line
  alter column amount_tc set not null,
  alter column curr set not null,
  add constraint journal_line_amount_tc_check check (amount_tc <> 'NaN'),
  add constraint journal_line_curr_fkey
        foreign key (curr) references currency (curr);


 alter table acc_trans
  alter column amount_bc set not null,
  alter column amount_tc set not null,
  alter column curr set not null,
  add constraint acc_trans_curr_fkey
        foreign key (curr) references currency (curr);


alter table ar
  drop constraint ar_check,
  add constraint ar_check
        check ( (amount_bc IS NULL AND curr IS NULL)
                OR (amount_bc IS NOT NULL AND curr IS NOT NULL)),
  add constraint ar_curr_fkey
        foreign key (curr) references currency (curr);


alter table ap
  drop constraint ap_check,
  add constraint ap_check
        check ( (amount_bc IS NULL AND curr IS NULL)
                OR (amount_bc IS NOT NULL AND curr IS NOT NULL)),
  add constraint ap_curr_fkey
        foreign key (curr) references currency (curr);


alter table oe
  add constraint oe_curr_fkey
        foreign key (curr) references currency (curr);


alter table budget_line
  alter column amount_tc set not null,
  alter column curr set not null,
  add constraint budget_line_curr_fkey
        foreign key (curr) references currency (curr);


alter table partsvendor
  alter column curr set not null,
  add constraint partsvendor_curr_fkey
        foreign key (curr) references currency (curr);


alter table partscustomer
  alter column curr set not null,
  add constraint partscustomer_curr_fkey
        foreign key (curr) references currency (curr);


alter table jcitems
  alter column curr set not null,
  add constraint jcitems_curr_fkey
        foreign key (curr) references currency (curr);


