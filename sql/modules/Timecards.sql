
set client_min_messages = 'warning';


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
  in_curr char(3),
  in_jctype int
)
RETURNS jcitems LANGUAGE PLPGSQL AS
$$
DECLARE retval jcitems;

BEGIN

UPDATE jcitems
   SET business_unit_id = in_business_unit_id,
       parts_id = in_parts_id,
       description = in_description,
       qty = in_qty,
       allocated = in_allocated,
       sellprice = in_sellprice,
       fxsellprice = in_fxsellprice,
       serialnumber = in_serialnumber,
       checkedin = in_checkedin,
       checkedout = in_checkedout,
       person_id = coalesce(in_person_id, person__get_my_id()),
       notes = in_notes,
       total = in_total,
       non_billable = in_non_billable,
       curr = in_curr,
       jctype = in_jctype
 WHERE id = in_id;

IF FOUND THEN
  SELECT * FROM jcitems INTO retval WHERE id = in_id;
  return retval;
END IF;

INSERT INTO jcitems
(business_unit_id, parts_id, description, qty, allocated, sellprice,
  fxsellprice, serialnumber, checkedin, checkedout, person_id, notes,
  total, non_billable, jctype, curr)
VALUES
(in_business_unit_id, in_parts_id, in_description, in_qty, in_allocated,
  in_sellprice, in_fxsellprice, in_serialnumber, in_checkedin, in_checkedout,
  coalesce(in_person_id, person__get_my_id()), in_notes, in_total,
  in_non_billable, in_jctype, in_curr);

SELECT * INTO retval FROM jcitems WHERE id = currval('jcitems_id_seq')::int;

RETURN retval;

END;
$$;

CREATE OR REPLACE FUNCTION timecard__delete(in_id int)
RETURNS bool
LANGUAGE SQL AS
$$
    WITH a AS (
        DELETE FROM jcitems j
        WHERE j.id = in_id
          AND j.allocated IS NULL
        RETURNING 1)
    SELECT COUNT(*) > 0;
$$;

CREATE OR REPLACE FUNCTION timecard__bu_class(in_id int)
returns business_unit_class LANGUAGE SQL AS
$$
SELECT * from business_unit_class
 where id in (select class_id from business_unit
               WHERE id in (select business_unit_id from jcitems
                             WHERE id = $1));
$$;

CREATE OR REPLACE FUNCTION timecard__parts
(in_timecard bool, in_service bool, in_partnumber text)
RETURNS SETOF parts LANGUAGE SQL AS
$$
SELECT *
  FROM parts
 WHERE not obsolete
       AND ($1 OR inventory_accno_id IS NULL)
       AND ($2 OR (income_accno_id IS NOT NULL
             AND inventory_accno_id IS NULL))
       AND ($3 IS NULL OR partnumber like $3 || '%')
 ORDER BY partnumber;
$$;

DROP TYPE IF EXISTS timecard_report_line CASCADE;
CREATE TYPE timecard_report_line AS (
   id int,
   description text,
   qty numeric,
   allocated numeric,
   checkedin time,
   checkedout time,
   transdate date,
   weekday double precision,
   workweek double precision,
   weekstarting date,
   partnumber text,
   business_unit_code text,
   business_unit_description text,
   employeenumber text,
   employee text,
   parts_id int,
   sellprice numeric,
   non_billable numeric,
   jctype int,
   notes text
);

CREATE OR REPLACE FUNCTION timecard__report
(in_business_units int[], in_partnumber text, in_person_id int,
in_date_from date, in_date_to date, in_open bool, in_closed bool,
in_jctype int)
RETURNS SETOF timecard_report_line
LANGUAGE SQL AS
$$
WITH RECURSIVE bu_tree (id, path) AS (
     SELECT id, id::text AS path, control_code, description
       FROM business_unit
      WHERE id = any(in_business_units) OR (in_business_units = '{}' OR in_business_units IS NULL and parent_id IS NULL)
      UNION
     SELECT bu.id, bu_tree.path || ',' || bu.id, bu.control_code, bu.description
       FROM business_unit bu
       JOIN bu_tree ON bu_tree.id = bu.parent_id
)
SELECT j.id, j.description, j.qty, j.allocated, j.checkedin::time as checkedin,
       j.checkedout::time as checkedout, j.checkedin::date as transdate,
       extract('dow' from j.checkedin) as weekday,
       extract('week' from j.checkedin) as workweek,
       date_trunc('week', j.checkedin)::date as weekstarting,
       p.partnumber, bu.control_code as business_unit_code,
       bu.description AS businessunit_description,
       ee.employeenumber, e.name AS employee, j.parts_id, j.sellprice,
       j.non_billable, j.jctype, j.notes
  FROM jcitems j
  JOIN parts p ON p.id = j.parts_id
  JOIN person pr ON pr.id = j.person_id
  JOIN entity_employee ee ON ee.entity_id = pr.entity_id
  JOIN entity e ON ee.entity_id = e.id
  LEFT JOIN bu_tree bu ON bu.id = j.business_unit_id
 WHERE (p.partnumber = in_partnumber OR in_partnumber IS NULL)
       AND (j.person_id = in_person_id OR in_person_id IS NULL)
       AND (j.checkedin::date >= in_date_from OR in_date_from IS NULL)
       AND (j.checkedin::date <= in_date_to OR in_date_to IS NULL)
       AND (((j.qty > j.allocated or j.allocated is null)  AND in_open)
            OR (j.qty <= j.allocated AND in_closed))
       AND (j.jctype = in_jctype OR in_jctype is null)
       AND (bu.path IS NOT NULL OR in_business_units = '{}' OR in_business_units IS NULL)
  ORDER BY j.checkedin, j.jctype, bu.description, p.partnumber, e.name
$$;

CREATE OR REPLACE FUNCTION timecard__allocate(in_id int, in_amount numeric)
returns jcitems
LANGUAGE PLPGSQL AS $$

DECLARE retval jcitems;

BEGIN

UPDATE jcitems SET allocated = allocated + in_amount WHERE id = in_id;

IF NOT FOUND THEN
   RAISE EXCEPTION 'timecard not found';
END IF;

SELECT * INTO retval FROM jcitems WHERE id = in_id;

IF allocated > qty THEN
   RAISE EXCEPTION 'Too many allocated';
END IF;

RETURN retval;

END;
$$;

-- Timecard Types

CREATE OR REPLACE FUNCTION timecard_type__get(in_id int) returns jctype
LANGUAGE sql AS $$

SELECT * FROM jctype where id = $1;

$$;

CREATE OR REPLACE FUNCTION timecard_type__list() RETURNS SETOF jctype
LANGUAGE SQL AS $$

SELECT * FROM jctype ORDER BY label;

$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
