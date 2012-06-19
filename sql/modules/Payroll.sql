BEGIN;
-- WAGE FUNCTIONS
CREATE OR REPLACE FUNCTION wage__list_for_entity(in_entity_id int)
RETURNS SETOF payroll_wage AS
$$
SELECT * FROM payroll_wage WHERE entity_id = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION wage__list_types(in_country_id int)
RETURNS SETOF payroll_income_type AS
$$ 
SELECT * FROM payroll_income_type where country_id = $1
$$ language sql;

CREATE OR REPLACE FUNCTION wage__save
(in_rate numeric, in_entity_id int, in_type_id int)
RETURNS SETOF payroll_wage
AS
$$ 
BEGIN

UPDATE payroll_wage
   SET rate = in_rate
 WHERE entity_id = in_entity_id and in_type_id;


IF NOT FOUND THEN
    INSERT INTO payroll_wage (entity_id, type_id, rate)
    VALUES (in_entity_id, in_type_id, in_rate);
END IF;
  
RETURN QUERY SELECT * FROM payroll_wage 
             WHERE entity_id = in_entity_id and in_type_id;
END;
$$ language plpgsql;

-- DEDUCTION FUNCTINS
CREATE OR REPLACE FUNCTION deduction__list_for_entity(in_entity_id int)
RETURNS SETOF payroll_deduction AS
$$
SELECT * FROM payroll_deduction WHERE entity_id = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION deduction__list_types(in_country_id int)
RETURNS SETOF payroll_deduction_type AS
$$ 
SELECT * FROM payroll_deduction_type where country_id = $1
$$ language sql;

CREATE OR REPLACE FUNCTION deductin__save
(in_rate numeric, in_entity_id int, in_type_id int)
RETURNS SETOF payroll_deduction
AS
$$ 
BEGIN

UPDATE payroll_deduction
   SET rate = in_rate
 WHERE entity_id = in_entity_id and in_type_id;


IF NOT FOUND THEN
    INSERT INTO payroll_deduction (entity_id, type_id, rate)
    VALUES (in_entity_id, in_type_id, in_rate);
END IF;
  
RETURN QUERY SELECT * FROM payroll_deduction
             WHERE entity_id = in_entity_id and in_type_id;
END;
$$ language plpgsql;


COMMIT;
