
alter table account
  add column heading_negative_balance integer
    references account_heading (id)
    constraint account_heading_neg_balance
       -- the negative balance heading can only be non-null for A and L accounts
       check (category in ('A', 'L') or heading_negative_balance is null);

comment on column account.heading_negative_balance is
  $$Indicates the header for reclassification of negative current asset/liability amounts.
  $$;
