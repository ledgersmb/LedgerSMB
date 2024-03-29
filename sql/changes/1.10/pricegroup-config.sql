
update menu_acl
   set node_id = 83
 where node_id = 92;

delete from menu_node
 where id = 92;

update menu_node
   set label = 'Pricegroups',
       url = 'pricegroups',
       position = 8
 where id = 83; -- Add Pricegroups

alter table pricegroup
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists pricegroup_update_last_updated on pricegroup;
create trigger pricegroup_update_last_updated
   before update on pricegroup
   for each row execute procedure cdc_update_last_updated();

