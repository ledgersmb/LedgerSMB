BEGIN;

SELECT setval('menu_node_id_seq', max(id)) from menu_node;
SELECT setval('menu_attribute_id_seq', max(id)) from menu_attribute;

SELECT * FROM menu_insert(236, 2, 'Depreciation');

INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'module', 'asset.pl');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'action', 'search_reports');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'depreciation', '1');

INSERT INTO menu_acl(node_id, acl_type, role_name)
values (currval('menu_node_id_seq')::int, 'allow', 
        'lsmb_' || current_database() || '__assets_approve');

SELECT * FROM menu_insert(236, 3, 'Disposal');

INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'module', 'asset.pl');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'action', 'search_reports');
INSERT INTO menu_acl(node_id, acl_type, role_name)
values (currval('menu_node_id_seq')::int, 'allow', 
        'lsmb_' || current_database() || '__assets_approve');

COMMIT;
