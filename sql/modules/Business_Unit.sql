BEGIN;

CREATE OR REPLACE FUNCTION business_unit__list_classes(in_active bool, in_module text)
RETURNS SETOF business_unit_class AS
$$

SELECT bc.*
  FROM business_unit_class bc
 WHERE     (active = $1 OR $1 IS NULL)
       AND (id IN (select bu_class_id
                     FROM bu_class_to_module bcm
                     JOIN lsmb_module mod ON mod.id = bcm.module_id
                    WHERE lower(label) = lower($2))
            OR $2 is null)
ORDER BY ordering;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION business_unit__list_classes(in_active bool, in_module text) IS
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
SELECT * FROM business_unit
              WHERE (in_active_on BETWEEN coalesce(start_date, in_active_on)
                                      AND coalesce(end_date, in_active_on)
                      OR in_active_on IS NULL)
                    AND (in_credit_id = credit_id
                        OR (credit_id IS NULL and in_strict_credit IS NOT TRUE)
                        OR (in_credit_id IS NULL))
                    AND class_id = in_business_unit_class_id
           ORDER BY control_code;
$$ LANGUAGE SQL;

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

CREATE OR REPLACE FUNCTION business_unit_class__save_modules
(in_id int, in_mod_ids int[])
RETURNS BOOL AS
$$
DELETE FROM bu_class_to_module WHERE bu_class_id = $1;

INSERT INTO bu_class_to_module (bu_class_id, module_id)
SELECT $1, unnest
  FROM unnest($2);

SELECT true;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION business_unit_class__get_modules(in_id int)
RETURNS SETOF lsmb_module AS
$$ SELECT * FROM lsmb_module
    WHERE id IN (select module_id from bu_class_to_module where bu_class_id = $1)
 ORDER BY id;
$$ language sql;

CREATE OR REPLACE FUNCTION business_unit_class__save
(in_id int, in_label text, in_active bool, in_ordering int)
RETURNS business_unit_class AS
$$
DECLARE retval business_unit_class;
        t_id int;
BEGIN

t_id := in_id;
UPDATE business_unit_class
   SET label = in_label,
       active = in_active,
       ordering = in_ordering
 WHERE id = in_id;

IF NOT FOUND THEN

   INSERT INTO business_unit_class (label, active, ordering)
   VALUES (in_label, in_active, in_ordering);

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
       credit_id = in_credit_id
 WHERE id = in_id;


IF FOUND THEN
   t_id := in_id;
ELSE
   INSERT INTO business_unit
          (class_id, control_code, description, start_date, end_date, parent_id,
           credit_id)
   VALUES (in_class_id, in_control_code, in_description, in_start_date,
           in_end_date, in_parent_id, in_credit_id);
    t_id := currval('business_unit_id_seq');
END IF;

SELECT * INTO retval FROM business_unit WHERE id = t_id;

RETURN retval;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION business_unit__get(in_id int)
RETURNS business_unit AS
$$ SELECT * FROM business_unit where id = $1; $$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION eca_bu_trigger() RETURNS TRIGGER AS
$$
BEGIN
  IF TG_OP = 'INSERT' THEN
      INSERT INTO business_unit(class_id, control_code, description, credit_id)
      SELECT 7 - NEW.entity_class, NEW.meta_number,  e.name, NEW.id
             FROM entity e WHERE e.id = NEW.entity_id;
  ELSIF TG_OP = 'UPDATE' THEN
      IF new.meta_number <> old.meta_number THEN
         UPDATE business_unit SET control_code = new.meta_number
          WHERE class_id = 7 - NEW.entity_class
                AND credit_id = new.id;
      END IF;
  ELSIF TG_OP = 'DELETE'THEN
      DELETE FROM business_unit WHERE class_id = 7 - OLD.entity_class
                  AND credit_id = OLD.id;
      RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

DROP TRIGGER IF EXISTS eca_maintain_b_units ON entity_credit_account;
DROP TRIGGER IF EXISTS eca_maintain_b_units_del ON entity_credit_account;

CREATE TRIGGER eca_maintain_b_units AFTER INSERT OR UPDATE
       ON entity_credit_account
       FOR EACH ROW EXECUTE PROCEDURE eca_bu_trigger();

CREATE TRIGGER eca_maintain_b_units_del BEFORE DELETE
       ON entity_credit_account
       FOR EACH ROW EXECUTE PROCEDURE eca_bu_trigger();


update defaults set value = 'yes' where setting_key = 'module_load_ok';


COMMIT;
