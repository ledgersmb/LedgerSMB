-- VERSION 1.3.0

-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.
BEGIN;

DROP FUNCTION IF EXISTS employee__save
(in_entity_id int, in_start_date date, in_end_date date, in_dob date,
        in_role text, in_ssn text, in_sales bool, in_manager_id int,
        in_employeenumber text);

CREATE OR REPLACE FUNCTION employee__save
(in_entity_id int, in_start_date date, in_end_date date, in_dob date,
	in_role text, in_ssn text, in_sales bool, in_manager_id int,
        in_employeenumber text, in_is_manager bool)
RETURNS int AS $$
DECLARE out_id INT;
BEGIN
	UPDATE entity_employee
	SET startdate = coalesce(in_start_date, now()::date),
		enddate = in_end_date,
		dob = in_dob,
		role = in_role,
		ssn = in_ssn,
		manager_id = in_manager_id,
		employeenumber = in_employeenumber,
                is_manager = coalesce(in_is_manager, false),
                sales = in_sales
	WHERE entity_id = in_entity_id;

	out_id = in_entity_id;

	IF NOT FOUND THEN
		INSERT INTO entity_employee
			(startdate, enddate, dob, role, ssn, manager_id,
				employeenumber, entity_id, is_manager, sales)
		VALUES
			(coalesce(in_start_date, now()::date), in_end_date,
                                in_dob, in_role, in_ssn,
				in_manager_id, in_employeenumber,
                                in_entity_id, in_is_manager, in_sales);
		RETURN in_entity_id;
	END IF;
        RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION employee__save
(in_entity_id int, in_start_date date, in_end_date date, in_dob date,
        in_role text, in_ssn text, in_sales bool, in_manager_id int,
        in_employee_number text, in_is_manager bool) IS
$$ Saves an employeerecord with the specified information.$$;

drop function if exists  employee__get_user(in_entity_id int);
CREATE OR REPLACE FUNCTION employee__get_user(in_entity_id int)
RETURNS users AS
$$SELECT * FROM users WHERE entity_id = $1;$$ language sql;

COMMENT ON FUNCTION employee__get_user(in_entity_id int) IS
$$ Returns username, user_id, etc. information if the employee is a user.$$;

drop view if exists employees cascade;
create view employees as
    select
        s.salutation,
        p.first_name,
        p.last_name,
        ee.*
    FROM person p
    JOIN entity_employee ee USING (entity_id)
    LEFT JOIN salutation s ON (p.salutation_id = s.id);

GRANT select ON employees TO public;

DROP TYPE IF EXISTS employee_result CASCADE;

CREATE TYPE employee_result AS (
    entity_id int,
    control_code text,
    person_id int,
    salutation text,
    salutation_id int,
    first_name text,
    middle_name text,
    last_name text,
    is_manager bool,
    start_date date,
    end_date date,
    role varchar(20),
    ssn text,
    sales bool,
    manager_id int,
    manager_first_name text,
    manager_last_name text,
    employeenumber varchar(32),
    dob date,
    country_id int
);

CREATE OR REPLACE FUNCTION employee__all_managers()
RETURNS setof employee_result AS
$$
   SELECT p.entity_id, e.control_code, p.id, s.salutation, s.id,
          p.first_name, p.middle_name, p.last_name, ee.is_manager,
          ee.startdate, ee.enddate, ee.role, ee.ssn, ee.sales, ee.manager_id,
          mp.first_name, mp.last_name, ee.employeenumber, ee.dob, e.country_id
     FROM person p
     JOIN entity_employee ee on (ee.entity_id = p.entity_id)
     JOIN entity e ON (p.entity_id = e.id)
LEFT JOIN salutation s on (p.salutation_id = s.id)
LEFT JOIN person mp ON ee.manager_id = p.entity_id
    WHERE ee.is_manager
 ORDER BY ee.employeenumber;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION employee__get
(in_entity_id integer)
returns employee_result as
$$
   SELECT p.entity_id, e.control_code, p.id, s.salutation, s.id,
          p.first_name, p.middle_name, p.last_name, ee.is_manager,
          ee.startdate, ee.enddate, ee.role, ee.ssn, ee.sales, ee.manager_id,
          mp.first_name, mp.last_name, ee.employeenumber, ee.dob, e.country_id
     FROM person p
     JOIN entity_employee ee on (ee.entity_id = p.entity_id)
     JOIN entity e ON (p.entity_id = e.id)
LEFT JOIN salutation s on (p.salutation_id = s.id)
LEFT JOIN person mp ON ee.manager_id = p.entity_id
    WHERE p.entity_id = $1;
$$ language sql;

COMMENT ON FUNCTION employee__get (in_entity_id integer) IS
$$ Returns an employee_result tuple with information specified by the entity_id.
$$;

