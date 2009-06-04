CREATE OR REPLACE FUNCTION tax_form__save(in_country_id int, in_form_name text)
RETURNS int AS
$$
BEGIN
	insert into country_tax_form(country_id,form_name) 
	values (in_country_id, in_form_name);

	RETURN currval('country_tax_form_id_seq');
END;
$$ LANGUAGE PLPGSQL;
