begin;

--Journal entry stored procedures for LedgerSMB
--Copyright (C) 2011, The LedgerSMB Core Team

--Permission granted to use this work in accordance with the GNU General Public
--License version 2 or at your option any later version.  Please see included
--LICENSE file for details.

-- This file contains many functions which are by nature security definer
-- functions.  The tradeoff security-wise is that we can more tightly control
-- what can be inserted into the tables via security definer functions, but
-- at the same time the opportunity for privilege escallation is also higher
-- because security definer functions to some extent break a declarative
-- security model.   As always avoid executing dynamic SQL as much as possible,
-- etc.

CREATE TYPE journal_entry_ext AS (
    id int,
    reference text,
    description text,
    journal int,
    journal_name text,
    post_date date,
    effective_start date,
    effective_end date,
    currency char(3),
    approved bool,
    is_template bool,
    entered_by int,
    entered_by_name text,
    approved_by int,
    approved_by_name text,
    lines journal_line[]
);

COMMENT ON TYPE journal_entry_ext IS
$$ Contains all relevant data for journal entries. $$;

CREATE OR REPLACE FUNCTION je_get (arg_id int) returns journal_entry_ext AS
$$
SELECT je.id, je.reference, je.journal, j.name, je.post_date,
       je.effective_start, je.effective_end, je.currency, je.approved,
       je.is_template, je.entered_by, ee.name, je.approved_by, ae.name,
       array_agg(row(jl.*))
  FROM journal_entry je
  JOIN journal j ON je.journal = j.id
  JOIN entity ee ON je.entered_by = ee.id
  JOIN entity ae ON je.approved_by = ae.id
  JOIN journal_line jl ON jl.je_id = je.id
 WHERE je.id = $1
 GROUP BY je.id, je.reference, je.journal, j.name, je.post_date,
       je.effective_start, je.effective_end, je.currency, je.approved,
       je.is_template, je.entered_by, ee.name, je.approved_by, ae.name;
$$ language sql;

COMMENT ON FUNCTION je_get (arg_id int) IS
$$ This is a simple function to retrieve the journal item of the id sent in the
search crieria.$$;

CREATE OR REPLACE FUNCTION je_approve (prop_id int) returns journal_entry_ext
AS $$
-- Must be security definer.  otherwise we risk giving people permission to
-- de-approve transactions which is bad, even with column perms.  --CT
UPDATE journal_entry
   SET approved = true,
       approved_by = person__get_my_entity_id()
 WHERE id = $1;

SELECT je_get($1);
$$ LANGUAGE SQL SECURITY DEFINER;

COMMENT ON FUNCTION je_approve (prop_id int) IS
$$ This function approvies the journal entry specified.$$;

CREATE OR REPLACE FUNCTION je_delete_unapproved(arg_id int)
RETURNS journal_entry_ext AS
$$
DELETE FROM journal_line
 WHERE je_id = (select id
                 from journal_entry
                where id = $1 and approved is false);

DELETE FROM journal_id
 WHERE id = $1 and approved is false;

SELECT je_get($1);
$$ language sql SECURITY DEFINER;

REVOKE EXECUTE ON je_approve FROM public;

CREATE OR REPLACE FUNCTION je_modify_and_approve (
prop_id int
prop_reference text,
prop_description text,
prop_post_date date,
prop_currency char(3),
prop_effective_start date,
prop_effective_end date,
prop_lines journal_line[]
) RETURNS journal_entry_ext AS
$$
DECLARE
    test bool;
BEGIN

-- error handling and checks before we begin
IF (pg_has_role(lsmb_role('draft_modify')) IS NOT TRUE THEN
    RAISE EXCEPTION 'Access denied';
END IF;

SELECT sum(amount) = 0 INTO test FROM expand(prop_lines);

IF TEST IS NOT TRUE THEN
   RAISE EXCEPTION 'Unbalanced transaction';
END IF;

SELECT approved IS FALSE INTO test FROM journal_entry WHERE id = prop_id;

IF TEST IS NOT TRUE THEN
   RAISE EXCEPTION 'Transaction laready approved';
END IF;

-- main function

DELETE FROM journal_line WHERE je_id = prop_id;

UPDATE journal_entry
   SET reference = prop_reference,
       description = prop_description,
       post_date = prop_post_date,
       effective_start = coalesce(prop_effective_start, prop_post_date),
       effective_end = coalesce(prop_effective_end, prop_post_date)
 WHERE id = prop_id

IF NOT FOUND THEN
    RAISE EXCEPTION 'Entry not found'
END IF;

INSERT INTO journal_line
            (je_id, account_id, amount, project_id, department_id)
     SELECT prop_id, account_id, amount, project_id, department_id
       FROM expand(prop_lines);

RETURN je_get(prop_id);

END;

$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION je_add(
prop_reference text,
prop_description text,
prop_journal int,
prop_post_date date,
prop_is_template bool,
prop_currency char(3),
prop_effective_start date,
prop_effective_end date,
prop_lines journal_line[]
) RETURNS journal_entry_ext AS
$$
DECLARE retval journal_entry_ext;
     test bool;
     separate_duties bool;
BEGIN
   -- must be security definer because otherwise we can't guarantee balanced
   -- transactions --CT
   SELECT sum(amount) = 0 into test FROM expand(prop_lines);
   IF test is not true
     RAISE EXCEPTION 'Unbalanced transaction';
   END IF;

   SELECT value <> '0' INTO separate_duties
     FROM defaults
    WHERE setting_key = 'separate_duties';

   INSERT INTO journal_entry
               (reference, description, journal, post_date, is_template,
               currency, effective_start, effective_end, approved)
        VALUES (prop_reference, prop_description, prop_journal, prop_post_date,
               prop_is_template, prop_currency,
               coalesce(prop_effective_start, prop_post_date),
               coalesce(prop_effective_end, prop_post_date),
               separate_duties is false);

   INSERT
     INTO journal_line
          (je_id, account_id, amount, project_id, department_id)
   SELECT currval('journal_entry_id_seq'), account_id, amount,
          project_id, department_id
     FROM expand(prop_lines);

   RETURN je_get(currval('journal_entry_id_seq'));
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION je_reverse
(arg_id int, arg_reference text, arg_post_date date)
RETURNS journal_entry_ext AS
$$
INSERT
  INTO journal_entry
       (reference, description, journal, post_date, is_template,
       currency, effective_start, effective_end, approved)
SELECT $2, description, journal, coalesce($3, post_date),
       0, currency, effective_strt, effective_end, d.value = '0'
  FROM journal_entry je, defaults d
 WHERE d.setting_key = 'separate_duties' and je.id = $1;

INSERT
  INTO journal_line
       (je_id, account_id, amount, project_id, department_id)
SELECT currval('journal_entry_id_seq'), account_id, amount * -1, project_id,
       department_id
  FROM journal_line
 WHERE je_id = $1;

SELECT je_get(currval('journal_entry_id_seq'));
$$ LANGUAGE SQL SECURITY DEFINER;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

commit;