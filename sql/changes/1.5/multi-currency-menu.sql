
-- insert 4 menu items:

--  * Currencies, with sub items:
--   * Edit currencies
--   * Edit rate types
--   * Edit rates

create or replace function fixes_tmp()
returns void as $$
begin
   perform * from menu_node where label='Currency';

   if not found then
-- 128 == System menu
insert into menu_node (label, parent, "position")
 values ('Currency', 128, 0);


insert into menu_attribute
 values ((SELECT id FROM menu_node WHERE label = 'Currency'), 'menu', 128);

insert into menu_node (label, parent, "position")
 values ('Edit currencies',
         (SELECT id FROM menu_node WHERE label = 'Currency'),
         0);

insert into menu_attribute
 values
  ((SELECT id FROM menu_node WHERE label = 'Edit currencies'),
   'module', 'currency.pl'),
  ((SELECT id FROM menu_node WHERE label = 'Edit currencies'),
   'action', 'list_currencies');

insert into menu_acl (role_name, acl_type, node_id)
 values ('lsmb_mc__exchangerate_edit', 'allow',
         (select max(id) from menu_node));
   end if;


   perform * from menu_node where label='Edit rate types';

   if not found then
     insert into menu_node (label, parent, "position")
      values ('Edit rate types',
              (SELECT id FROM menu_node WHERE label = 'Currency'),
              2);

     insert into menu_attribute
      values
       ((SELECT id FROM menu_node WHERE label = 'Edit rate types'),
        'module', 'currency.pl'),
       ((SELECT id FROM menu_node WHERE label = 'Edit rate types'),
        'action', 'list_exchangerate_types');

     insert into menu_acl (role_name, acl_type, node_id)
      values ('lsmb_mc__exchangerate_edit', 'allow',
              (SELECT id FROM menu_node WHERE label = 'Edit rate types'));
   end if;

   perform * from menu_node where label='Edit rates';

   if not found then
     insert into menu_node (label, parent, "position")
      values ('Edit rates',
              (SELECT id FROM menu_node WHERE label = 'Currency'),
              3);

     insert into menu_attribute
      values
       ((SELECT id FROM menu_node WHERE label = 'Edit rates'),
        'module', 'currency.pl'),
       ((SELECT id FROM menu_node WHERE label = 'Edit rates'),
        'action', 'list_exchangerates');

     insert into menu_acl (role_name, acl_type, node_id)
      values ('lsmb_mc__exchangerate_edit', 'allow',
              (SELECT id FROM menu_node WHERE label = 'Edit rates'));
   end if;

   return;
end;
$$ language plpgsql;

select fixes_tmp();

drop function fixes_tmp();

