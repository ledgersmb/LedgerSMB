SELECT menu_insert(217, 2, 'List Tax Forms');
INSERT INTO menu_attribute(node_id, attribute, value)
    VALUES (currval('menu_node_id_seq')::int, 'module', 'taxform.pl');
INSERT INTO menu_attribute(node_id, attribute, value)
    VALUES (currval('menu_node_id_seq')::int, 'action', 'list_all');

SELECT menu_insert(217, 3, 'Reports');
INSERT INTO menu_attribute(node_id, attribute, value)
    VALUES (currval('menu_node_id_seq')::int, 'module', 'taxform.pl');


