

alter table menu_node add column url text;
alter table menu_node add column standalone boolean;
alter table menu_node add column menu boolean;


update menu_node m
   set standalone = (select true from menu_attribute
                      where attribute = 'new'
                            and m.id = node_id);

update menu_node m
   set menu = (select true from menu_attribute
               where attribute = 'menu'
                     and m.id = node_id);

delete from menu_attribute where attribute = 'new';
delete from menu_attribute where attribute = 'menu';



update menu_node m
   set url = (select value from menu_attribute
               where node_id = m.id and attribute = 'module') || '?'
           || (select string_agg(attribute || '=' || value, '&')
                 from menu_attribute
                where node_id = m.id and not attribute = 'module'
                group by node_id);

drop table menu_attribute;

drop function if exists to_args(text[], text[]) cascade;
