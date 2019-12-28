

CREATE OR REPLACE FUNCTION
pg_temp.menu_insert(in_parent_id int, in_position int, in_label text)
returns int
AS $$
DECLARE
        new_id int;
BEGIN
        UPDATE menu_node
            -- prevent duplicates by setting negative as a first step
           SET position = -1 * (position + 1)
         WHERE parent = in_parent_id
               AND position >= in_position;

        UPDATE menu_node
            -- negate again now that all numbers are final
           SET position = -1 * position
         WHERE parent = in_parent_id
               AND position < 0;

        INSERT INTO menu_node (parent, position, label)
        VALUES (in_parent_id, in_position, in_label);

        RETURN currval('menu_node_id_seq');
END;
$$ language plpgsql;


DO $$
DECLARE
  menu_id int;
  parent_menu_id int;
BEGIN
  SELECT pg_temp.menu_insert(
     (select id from menu_node where label = 'Goods and Services'),
     (select position from menu_node where label = 'Import Inventory'),
     'Import'
  ) INTO parent_menu_id;
  UPDATE menu_node
     SET menu = true
   WHERE id = parent_menu_id;

  SELECT pg_temp.menu_insert(parent_menu_id, 1, 'Goods') INTO menu_id;
  UPDATE menu_node
     SET url = 'import_csv.pl?action=begin_import&type=parts'
   WHERE id = menu_id;

  SELECT pg_temp.menu_insert(parent_menu_id, 2, 'Services') INTO menu_id;
  UPDATE menu_node
     SET url = 'import_csv.pl?action=begin_import&type=services'
   WHERE id = menu_id;

  SELECT pg_temp.menu_insert(parent_menu_id, 3, 'Overhead') INTO menu_id;
  UPDATE menu_node
     SET url = 'import_csv.pl?action=begin_import&type=overhead'
   WHERE id = menu_id;


  UPDATE menu_node
     SET label = 'Inventory',
         position = 4,
         parent = parent_menu_id
   WHERE id = (select id from menu_node where label = 'Import Inventory');

END;
$$ language plpgsql;
