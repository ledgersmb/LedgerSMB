BEGIN;

DROP FUNCTION IF EXISTS tax_form__save(in_id int, in_country_id int,
                          in_form_name text, in_default_reportable bool);
CREATE OR REPLACE FUNCTION tax_form__save(in_id int, in_country_id int,
                          in_form_name text, in_default_reportable bool,
                          in_is_accrual bool)
RETURNS int AS
$$
BEGIN
        UPDATE country_tax_form
           SET country_id = in_country_id,
               form_name =in_form_name,
               default_reportable = coalesce(in_default_reportable,false),
               is_accrual = coalesce(in_is_accrual, false)
         WHERE id = in_id;

        IF FOUND THEN
           RETURN in_id;
        END IF;

	insert into country_tax_form(country_id,form_name, default_reportable,
                                     is_accrual)
	values (in_country_id, in_form_name,
                coalesce(in_default_reportable, false),
                coalesce(in_is_accrual, false));

	RETURN currval('country_tax_form_id_seq');
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION tax_form__save(in_id int, in_country_id int,
                          in_form_name text, in_default_reportable bool,
                          in_is_accrual bool) IS
$$Saves tax form information to the database.$$;

CREATE OR REPLACE FUNCTION tax_form__get(in_form_id int)
returns country_tax_form
as $$
SELECT * FROM country_tax_form where id = $1;
$$ language sql;

COMMENT ON FUNCTION tax_form__get(in_form_id int) IS
$$ Retrieves specified tax form information from the database.$$;

DROP TYPE IF EXISTS tax_form_list CASCADE;

CREATE TYPE tax_form_list AS (
   id int,
   form_name text,
   country_name text,
   default_reportable bool,
   is_accrual bool
);

DROP FUNCTION IF EXISTS tax_form__list_all();
CREATE OR REPLACE FUNCTION tax_form__list_all()
RETURNS SETOF tax_form_list AS
$BODY$
SELECT tf.id, tf.form_name, c.name, tf.default_reportable, tf.is_accrual
  FROM country c
  JOIN country_tax_form tf ON c.id = tf.country_id
 ORDER BY country_id, form_name;
$BODY$ LANGUAGE SQL;

COMMENT ON FUNCTION tax_form__list_all() IS
$$ Returns a set of all tax forms, ordered by country_id and id$$;

DROP TYPE IF EXISTS taxform_list CASCADE;
CREATE TYPE taxform_list AS (
   id int,
   form_name text,
   country_id int,
   country_name text,
   default_reportable bool,
   is_accrual bool
);

CREATE OR REPLACE function tax_form__list_ext()
RETURNS SETOF taxform_list AS
$BODY$
SELECT t.id, t.form_name, t.country_id, c.name, t.default_reportable,
       t.is_accrual
  FROM country_tax_form t
  JOIN country c ON c.id = t.country_id
 ORDER BY c.name, t.form_name;
$BODY$ language sql;

COMMENT ON function tax_form__list_ext() IS
$$ Returns a list of tax forms with an added field, country_name, to specify the
name of the country.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
