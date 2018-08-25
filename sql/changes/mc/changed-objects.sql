
alter table ar
  rename column paid to paid_deprecated;

alter table ap
  rename column paid to paid_deprecated;

alter table oe
  rename column amount to amount_tc,
  rename column netamount to netamount_tc;


