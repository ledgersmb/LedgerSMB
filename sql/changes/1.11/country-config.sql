
insert into menu_node (parent, "position", label, url)
            values (128, 10, 'Country', 'countries');

alter table country
  add column last_updated timestamp without time zone not null default now();

create trigger country_modtimestamp
   before update on country
   for each row execute procedure moddatetime(last_updated);

