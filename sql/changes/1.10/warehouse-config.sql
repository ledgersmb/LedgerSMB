

update menu_node
   set menu = null,
       url = 'warehouses',
       parent = 77,
       position = 9
 where id = 141; -- Warehouses

update menu_acl
   set node_id = 141
 where node_id in (142, 143);

delete from menu_node
 where id in (142, 143);

alter table warehouse
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists warehouse_update_last_updated on warehouse;
create trigger warehouse_update_last_updated
   before update on warehouse
   for each row execute procedure cdc_update_last_updated();

