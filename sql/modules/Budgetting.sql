
set client_min_messages = 'warning';


-- Beginnings of a budget module, released under the GPL v2 or later.
-- Copyright 2011 The LedgerSMB Core Team
--
-- Notes for future versions:
-- 1:  For 1.4, move to arrays of composites and unnest()
-- 2:  Move to new input argument semantics
-- 3:  Add array of composites to budget_info_ext for lines
-- 4:  Make department_id default to 0 and be not null
-- 5:  Convert type definitions to views.

BEGIN;

DROP TYPE IF EXISTS budget_info_ext CASCADE;

CREATE TYPE budget_info_ext AS (
   id INT,
   start_date date,
   end_date date ,
   reference text,
   description text,
   entered_by int,
   approved_by int,
   obsolete_by int,
   entered_at timestamp,
   approved_at timestamp,
   obsolete_at timestamp,
   entered_by_name text,
   approved_by_name text,
   obsolete_by_name text
);

COMMENT ON TYPE budget_info_ext IS
$$ This is the base budget_info type.  In 1.4, it will be renamed budget and
include an array of lines, but since we support 8.3, we cannot do that.

The id, start_date, end_date, reference, description, entered_by, approved_by,
entered_at, and approved_at fields reference the budget_info table.  The other
two fields refer to the possible joins. $$;

CREATE OR REPLACE FUNCTION budget__get_info(in_id int)
returns budget_info_ext AS
$$
select bi.id, bi.start_date, bi.end_date, bi.reference, bi.description,
       bi.entered_by, bi.approved_by, bi.obsolete_by, bi.entered_at,
       bi.approved_at, bi.obsolete_at,
       ee.name, ae.name, oe.name
  from budget_info bi
  JOIN entity ee ON bi.entered_by = ee.id
  LEFT JOIN entity ae ON bi.approved_by = ae.id
  LEFT JOIN entity oe ON bi.obsolete_by = oe.id
 where bi.id = $1;
$$ language sql;

COMMENT ON FUNCTION budget__get_info(in_id int) IS
$$ Selects the budget info. $$;

CREATE OR REPLACE FUNCTION budget__get_business_units(in_id int)
returns setof business_unit AS
$$ select bu.*
     FROM business_unit bu
     JOIN budget_to_business_unit b2bu ON b2bu.bu_id = bu.id
     JOIN budget_info bi ON bi.id = b2bu.budget_id
    WHERE bi.id = $1
 ORDER BY bu.class_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION budget__search(
   in_start_date date,
   in_end_date date ,
   in_includes_date date,
   in_reference text,
   in_description text,
   in_entered_by int,
   in_approved_by int,
   in_obsolete_by int,
   in_business_units int[],
   in_is_approved bool, in_is_obsolete bool
) RETURNS SETOF budget_info_ext AS
$$
select bi.id, bi.start_date, bi.end_date, bi.reference, bi.description,
       bi.entered_by, bi.approved_by, bi.obsolete_by, bi.entered_at,
       bi.approved_at, bi.obsolete_at,
       ee.name, ae.name, oe.name
  from budget_info bi
  JOIN entity ee ON bi.entered_by = ee.id
  LEFT JOIN entity ae ON bi.approved_by = ae.id
  LEFT JOIN entity oe ON bi.obsolete_by = oe.id
 WHERE (start_date = $1 or $1 is null) AND ($2 = end_date or $2 is null)
       AND ($3 BETWEEN start_date AND end_date or $2 is null)
       AND ($4 ilike reference || '%' or $4 is null)
       AND (bi.description @@ plainto_tsquery($5) or $5 is null)
       AND ($6 = entered_by or $6 is null)
       AND ($7 = approved_by or $7 is null)
       AND ($8 = obsolete_by or $8 is null)
       AND ($10 IS NULL OR ($10 = (approved_by IS NOT NULL)))
       AND ($11 IS NULL OR ($11 = (obsolete_by IS NOT NULL)))
 ORDER BY reference;
$$ language sql;

