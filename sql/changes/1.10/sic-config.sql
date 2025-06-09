
alter table sic
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists sic_update_last_updated on sic;
create trigger sic_update_last_updated
   before update on sic
   for each row execute procedure cdc_update_last_updated();

