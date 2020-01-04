

-- remove menu item 156 and all sub menu items (HTML Templates)

delete from menu_acl
 where node_id in (27, 29, 87, 88, 89, 93, 99, 159, 160, 161, 162, 163,
                   164, 165, 166, 167, 168, 169, 170, 171, 241, 156);

delete from menu_node
 where id in (27, 29, 87, 88, 89, 93, 99, 159, 160, 161, 162, 163, 164,
              165, 166, 167, 168, 169, 170, 171, 241);

delete from menu_node where id = 156;


-- remove menu item 172 and all sub menu items (LaTeX Templates)

delete from menu_acl
 where node_id in (30, 31, 32, 33, 90, 94, 103, 104, 105, 173, 174, 175,
                   176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186,
                   187, 242, 172);

delete from menu_node
 where id in (30, 31, 32, 33, 90, 94, 103, 104, 105, 173, 174, 175,
              176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186,
              187, 242);

delete from menu_node where id = 172;

-- re-insert item 156 as a menu-item (Templates)

insert into menu_node (id, label, parent, "position", url)
     values (156, 'Templates', 128, 13,
             'template.pl?action=display');