COMMENT ON FUNCTION budget__search(
   in_start_date date,
   in_end_date date ,
   in_includes_date date,
   in_reference text,
   in_description text,
   in_entered_by int,
   in_approved_by int,
   in_obsolete_by int,
   in_business_units int[],
   in_is_approved bool,
   in_is_obsolete bool
)  IS $$ This is a general search for budgets$$;

CREATE OR REPLACE FUNCTION budget__save_info
(in_id int, in_start_date date, in_end_date date, in_reference text,
in_description text, in_business_units int[])
RETURNS budget_info_ext AS
$$
DECLARE
   retval budget_info_ext;
   t_id int;
BEGIN

   PERFORM * FROM budget_info WHERE id = in_id and approved_by is not null;
   IF FOUND THEN
       RAISE EXCEPTION 'report approved';
   END IF;

  UPDATE budget_info
     SET start_date = in_start_date,
         end_date = in_end_date,
         reference = in_reference,
         description = in_description
   WHERE id = in_id and approved_by is null;
  IF FOUND THEN
      t_id := in_id;
  ELSE
       INSERT INTO budget_info (start_date, end_date, reference, description)
            VALUES (in_start_date, in_end_date, in_reference, in_description);
       t_id = currval('budget_info_id_seq');

       INSERT INTO budget_to_business_unit(budget_id, bu_id, bu_class)
       SELECT t_id, id, class_id
         FROM business_unit
        WHERE id = ANY(in_business_units);
  END IF;
  retval := budget__get_info(t_id);
  return retval;
END;
$$ security definer language plpgsql;

COMMENT ON FUNCTION budget__save_info
(in_id int, in_start_date date, in_end_date date, in_reference text,
in_description text, in_business_units int[]) IS
$$Saves the extended budget info passed through to the function.  See the
comment on type budget_info_ext for more information.$$;

CREATE OR REPLACE FUNCTION budget__approve(in_id int)
RETURNS budget_info_ext AS $$
UPDATE budget_info
   set approved_at = now(), approved_by = person__get_my_entity_id()
 WHERE id = $1;

SELECT budget__get_info($1);
$$ language sql;

CREATE OR REPLACE FUNCTION budget__save_details(in_id int, in_details text[])
RETURNS budget_info_ext AS
$$
DECLARE
   loop_count int;
   retval budget_info_ext;
BEGIN
    FOR loop_count in
        array_lower(in_details, 1) ..
        array_upper(in_details, 1)
    LOOP
        INSERT INTO budget_line
                    (budget_id,
                     account_id,
                     description,
                     amount)
             VALUES (in_id,
                     in_details[loop_count][1]::int,
                     in_details[loop_count][2],
                     in_details[loop_count][3]::numeric);
    END LOOP;
    retval := budget__get_info(in_id);
    return retval;
END;
$$ language plpgsql;

COMMENT ON FUNCTION budget__save_details(in_id int, in_details text[]) IS
$$ This saves the line items for the budget.  in_details is an array n long
where each entry is {int account_id, text description, numeric amount}.  The
in_id parameter is the budget_id.$$;

DROP TYPE IF EXISTS budget_line_details CASCADE;

CREATE TYPE budget_line_details AS (
    budget_id int,
    account_id int,
    description text,
    amount numeric,
    accno text,
    acc_desc text,
    debit numeric,
    credit numeric
);


DROP FUNCTION IF EXISTS budget__get_details(int) CASCADE;
CREATE OR REPLACE FUNCTION budget__get_details(in_id int)
RETURNS SETOF budget_line_details AS
$$
  SELECT l.budget_id, l.account_id, l.description, l.amount,
         a.accno, a.description,
         CASE WHEN l.amount < 0 THEN l.amount * -1 ELSE NULL END,
         CASE WHEN l.amount > 0 THEN l.amount ELSE NULL END
    FROM budget_line l
    JOIN account a ON a.id = l.account_id
   where budget_id = $1;
$$ language sql;

COMMENT ON FUNCTION budget__get_details(in_id int) IS
$$ This retrieves the budget lines associated with a budget.$$;

