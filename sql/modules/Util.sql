CREATE OR REPLACE FUNCTION parse_date(in_date date) returns date AS
$$ select $1; $$ language sql;

COMMENT ON FUNCTION parse_date IS $$ Simple way to cast a Perl string to a
date format of known type. $$;

CREATE OR REPLACE FUNCTION je_set_default_lines(in_rowcount int) returns int
as
$$
BEGIN
    UPDATE menu_attribute set value = $1 
     where node_id = 74 and attribute='rowcount';

    IF NOT FOUND THEN
         INSERT INTO menu_attribute (node_id, attribute, value)
              values (74, 'rowcount', $1);
    END IF;
    RETURN $1; 
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION je_get_default_lines() returns varchar as
$$
SELECT value FROM menu_attribute where node_id = 74 and attribute = 'rowcount';
$$ language sql; 

CREATE OR REPLACE FUNCTION department__list_all() RETURNS SETOF department AS
$$
SELECT * FROM department order by description;
$$ language sql;

CREATE OR REPLACE FUNCTION warehouse__list_all() RETURNS SETOF warehouse AS
$$
SELECT * FROM warehouse order by description;
$$ language sql;

CREATE OR REPLACE FUNCTION invoice__get_by_vendor_number
(in_meta_nunber text, in_invoice_number text)
RETURNS ap AS
$$
DECLARE retval ap;
BEGIN
	SELECT * INTO retval FROM ap WHERE entity_credit_id = 
		(select id from entity_credit_account where entity_class = 1
		AND meta_number = in_meta_number)
		AND invnumber = in_invoice_number;
	RETURN retval;
END;
$$ LANGUAGE PLPGSQL;
