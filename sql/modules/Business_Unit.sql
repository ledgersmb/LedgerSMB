BEGIN;

CREATE OR REPLACE FUNCTION business_unit__list_classes(in_active bool)
RETURNS SETOF business_unit_class AS
$$

SELECT * FROM business_unit_class 
 WHERE active = $1 OR $1 IS NULL
ORDER BY ordering;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION business_unit__list_classes(in_active bool) IS
$$ This function lists all business unit clases.  If in_active is true, then 
only active classes are listed.  If it is false then only inactive classes are
listed.  If it is null, then all classes are listed.$$;

CREATE OR REPLACE FUNCTION business_unit_get(in_id int) RETURNS business_unit
AS
$$ SELECT * FROM business_unit WHERE id = $1; $$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION business_unit__list_by_class
(in_business_unit_class_id int, in_active_on date, in_credit_id int, 
in_strict_credit bool)
RETURNS SETOF business_unit AS
$$
BEGIN
RETURN QUERY SELECT * FROM business_unit 
              WHERE (in_active_on BETWEEN start_date AND end_date OR
                     in_active_in IS NULL)
                    AND (in_credit_id = credit_id
                        OR (credit_id IS NULL and in_strict_credit IS NOT TRUE)
                        OR (in_credit_id IS NULL))
                    AND class_id = in_business_unit_class_id
           ORDER BY control_code;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION business_unit__list_by_class
(in_business_unit_class_id int, in_active_on date, in_credit_id int,
in_strict_credit bool) IS
$$ This function retUrns a list of all units (projects, departments, funds, etc)
active on the in_active_on date, where in_credit_id matches the credit id of the
customer or vendor requested, and where in_business_uni_class_id is the class id
of the class of business units (1 for department, 2 for project, etc).

With the exception of in_business_unit_class_id, the null matches all records.
$$;

DROP TYPE IF EXISTS business_unit_short CASCADE;

CREATE TYPE business_unit_short AS (
id int,
control_code text,
description text,
start_date date,
end_date date,
parent_id int,
path int[],
level int
);

CREATE OR REPLACE FUNCTION business_unit__get_tree_for(in_id int)
RETURNS SETOF business_unit_short AS
$$
WITH RECURSIVE tree  (id, control_code, description,  start_date, end_date, 
                      parent_id, path, level)
AS (
   SELECT id, control_code, description, start_date, end_date, parent_id, 
          ARRAY[parent_id] AS path, 1 as level
     FROM business_unit WHERE $1 = id
    UNION
   SELECT t.id, t.control_code, t.description, t.start_date, t.end_date, 
          t.parent_id,   
          t.path || bu.id AS path, t.level + 1 as level
     FROM business_unit bu JOIN tree t ON t.parent_id = bu.id
)
SELECT * FROM tree ORDER BY path;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION business_unit__get_tree_for(in_id int) IS
$$ This function returns tree-related records with the root of the tree being 
the business unit of in_id.  $$;

CREATE OR REPLACE FUNCTION business_unit_class__save 
(in_id int, in_label text, in_active bool, in_non_accounting bool, in_ordering int)
RETURNS business_unit_class AS
$$
DECLARE retval business_unit_class;
        t_id int;
BEGIN

t_id := in_id;
UPDATE business_unit_class
   SET label = in_label,
       active = in_active,
       ordering = in_ordering,
       non_accounting = in_non_accounting
 WHERE id = in_id;

IF NOT FOUND THEN

   INSERT INTO business_unit_class (label, active, non_accounting, ordering)
   VALUES (in_label, in_active, in_non_accounting, in_ordering);

   t_id := currval('business_unit_class_id_seq');

END IF;

SELECT * INTO retval FROM business_unit_class WHERE id = t_id;

RETURN retval;

END;

$$LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION business_unit__save
(in_id int, in_class_id int, in_control_code text, in_description text,
in_start_date date, in_end_date date, in_parent_id int, in_credit_id int)
RETURNS business_unit AS
$$
DECLARE retval business_unit;
        t_id int;

BEGIN

UPDATE business_unit
   SET class_id = in_class_id,
       control_code = in_control_code,
       description = in_description,
       start_date = in_start_date,
       end_date = in_end_date,
       parent_id = in_parent_id,
       credit_id = in_credit_id
 WHERE id = in_id;


IF FOUND THEN
   t_id = in_id;
ELSE
   INSERT INTO business_unit 
          (class_id, control_code, description, start_date, end_date, parent_id,
           credit_id)
   VALUES (in_class_id, in_control_code, in_description, in_start_date, 
           in_end_date, in_parent_id, in_credit_id);
END IF;

SELECT * INTO retval FROM business_unit WHERE id = in_id;

RETURN retval;
END;
$$ LANGUAGE PLPGSQL;

COMMIT;
