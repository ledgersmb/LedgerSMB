CREATE OR REPLACE FUNCTION tax_form__save(in_country_id int, in_form_name text, in_default_reportable bool)
RETURNS int AS
$$
BEGIN
	insert into country_tax_form(country_id,form_name, default_reportable) 
	values (in_country_id, in_form_name, in_default_reportable);

	RETURN currval('country_tax_form_id_seq');
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION tax_form__get(in_form_id int) 
returns country_tax_form
as $$
SELECT * FROM country_tax_form where id = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION tax_form__list_all()
RETURNS SETOF country_tax_form AS
$BODY$
SELECT * FROM country_tax_form ORDER BY country_id;
$BODY$ LANGUAGE SQL;

