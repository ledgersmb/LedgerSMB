INSERT INTO menu_node (id, parent, position, label)
VALUES (87, 156, -1, 'Invoicing'),
       (88, 156, -2, 'Ordering'),
       (89, 156, -3, 'Shipping'),
       (93, 156, -4, 'Other'),
       (94, 172, -1, 'Invoicing'),
       (103, 172, -2, 'Ordering'),
       (104, 172, -3, 'Shipping'),
       (105, 172, -4, 'Other');

INSERT INTO menu_attribute (id, node_id, attribute, value) -- menu = 1
VALUES (301, '87', 'menu', '1'),
       (302, '88', 'menu', '1'),
       (303, '89', 'menu', '1'),
       (304, '93', 'menu', '1'),
       (305, '94', 'menu', '1'),
       (306, '103', 'menu', '1'),
       (307, '104', 'menu', '1'),
       (308, '105', 'menu', '1');

UPDATE menu_node set parent = 87
 WHERE id in (99, 159, 160, 161, 168);
UPDATE menu_node set parent = 88
 WHERE id in (164, 165, 166, 169, 170);
UPDATE menu_node set parent = 89
 WHERE id in (162, 163, 167);
UPDATE menu_node set parent = 93 where parent = 156 and position > 0;
UPDATE menu_node set parent = 94
 WHERE id in (90, 173, 174, 175, 182);
UPDATE menu_node set parent = 103
 WHERE id in (178, 179, 180, 185, 186);
UPDATE menu_node set parent = 104
 WHERE id in (176, 177, 32, 33, 181);
UPDATE menu_node set parent = 105 where parent = 172 and position > 0;

UPDATE menu_node SET position = position * -1 where position < 0
  AND parent in (156, 172);
