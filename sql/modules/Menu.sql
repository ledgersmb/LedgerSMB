
set client_min_messages = 'warning';


BEGIN;

DROP TYPE IF EXISTS menu_item CASCADE;
CREATE TYPE menu_item AS (
   position int,
   id int,
   level int,
   label varchar,
   path varchar,
   parent int,
   standalone boolean,
   menu boolean,
   url text
);



CREATE OR REPLACE FUNCTION menu_generate() RETURNS SETOF menu_item AS
$$
WITH RECURSIVE tree (path, id, parent, level, positions)
AS (
   select id::text as path, id, parent,
          0 as level, position::text
     from menu_node where parent is null
    UNION
   select path || ',' || n.id::text, n.id,
          n.parent, t.level + 1, t.positions || ',' || n.position
     from menu_node n
     JOIN tree t ON t.id = n.parent
)
SELECT n.position, n.id, c.level, n.label, c.path, n.parent,
       n.standalone, n.menu, n.url
  FROM tree c
  JOIN menu_node n USING(id)
 WHERE n.id IN (select node_id
                  FROM menu_acl acl
             LEFT JOIN pg_roles pr on pr.rolname = acl.role_name
                 WHERE CASE WHEN role_name ilike 'public' THEN true
                            WHEN rolname IS NULL THEN FALSE
                            ELSE pg_has_role(rolname, 'USAGE')
                       END
                 GROUP BY node_id
                   HAVING bool_and(CASE WHEN acl_type ilike 'DENY' THEN FALSE
                                        WHEN acl_type ilike 'ALLOW' THEN TRUE
                                   END))
       OR exists (select cn.id, cc.path
                    FROM tree cc
                    JOIN menu_node cn USING(id)
                   WHERE cn.id IN (select node_id
                                     FROM menu_acl acl
                                LEFT JOIN pg_roles pr
                                          on pr.rolname = acl.role_name
                                    WHERE CASE WHEN rolname ilike 'public'
                                                    THEN true
                                               WHEN rolname IS NULL
                                                    THEN FALSE
                                               ELSE pg_has_role(rolname, 'USAGE')
                                          END
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                      END))
                         and cc.path::text like c.path::text || ',%')
 ORDER BY string_to_array(c.positions, ',')::int[]
$$ language sql;

COMMENT ON FUNCTION menu_generate() IS
$$
This function returns the complete menu tree.  It is used to generate nested
menus for the web interface.
$$;

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

comment on function menu_insert(int, int, text) is $$
This function inserts menu items at arbitrary positions.  The arguments are, in
order:  parent, position, label.  The return value is the id number of the menu
item created. $$;


DROP VIEW IF EXISTS menu_friendly;
CREATE VIEW menu_friendly AS
WITH RECURSIVE tree (path, id, parent, level, positions)
                               AS (select id::text as path, id, parent,
                                           0 as level, position::text
                                      FROM menu_node where parent is null
                                     UNION
                                    select path || ',' || n.id::text, n.id,
                                           n.parent,
                                           t.level + 1,
                                           t.positions || ',' || n.position
                                      FROM menu_node n
                                      JOIN tree t ON t.id = n.parent)
SELECT t."level", t.path,
       (repeat(' '::text, (2 * t."level")) || (n.label)::text) AS label,
        n.id, n."position"
   FROM tree t
   JOIN menu_node n USING (id)
  ORDER BY string_to_array(t.positions, ',')::int[];

COMMENT ON VIEW menu_friendly IS
$$ A nice human-readable view for investigating the menu tree.  Does not
show menu attributes or acls.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