CREATE OR REPLACE FUNCTION employee__search
(in_employeenumber text, in_startdate_from date, in_startdate_to date,
in_first_name text, in_middle_name text, in_last_name text,
in_notes text, in_is_user bool)
RETURNS SETOF employee_result as
$$
SELECT p.entity_id, e.control_code, p.id, s.salutation, s.id,
          p.first_name, p.middle_name, p.last_name, ee.is_manager,
          ee.startdate, ee.enddate, ee.role, ee.ssn, ee.sales, ee.manager_id,
          mp.first_name, mp.last_name, ee.employeenumber, ee.dob, e.country_id
     FROM person p
     JOIN entity e ON p.entity_id = e.id
     JOIN entity_employee ee on (ee.entity_id = p.entity_id)
LEFT JOIN salutation s on (p.salutation_id = s.id)
LEFT JOIN person mp ON ee.manager_id = p.entity_id
    WHERE ($7 is null or p.entity_id in (select ref_key from entity_note
                                          WHERE note ilike '%' || $7 || '%'))
          and ($1 is null or $1 = ee.employeenumber)
          and ($2 is null or $2 <= ee.startdate)
          and ($3 is null or $3 >= ee.startdate)
          and ($4 is null or p.first_name ilike '%' || $4 || '%')
          and ($5 is null or p.middle_name ilike '%' || $5 || '%')
          and ($6 is null or p.last_name ilike '%' || $6 || '%')
          and ($8 is null
               or $8 = (exists (select 1 from users where entity_id = e.id)));
$$ language sql;

COMMENT ON FUNCTION employee__search
(in_employeenumber text, in_startdate_from date, in_startdate_to date,
in_first_name text, in_middle_name text, in_last_name text,
in_notes text, in_users bool) IS
$$ Returns a list of employee_result records matching the search criteria.

employeenumber is an exact match.
stardate_from and startdate_to specify the start dates for employee searches
All others are partial matches.

NULLs match all values.$$;

CREATE OR REPLACE FUNCTION employee__list_managers
(in_id integer)
RETURNS SETOF employees as
$$
		SELECT
		    s.salutation,
		    p.first_name,
		    p.last_name,
		    ee.*
		FROM entity_employee ee
		JOIN entity e on e.id = ee.entity_id
                JOIN person p ON p.entity_id = e.id
                JOIN salutation s ON s.id = p.salutation_id
		WHERE ee.sales = 't'::bool AND ee.role='manager'
			AND ee.entity_id <> coalesce(in_id, -1)
		ORDER BY name
$$ language sql;

COMMENT ON FUNCTION employee__list_managers
(in_id integer) IS
$$ Returns a list of managers, that is employees with the 'manager' role set.$$;

DROP VIEW IF EXISTS employee_search CASCADE;
CREATE OR REPLACE VIEW employee_search AS
SELECT e.*, em.name AS manager, emn.note, en.name as name
FROM entity_employee e
LEFT JOIN entity en on (e.entity_id = en.id)
LEFT JOIN entity_employee m ON (e.manager_id = m.entity_id)
LEFT JOIN entity em on (em.id = m.entity_id)
LEFT JOIN entity_note emn on (emn.ref_key = em.id);


CREATE OR REPLACE FUNCTION employee_search
(in_startdatefrom date, in_startdateto date, in_name varchar, in_notes text,
	in_enddateto date, in_enddatefrom date, in_sales boolean)
RETURNS SETOF employee_search AS
$$
		SELECT * FROM employee_search
		WHERE coalesce(startdate, 'infinity'::timestamp)
			>= coalesce(in_startdateto, '-infinity'::timestamp)
			AND coalesce(startdate, '-infinity'::timestamp) <=
				coalesce(in_startdatefrom,
						'infinity'::timestamp)
			AND coalesce(enddate, '-infinity'::timestamp) <=
				coalesce(in_enddateto, 'infinity'::timestamp)
			AND coalesce(enddate, 'infinity'::timestamp) >=
				coalesce(in_enddatefrom, '-infinity'::timestamp)
			AND (name ~*~ in_name
			    OR note ~*~ in_notes)
			AND (sales = 't' OR coalesce(in_sales, 'f') = 'f')
$$ language sql;

CREATE OR REPLACE FUNCTION employee__all_salespeople()
RETURNS setof employee_result LANGUAGE SQL AS
$$
   SELECT p.entity_id, e.control_code, p.id, s.salutation, s.id,
          p.first_name, p.middle_name, p.last_name, ee.is_manager,
          ee.startdate, ee.enddate, ee.role, ee.ssn, ee.sales, ee.manager_id,
          mp.first_name, mp.last_name, ee.employeenumber, ee.dob, e.country_id
     FROM person p
     JOIN entity_employee ee on (ee.entity_id = p.entity_id)
     JOIN entity e ON (p.entity_id = e.id)
LEFT JOIN salutation s on (p.salutation_id = s.id)
LEFT JOIN person mp ON ee.manager_id = p.entity_id
    WHERE ee.sales
 ORDER BY ee.employeenumber;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
