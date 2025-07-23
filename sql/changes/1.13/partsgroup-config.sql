
alter table partsgroup
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists partsgroup_update_last_updated on partsgroup;
create trigger partsgroup_update_last_updated
   before update on partsgroup
   for each row execute procedure cdc_update_last_updated();

