

insert into menu_node (id, parent, position, label)
values (254, 128, 'Currency', 0),
       (255, 254, 'Edit currencies', 0),
       (256, 254, 'Edit rate types', 2),
       (257, 254, 'Edit rates', 254, 3);


insert into menu_attribute (id, node_id, attribute, value)
values (682, 254, 'menu', 128),
       (683, 255, 'module', 'currency.pl'),
       (684, 255, 'action', 'list_currencies'),
       (685, 256, 'module', 'currency.pl'),
       (686, 256, 'action', 'list_exchangerate_types'),
       (687, 257, 'module', 'currency.pl'),
       (688, 257, 'action', 'list_exchangerates');


select setval('menu_node_id_seq', 257, true);
select setval('menu_attribute_id_seq', 688, true);
