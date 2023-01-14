
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

create trigger pricegroup_modtimestamp
   before update on pricegroup
   for each row execute procedure moddatetime(last_updated);

