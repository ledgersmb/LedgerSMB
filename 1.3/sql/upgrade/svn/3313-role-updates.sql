
INSERT INTO menu_acl (node_id, acl_type, role_name)
SELECT id, 'allow', 'lsmb_' || current_database() ||'__tax_form_save'
  FROM menu_node WHERE parent = 217 and position in (2,3);
