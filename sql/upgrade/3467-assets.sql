BEGIN;
INSERT INTO account_link_description  (description, summary, custom)
VALUES 
('Asset_Dep',            FALSE, FALSE),
('Fixed_Asset',          FALSE, FALSE),
('asset_expense',        FALSE, FALSE),
('asset_gain',           FALSE, FALSE),
('asset_loss',           FALSE, FALSE);


CREATE TEMPORARY TABLE menu_import (node_id int, key text);

INSERT INTO menu_import
values (menu_insert(0, 17, 'Fixed Assets'), 'main_menu');

INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'menu', '1');


SELECT menu_insert(
    (select id FROM menu_node
      where parent = (select id from menu_node
                       where parent = 0 and position = 17
                             and label = 'Fixed Assets')
            and position = 2),
    2, 'Search Assets');

INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'module', 'asset.pl');
INSERT INTO menu_attribute (node_id, attribute, value)
VALUES (currval('menu_node_id_seq')::int, 'action', 'asset_search');

COMMIT;
