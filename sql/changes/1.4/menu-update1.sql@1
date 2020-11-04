UPDATE menu_node set position = (position * -1) - 1
 where parent IN (172, 156) and position > 1;
UPDATE menu_node set position = position * -1 where position < 0;
INSERT INTO menu_node (id, parent, position, label)
VALUES (90, 172, 2, 'Product Receipt'),
       (99, 156, 2, 'Product Receipt');

INSERT INTO menu_attribute
(id, node_id, attribute, value) VALUES
(228, 90, 'module', 'template.pm'),
(229, 90, 'action', 'display'),
(230, 90, 'template_name', 'product_receipt'),
(231, 90, 'format', 'tex'),
(240, 99, 'module', 'template.pm'),
(241, 99, 'action', 'display'),
(242, 99, 'template_name', 'product_receipt'),
(245, 99, 'format', 'html');
