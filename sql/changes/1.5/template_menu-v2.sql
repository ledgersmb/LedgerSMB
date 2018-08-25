
-- This code is required because of github issue #3588

-- The essence of that issue: when creating a new database,
-- scripts template_menu.sql and template_menu3.sql fail.

-- This script doesn't assume as much about the context of the menu
-- as the aforementioned scripts do. The most important thing
-- (being the reason the other scripts fail) is that this script
-- explicitly "creates room" for each node to be inserted into the menu
-- by "freeing up" the position in the menu this script wants to insert
-- the menu item into.

DO $$
BEGIN
  -- Create room to insert the nodes

  PERFORM 1 FROM menu_node
           WHERE id = 29;

  IF NOT FOUND THEN
    UPDATE menu_node
       SET position = position + 1
     WHERE position >= 18 AND parent = 156;

    INSERT INTO menu_node(id, parent, position, label)
    VALUES (29, 156, 18, 'Payment'); -- printPayment.html

    INSERT INTO menu_attribute(id, node_id, attribute, value)
    VALUES
       (256, 29, 'action', 'display'),
       (257, 29, 'format', 'html'),
       (258, 29, 'module', 'template.pl'),
       (259, 29, 'template_name', 'printPayment');
  END IF;



  PERFORM 1 FROM menu_node
           WHERE id = 30;

  IF NOT FOUND THEN
    UPDATE menu_node
       SET position = position + 1
     WHERE position >= 18 AND parent = 172;

    INSERT INTO menu_node(id, parent, position, label)
    VALUES (30, 172, 18, 'Check Base'); -- check_base.tex

    INSERT INTO menu_attribute(id, node_id, attribute, value)
    VALUES
       (260, 30, 'action', 'display'),
       (261, 30, 'format', 'tex'),
       (262, 30, 'module', 'template.pl'),
       (267, 30, 'template_name', 'check_base');
  END IF;


  PERFORM 1 FROM menu_node
           WHERE id = 31;

  IF NOT FOUND THEN
    UPDATE menu_node
       SET position = position + 1
     WHERE position >= 19 AND parent = 172;

    INSERT INTO menu_node(id, parent, position, label)
    VALUES (31, 172, 19, 'Multiple Checks'); -- check_multiple.tex

    INSERT INTO menu_attribute(id, node_id, attribute, value)
    VALUES
       (289, 31, 'action', 'display'),
       (290, 31, 'format', 'tex'),
       (291, 31, 'module', 'template.pl'),
       (292, 31, 'template_name', 'check_multiple');
  END IF;


  PERFORM 1 FROM menu_node
           WHERE id = 32;

  IF NOT FOUND THEN
    UPDATE menu_node
       SET position = position + 1
     WHERE position >= 20 AND parent = 172;

    INSERT INTO menu_node(id, parent, position, label)
    VALUES (32, 172, 20, 'Envelope'); -- envelope

    INSERT INTO menu_attribute(id, node_id, attribute, value)
    VALUES
       (293, 32, 'action', 'display'),
       (294, 32, 'format', 'tex'),
       (295, 32, 'module', 'template.pl'),
       (296, 32, 'template_name', 'envelope');
  END IF;


  PERFORM 1 FROM menu_node
           WHERE id = 33;

  IF NOT FOUND THEN
    UPDATE menu_node
       SET position = position + 1
     WHERE position >= 21 AND parent = 172;

    INSERT INTO menu_node(id, parent, position, label)
    VALUES (33, 172, 21, 'Shipping Label'); -- shipping_label.tex

    INSERT INTO menu_attribute(id, node_id, attribute, value)
    VALUES
       (297, 33, 'action', 'display'),
       (298, 33, 'format', 'tex'),
       (299, 33, 'module', 'template.pl'),
       (300, 33, 'template_name', 'shipping_label');
  END IF;

END;
$$ LANGUAGE plpgsql;
