
UPDATE menu_node SET position = position * -1 - 1 WHERE parent = 1 and position > 6;
INSERT INTO menu_node (id, parent, position, label)
VALUES (129, 1, 7, 'Add Return');
update menu_node set position = position * -1 where position < 0;
INSERT INTO menu_attribute (id, node_id, attribute, value)
VALUES (251, 129, 'module', 'is.pl'),
       (252, 129, 'action', 'add'),
       (253, 129, 'type', 'customer_return');
