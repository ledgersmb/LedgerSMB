drop function employee__get(int);

CREATE TYPE employee_result AS (
    entity_id int,
    person_id int,
    salutation text,
    first_name text,
    middle_name text,
    last_name text,
    startdate date,
    enddate date,
    role varchar(20),
    ssn text,
    sales bool,
    manager_id int,
    manager_first_name text,
    manager_last_name text,
    employeenumber varchar(32),
    dob date
);

CREATE OR REPLACE FUNCTION employee__get
(in_entity_id integer)
returns employee_result as
$$
   SELECT p.entity_id, p.id, s.salutation,
          p.first_name, p.middle_name, p.last_name,
          ee.startdate, ee.enddate, ee.role, ee.ssn, ee.sales, ee.manager_id,
          mp.first_name, mp.last_name, ee.employeenumber, ee.dob
     FROM person p
     JOIN entity_employee ee on (ee.entity_id = p.entity_id)
LEFT JOIN salutation s on (p.salutation_id = s.id)
LEFT JOIN person mp ON ee.manager_id = p.entity_id
    WHERE p.entity_id = $1;
$$ language sql;

