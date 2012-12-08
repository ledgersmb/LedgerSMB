BEGIN;

CREATE OR REPLACE FUNCTION timecard__get(id int) RETURNS jcitems
LANGUAGE SQL AS
$$ SELECT * FROM jcitems WHERE id = $1; $$;

CREATE OR REPLACE FUNCTION timecard__save
(in_id int,
  in_business_unit_id int,
  in_parts_id int,
  in_description text,
  in_qty numeric,
  in_allocated numeric,
  in_sellprice NUMERIC,
  in_fxsellprice NUMERIC,
  in_serialnumber text,
  in_checkedin timestamp with time zone,
  in_checkedout timestamp with time zone,
  in_person_id integer,
  in_notes text,
  in_total numeric,
  in_non_billable numeric,
) 
RETURNS jcitems LANGUAGE PLPGSQL AS
$$
DECLARE retval jcitems;

BEGIN;

UPDATE jcitems 
   SET description = in_description,
       qty = in_qty,
       allocated = in_allocated,
       serialnumber = in_serialnumber,
       checkedin = in_checkedin,
       checkedout = in_checkedout,
       person_id = person__get_my_entity_id(),
       notes = in_notes,
       total = in_total,
       non_billable = in_non_billable
 WHERE id = in_id;

IF FOUND THEN
  SELECT * INTO retval WHERE id = in_id;
  return retval;
END IF;

INSERT INTO jcitems 
(business_unit_id, parts_id, description, qty, allocated, sellprice,
  fxsellprice, serialnumber, checkedin, checkedout, person_id, notes,
  total, non_billable)
VALUES
(in_business_unit_id, in_parts_id, in_description, in_qty, in_allocated, 
  in_sellprice, in_fxsellprice, in_serialnumber, in_checkedin, in_checkedout, 
  in_person_id, in_notes, in_total, in_non_billable);

SELECT * INTO retval WHERE id = currval('jcitems_id_seq')::int;

RETURN retval;

$$;

CREATE OR REPLACE FUNCTION timecard__parts(in_timecard bool, in_service bool)
RETURNS SETOF parts AS
$$
SELECT * 
  FROM parts
 WHERE not obsolete
       AND ($1 OR inventory_accno_id IS NULL)
       AND ($2 OR (income_accno_id IS NOT NULL 
             AND inventory_accno_id IS NULL))
 ORDER BY partnumber;
$$;

DROP TYPE IF EXISTS timecard_report_line;
CREATE TYPE timecard_report_line AS (
   id int,
   description text,
   qty numeric,
   allocated numeric,
   checkedin time,
   checkedout time,
   transdate date,
   weekday double,
   workweek text,
   partnumber text,
   business_unit_code text,
   business_unit_description text,
   employeenumber text, 
   employee text,
   parts_id int,
   sellprice numeric
); 

CREATE OR REPLACE FUNCTION timecard__report
(in_business_units int[], in_partnumber text, in_person_id int, 
in_date_from date, in_date_to date, in_open bool, in_closed bool)
RETURNS SETOF timecard_report_line
LANGUAGE SQL AS
$$
WITH RECURSIVE bu_tree (id, path) AS (
     SELECT id, id::text AS path, control_code, description
       FROM business_unit
      WHERE id = any(in_business_units)
      UNION
     SELECT bu.id, bu_tree.path || ',' || bu.id, control_code, description
       FROM business_unit bu
       JOIN bu_tree ON bu_tree.id = bu.parent_id
)
SELECT j.id, j.description, j.qty, j.allocated, j.checkedin::time as checkedin,
       j.checkedout::time as checkedout, j.checkedin::date as transdate,
       extract('dow' from j.checkedin) as weekday, 
       extract('week' from j.checkedin) as workweek,
       p.partnumber, bu.control_code as business_unit_code, 
       bu.description AS businessunit_description,
       ee.employeenumber, e.name AS employee, j.parts_id, j.sellprice
  FROM jcitems j
  JOIN parts p ON p.id = jc.parts_id
  JOIN person ON person.id = jc.person_id
  JOIN employee_entity ee ON ee.entity_id = person.entity_id
  JOIN entity e ON ee.entity_id = e.id
  JOIN bu_tree bu ON bu.id = j.business_unit_id
 WHERE (p.partnumber = $2 OR $2 IS NULL)
       AND (ee.entity_id = $3 OR $3 IS NULL)
       AND (j.checkedin::date <= $4 OR $4 IS NULL)
       AND (j.checkedin::date >= $5 OR $5 IS NULL)
       AND (j.qty > j.allocated AND $6)
       AND (j.qty <= j.allocated AND $7);
$$;
