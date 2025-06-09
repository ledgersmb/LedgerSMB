
insert into menu_node (id, parent, "position", label, url)
            values (264, 128, 10, 'Country', 'countries');

alter table country
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists country_update_last_updated on country;
create trigger country_update_last_updated
   before update on country
   for each row execute procedure cdc_update_last_updated();

