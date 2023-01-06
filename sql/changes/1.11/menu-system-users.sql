
insert into menu_node (id, label, parent, position, url)
values (263, 'Users', (select id from menu_node where label='System'),
        (select max(position)+1 from menu_node
          where parent=(select id from menu_node where label='System')),
          'admin.pl?action=list_users');

