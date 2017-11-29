INSERT INTO menu_node (id, parent, position, label)
values (29, 156, 18, 'Payment'), -- printPayment.html
       (30, 172, 18, 'Check Base'), -- check_base.tex
       (31, 172, 19, 'Multiple Checks'), -- check_multiple.tex
       (32, 172, 20, 'Envelope'), -- envelope
       (33, 172, 21, 'Shipping Label'); -- shipping_label.tex

INSERT INTO menu_attribute (id, node_id, attribute, value)
VALUES (256, 29, 'action', 'display'),
       (257, 29, 'format', 'html'),
       (258, 29, 'module', 'template.pl'),
       (259, 29, 'name', 'printPayment'),
       (260, 30, 'action', 'display'),
       (261, 30, 'format', 'tex'),
       (262, 30, 'module', 'template.pl'),
       (267, 30, 'name', 'check_base'),
       (289, 31, 'action', 'display'),
       (290, 31, 'format', 'tex'),
       (291, 31, 'module', 'template.pl'),
       (292, 31, 'name', 'check_multiple'),
       (293, 32, 'action', 'display'),
       (294, 32, 'format', 'tex'),
       (295, 32, 'module', 'template.pl'),
       (296, 32, 'name', 'envelope'),
       (297, 33, 'action', 'display'),
       (298, 33, 'format', 'tex'),
       (299, 33, 'module', 'template.pl'),
       (300, 33, 'name', 'shipping_label');
