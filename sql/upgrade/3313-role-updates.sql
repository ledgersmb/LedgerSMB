
INSERT INTO menu_acl (node_id, acl_type, role_name)
SELECT id, 'allow', 'lsmb_<?lsmb dbname ?>__tax_form_save'
  FROM menu_node WHERE parent_id = 217 and position in (2,3);
