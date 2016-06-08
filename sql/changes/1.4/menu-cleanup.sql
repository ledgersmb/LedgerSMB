
DELETE FROM menu_acl
 WHERE node_id IN (select node_id from menu_attribute
                    where attribute = 'module' and value = 'bp.pl');
DELETE FROM menu_attribute
 WHERE node_id IN (select node_id from menu_attribute
                    where attribute = 'module' and value = 'bp.pl');
DELETE FROM menu_node
 WHERE id NOT IN (select node_id from menu_attribute);

DELETE FROM menu_acl
 WHERE node_id IN (select node_id from menu_attribute
                    where attribute = 'menu' and node_id not in
                          (select parent from menu_node));

DELETE FROM menu_attribute
 WHERE node_id IN (select node_id from menu_attribute
                    where attribute = 'menu' and node_id not in
                          (select parent from menu_node));
DELETE FROM menu_node
 WHERE id NOT IN (select node_id from menu_attribute);

UPDATE menu_attribute SET value = 'contact.pl'
 WHERE node_id = 48 AND attribute = 'module';

UPDATE menu_attribute SET value = 'template.pl' WHERE value = 'template.pm';
