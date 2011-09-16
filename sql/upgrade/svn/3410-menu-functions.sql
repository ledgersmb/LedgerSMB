CREATE OR REPLACE FUNCTION menu_generate() RETURNS SETOF menu_item AS 
$$
DECLARE 
	item menu_item;
	arg menu_attribute%ROWTYPE;
BEGIN
	FOR item IN 
		SELECT n.position, n.id, c.level, n.label, c.path, 
                       to_args(array[ma.attribute, ma.value])
		FROM connectby('menu_node', 'id', 'parent', 'position', '0', 
				0, ',') 
			c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
		JOIN menu_node n USING(id)
                JOIN menu_attribute ma ON (n.id = ma.node_id)
               WHERE n.id IN (select node_id FROM menu_acl
                               WHERE pg_has_role(CASE WHEN role_name 
                                                           ilike 'public'
                                                      THEN current_user
                                                      ELSE role_name
                                                   END, 'USAGE')
                            GROUP BY node_id
                              HAVING bool_and(CASE WHEN acl_type ilike 'DENY'
                                                   THEN FALSE
                                                   WHEN acl_type ilike 'ALLOW'
                                                   THEN TRUE
                                                END))
                    or exists (select cn.id, cc.path
                                 FROM connectby('menu_node', 'id', 'parent', 
                                                'position', '0', 0, ',')
                                      cc(id integer, parent integer, 
                                         "level" integer, path text,
                                         list_order integer)
                                 JOIN menu_node cn USING(id)
                                WHERE cn.id IN 
                                      (select node_id FROM menu_acl
                                        WHERE pg_has_role(CASE WHEN role_name 
                                                           ilike 'public'
                                                      THEN current_user
                                                      ELSE role_name
                                                   END, 'USAGE')
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type 
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type 
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                         END))
                                       and cc.path like c.path || ',%')
            GROUP BY n.position, n.id, c.level, n.label, c.path, c.list_order
            ORDER BY c.list_order
                             
	LOOP
		RETURN NEXT item;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION menu_children(in_parent_id int) RETURNS SETOF menu_item
AS $$
declare 
	item menu_item;
	arg menu_attribute%ROWTYPE;
begin
        FOR item IN
		SELECT n.position, n.id, c.level, n.label, c.path, 
                       to_args(array[ma.attribute, ma.value])
		FROM connectby('menu_node', 'id', 'parent', 'position', 
				in_parent_id, 1, ',') 
			c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
		JOIN menu_node n USING(id)
                JOIN menu_attribute ma ON (n.id = ma.node_id)
               WHERE n.id IN (select node_id FROM menu_acl
                               WHERE pg_has_role(CASE WHEN role_name 
                                                           ilike 'public'
                                                      THEN current_user
                                                      ELSE role_name
                                                   END, 'USAGE')
                            GROUP BY node_id
                              HAVING bool_and(CASE WHEN acl_type ilike 'DENY'
                                                   THEN FALSE
                                                   WHEN acl_type ilike 'ALLOW'
                                                   THEN TRUE
                                                END))
                    or exists (select cn.id, cc.path
                                 FROM connectby('menu_node', 'id', 'parent', 
                                                'position', '0', 0, ',')
                                      cc(id integer, parent integer, 
                                         "level" integer, path text,
                                         list_order integer)
                                 JOIN menu_node cn USING(id)
                                WHERE cn.id IN 
                                      (select node_id FROM menu_acl
                                        WHERE pg_has_role(CASE WHEN role_name 
                                                           ilike 'public'
                                                      THEN current_user
                                                      ELSE role_name
                                                   END, 'USAGE')
                                     GROUP BY node_id
                                       HAVING bool_and(CASE WHEN acl_type 
                                                                 ilike 'DENY'
                                                            THEN false
                                                            WHEN acl_type 
                                                                 ilike 'ALLOW'
                                                            THEN TRUE
                                                         END))
                                       and cc.path like c.path || ',%')
            GROUP BY n.position, n.id, c.level, n.label, c.path, c.list_order
            ORDER BY c.list_order
        LOOP
                return next item;
        end loop;
end;
$$ language plpgsql;

