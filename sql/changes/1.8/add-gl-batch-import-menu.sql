

CREATE OR REPLACE FUNCTION
menu_insert(in_parent_id int, in_position int, in_label text)
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


select menu_insert(73, 3, 'Import Batch');
insert into menu_acl (role_name, acl_type, node_id)
select role_name, acl_type, currval('menu_node_id_seq')
  from menu_acl
 where node_id = 245;

update menu_node
   set url = 'import_csv.pl?action=begin_import&type=gl_multi'
 where id = currval('menu_node_id_seq');


DROP FUNCTION menu_insert(int, int, text);
