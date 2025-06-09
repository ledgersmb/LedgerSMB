
alter table business
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists business_update_last_updated on business;
create trigger business_update_last_updated
   before update on business
   for each row execute procedure cdc_update_last_updated();

