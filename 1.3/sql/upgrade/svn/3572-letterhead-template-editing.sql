-- Copy Letterhead HTML and TeX menus from their respective Invoice counterparts
insert into menu_node (id, label, parent, position) values (241, 'Letterhead', 159, 16);
insert into menu_node (id, label, parent, position) values (242, 'Letterhead', 172, 16);


insert into menu_attribute
  select 241 as node_id, attribute, value from menu_attribute where node_id = 159;
insert into menu_attribute
  select 242 as node_id, attribute, value from menu_attribute where node_id = 173;

insert into menu_acl
  select nextval('menu_acl_id_seq'), role_name, acl_type, 241 as node_id
  from menu_acl where node_id = 159;
insert into menu_acl
  select nextval('menu_acl_id_seq'), role_name, acl_type, 242 as node_id
  from menu_acl where node_id = 173;
