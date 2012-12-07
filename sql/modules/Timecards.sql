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

CREATE OR REPLACE FUNCTION timecard__report(...)
RETURNS ...
LANGUAGE SQL AS
$$ ... 
$$;
