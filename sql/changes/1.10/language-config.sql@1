

update menu_node
   set menu = null,
       url = 'languages'
 where id = 150; -- Languages

update menu_acl
   set node_id = 150
 where node_id in (151, 152);

delete from menu_node
 where id in (151, 152);

alter table language
  add column last_updated timestamp without time zone not null default now();

create trigger language_modtimestamp
   before update on language
   for each row execute procedure moddatetime(last_updated);

