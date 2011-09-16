UPDATE menu_attribute set attribute = 'depreciation' 
 where attribute = 'depreciate';

SELECT menu_insert(parent, position + 1, 'Disposal')
  FROM menu_node 
 WHERE label = 'Depreciate';

INSERT INTO menu_attribute(attribute, value, node_id)
     VALUES ('module', 'asset.pl', currval('menu_node_id_seq'));
INSERT INTO menu_attribute(attribute, value, node_id)
     VALUES ('action', 'new_report', currval('menu_node_id_seq'));
