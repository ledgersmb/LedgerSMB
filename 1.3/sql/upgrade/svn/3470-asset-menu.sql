BEGIN;

CREATE TEMPORARY TABLE menu_track (token text, node_id int);

INSERT INTO menu_track(node_id, token)
values (menu_insert(0, 17, 'Fixed Assets'), 'asset_top');

INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'menu', '1');

INSERT INTO menu_track values ('asset_class', menu_insert((SELECT node_id from menu_track where token = 'asset_top'), 1, 'Asset Classes'));

INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'menu', '1');

INSERT INTO menu_track values ('asset_item', menu_insert((SELECT node_id from menu_track where token = 'asset_top'), 2, 'Assets'));

INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'menu', '1');


SELECT menu_insert((SELECT node_id from menu_track where token = 'asset_class'), 1, 'Add Class');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'module', 'assets.pl');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'action', 'asset_category_screen');

SELECT menu_insert((SELECT node_id from menu_track where token = 'asset_class'), 2, 'List Classes');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'module', 'assets.pl');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'action', 'asset_category_search');


SELECT menu_insert((SELECT node_id from menu_track where token = 'asset_item'), 1, 'Add Assets');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'module', 'assets.pl');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'action', 'asset_screen');

SELECT menu_insert((SELECT node_id from menu_track where token = 'asset_items'), 2, 'Search Assets');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'module', 'assets.pl');
INSERT INTO menu_attribute(node_id, attribute, value)
VALUES (currval('menu_node_id_seq'), 'action', 'asset_search');

SELECT menu_insert(
       (SELECT id FROM menu_node WHERE parent = (select id from menu_node
                                                 where position = 17 
                                                       and parent = 0)
                  AND position=2), 3, 'Depreciate');

INSERT INTO menu_attribute (node_id, attribute, value)
values (currval('menu_node_id_seq'), 'module', 'asset.pl');
INSERT INTO menu_attribute (node_id, attribute, value)
values (currval('menu_node_id_seq'), 'action', 'new_report');
INSERT INTO menu_attribute (node_id, attribute, value)
values (currval('menu_node_id_seq'), 'depreciate', '1');

SELECT menu_insert(
    (select id FROM menu_node 
      where parent = (select id from menu_node 
                       where parent = 0 and position = 17 
                             and label = 'Fixed Assets')
            and position = 2), 
    2, 'Import');

INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'module', 'asset.pl');
INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'action', 'import');

SELECT menu_insert(
       (SELECT id FROM menu_node WHERE parent = (select id from menu_node
                                                 where position = 17
                                                       and parent = 0)
                  AND position=2), 10, 'Reports');

INSERT INTO menu_attribute (node_id, attribute, value)
values (currval('menu_node_id_seq'), 'menu', '1');
select menu_insert(currval('menu_node_id_seq')::int, 1, 'Net Book Value');
INSERT INTO menu_attribute (node_id, attribute, value)
values (currval('menu_node_id_seq'), 'module', 'asset.pl');
INSERT INTO menu_attribute (node_id, attribute, value)
values (currval('menu_node_id_seq'), 'action', 'display_nbv');

COMMIT;
