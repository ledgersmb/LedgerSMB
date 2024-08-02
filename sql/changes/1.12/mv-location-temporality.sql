
alter table eca_to_location
  add column created date not null default now(),
  add column inactive_date timestamp,
  add column active boolean not null default true;

alter table entity_to_location
  add column created date not null default now(),
  add column inactive_date timestamp,
  add column active boolean not null default true;

update eca_to_location etl
   set created = l.created,
       inactive_date = l.inactive_date,
       active = l.active
       from location l
 where l.id = etl.location_id;

update entity_to_location etl
   set created = l.created,
       inactive_date = l.inactive_date,
       active = l.active
       from location l
 where l.id = etl.location_id;

alter table location
  drop column created,
  drop column inactive_date,
  drop column active;
