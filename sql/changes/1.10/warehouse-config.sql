

update menu_node
   set menu = null,
       url = 'warehouses'
 where id = 141; -- Warehouses

update menu_acl
   set node_id = 141
 where node_id in (142, 143);

delete from menu_node
 where id in (142, 143);

alter table warehouse
  add column last_updated timestamp without time zone not null default now();

create trigger warehouse_modtimestamp
   before update on warehouse
   for each row execute procedure moddatetime(last_updated);

