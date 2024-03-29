

update menu_node
   set menu = null,
       url = 'business-types',
       parent = 19,
       position = 4
 where id = 147; -- Type of Business

update menu_acl
   set node_id = 147
 where node_id in (148, 149); -- 248 creates duplicate sic_create on 150

delete from menu_node
 where id in (148, 149);

alter table business
  add column last_updated timestamp without time zone not null default now();

drop trigger if exists business_update_last_updated on business;
create trigger business_update_last_updated
   before update on business
   for each row execute procedure cdc_update_last_updated();

