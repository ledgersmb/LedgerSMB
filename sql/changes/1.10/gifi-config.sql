
alter table gifi
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists gifi_update_last_updated on gifi;
create trigger gifi_update_last_updated
   before update on gifi
   for each row execute procedure cdc_update_last_updated();