CREATE OR REPLACE FUNCTION budget__get_notes(in_id int)
RETURNS SETOF budget_note AS
$$
   SELECT * FROM budget_note WHERE ref_key = $1;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION budget__get_notes(in_id int) IS
$$ Retrieves the notes associated with the budget.$$;

CREATE OR REPLACE FUNCTION budget__save_note
(in_id int, in_subject text, in_note text)
RETURNS budget_note AS
$$
INSERT INTO budget_note (subject, note, ref_key)
  values ($2, $3, $1)
RETURNING *;
$$ language sql;

COMMENT ON FUNCTION budget__save_note
(in_id int, in_subject text, in_note text) IS
$$ Saves a note attached to a budget.$$;

CREATE OR REPLACE FUNCTION budget__get_notes(in_id int)
RETURNS SETOF budget_note AS
$$
SELECT * FROM budget_note WHERE ref_key = $1
 ORDER BY created;
$$ language sql;

COMMENT ON FUNCTION budget__get_notes(in_id int) IS
$$ Returns all notes associated with a budget, by default in the order they
were created.$$;

DROP TYPE IF EXISTS budget_variance_report CASCADE;
CREATE TYPE budget_variance_report AS (
    accno text,
    account_label text,
    account_id int,
    budget_description text,
    budget_amount numeric,
    used_amount numeric,
    variance numeric
);

COMMENT ON TYPE budget_variance_report IS
$$ This is the base type for the budget variance report.$$;

CREATE OR REPLACE FUNCTION budget__variance_report(in_id int)
RETURNS SETOF budget_variance_report
AS
$$
   WITH agg_account (amount, id, transdate)
        AS ( SELECT ac.amount_bc *
                    CASE WHEN a.contra THEN -1 ELSE 1 END *
                    CASE WHEN a.category IN ('A', 'E') THEN -1 ELSE 1 END
                    AS amount,
                    ac.chart_id, ac.transdate
               FROM acc_trans ac
               JOIN account a ON ac.chart_id = a.id
           )
   SELECT act.accno, act.description, act.id, b.description, b.amount,
          coalesce(sum(a.amount), 0),
          b.amount - coalesce(sum(a.amount), 0) AS variance
     FROM budget_info bi
     JOIN budget_line b ON bi.id = b.budget_id
     JOIN account act ON act.id = b.account_id
LEFT JOIN agg_account a ON a.transdate BETWEEN bi.start_date and bi.end_date
                           AND a.id = b.account_id
    WHERE bi.id = $1
 GROUP BY act.accno, act.description, act.id, b.description, b.amount
 ORDER BY act.accno;
$$ language sql;

COMMENT ON FUNCTION budget__variance_report(in_id int) IS
$$ Retrieves a variance report for budget with an id of in_id.$$;

CREATE OR REPLACE FUNCTION budget__mark_obsolete(in_id int)
RETURNS budget_info_ext AS
$$
UPDATE budget_info
   set obsolete_by = person__get_my_entity_id(), obsolete_at = now()
 WHERE id = $1 and approved_by is not null;
SELECT budget__get_info($1)
$$ language sql;

COMMENT ON FUNCTION budget__mark_obsolete(in_id int) IS
$$ Marks a budget as obsolete $$;

CREATE OR REPLACE FUNCTION budget__reject(in_id int)
RETURNS bool AS
$$
BEGIN

DELETE FROM budget_line
 WHERE budget_id IN (SELECT id from budget_info
                      WHERE id = in_id AND approved_by IS NULL);

DELETE FROM budget_to_project
 WHERE budget_id IN (SELECT id from budget_info
                      WHERE id = in_id AND approved_by IS NULL);

DELETE FROM budget_to_department
 WHERE budget_id IN (SELECT id from budget_info
                      WHERE id = in_id AND approved_by IS NULL);

DELETE FROM budget_info WHERE id = in_id AND approved_by IS NULL;

RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;
REVOKE EXECUTE ON FUNCTION budget__reject(in_id int) FROM public;

COMMENT ON FUNCTION budget__reject(in_id int) IS
$$ Deletes unapproved budgets only.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';


COMMIT;
