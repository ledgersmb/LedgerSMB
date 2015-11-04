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

DROP FUNCTION IF EXISTS wage__save
(in_rate numeric, in_entity_id int, in_type_id int);

CREATE OR REPLACE FUNCTION wage__save
(in_rate numeric, in_entity_id int, in_type_id int)
RETURNS payroll_wage
AS
$$
DECLARE
  return_wage payroll_wage;
BEGIN

UPDATE payroll_wage
   SET rate = in_rate
 WHERE entity_id = in_entity_id and in_type_id;


IF NOT FOUND THEN
    INSERT INTO payroll_wage (entity_id, type_id, rate)
    VALUES (in_entity_id, in_type_id, in_rate);
END IF;

SELECT * INTO return_wage FROM payroll_wage
             WHERE entity_id = in_entity_id and in_type_id;

RETURN return_wage;
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

DROP FUNCTION IF EXISTS deduction__save
(in_rate numeric, in_entity_id int, in_type_id int);

CREATE OR REPLACE FUNCTION deduction__save
(in_rate numeric, in_entity_id int, in_type_id int)
RETURNS payroll_deduction
AS
$$
DECLARE return_ded payroll_deduction;
BEGIN

UPDATE payroll_deduction
   SET rate = in_rate
 WHERE entity_id = in_entity_id and in_type_id;


IF NOT FOUND THEN
    INSERT INTO payroll_deduction (entity_id, type_id, rate)
    VALUES (in_entity_id, in_type_id, in_rate);
END IF;

SELECT * INTO return_ded FROM payroll_deduction
             WHERE entity_id = in_entity_id and in_type_id;
RETURN return_ded;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION payroll_income_type__get(in_id int)
RETURNS payroll_income_type AS $$
SELECT * FROM payroll_income_type WHERE id  = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION payroll_income_category__list()
RETURNS SETOF payroll_income_category AS $$
SELECT * FROM payroll_income_category order by id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION payroll_income_class__for_country(in_country_id int)
RETURNS SETOF payroll_income_class AS
$$
SELECT * FROM payroll_income_class where country_id = $1
ORDER BY label;
$$ language sql;

CREATE OR REPLACE FUNCTION payroll_income_type__save(
in_id int, in_account_id int, in_pic_id int, in_country_id int,
in_label text, in_unit text, in_default_amount numeric
) RETURNS payroll_income_type AS $$

   DECLARE retval payroll_income_type;

BEGIN
   UPDATE payroll_income_type
      SET account_id = in_account_id,
          pic_id = in_pic_id,
          country_id = in_country_id,
          label = in_label,
          unit = in_unit,
          default_amount = in_default_amount
    WHERE id = in_id;

   IF FOUND THEN
       retval := payroll_income_type__get(in_id);
       RETURN retval;
   END IF;

   INSERT INTO payroll_income_type
          (account_id, pic_id, country_id, label, unit, default_amount)
   VALUES (in_account_id, in_pic_id, in_country_id, in_label, in_unit,
           in_default_amount);

   retval := payroll_income_type__get(currval('payroll_income_type_id_seq')::int);
   RETURN retval;

END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION payroll_income_type__search
(in_account_id int, in_pic_id int, in_country_id int, in_label text,
in_unit text) RETURNS SETOF payroll_income_type
LANGUAGE SQL STABLE AS
$$
SELECT *
  FROM payroll_income_type
 where (account_id = $1 OR $1 IS NULL) AND
       (pic_id = $2 OR $2 IS NULL) AND
       (country_id = $3 OR $3 IS NULL) AND
       ($4 IS NULL OR label LIKE $4 || '%') AND
       (unit = $5 or $5 IS NULL);
$$;

CREATE OR REPLACE FUNCTION payroll_deduction_type__search
(in_account_id int, in_pdc_id int, in_country_id int, in_label text,
in_unit text) RETURNS SETOF payroll_deduction_type
LANGUAGE SQL STABLE AS
$$
SELECT *
  FROM payroll_deduction_type
 where (account_id = $1 OR $1 IS NULL) AND
       (pdc_id = $2 OR $2 IS NULL) AND
       (country_id = $3 OR $3 IS NULL) AND
       ($4 IS NULL OR label LIKE $4 || '%') AND
       (unit = $5 or $5 IS NULL);
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
