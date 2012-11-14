-- Many of these will have to be rewritten to work with 1.4

CREATE OR REPLACE FUNCTION journal__add(
in_source text,
in_description text,
in_entry_type int,
in_transaction_date date,
in_approved bool,
in_is_template bool
) RETURNS journal AS 
$$
DECLARE retval journal;
BEGIN
	INSERT INTO journal_entry (source, description, entry_type, transaction_date,
			approved, is_template)
	VALUES (in_source, in_description, in_entry_type, in_transaction_date,
			coalesce(in_approved, false), 
			coalesce(in_is_template, false));

	SELECT * INTO retval FROM journal WHERE id = currval('journal_id_seq');
	RETURN retval;
END;
$$ language plpgsql; 

CREATE OR REPLACE FUNCTION journal__add_line(
in_account_id int, in_journal_id int, in_amount numeric, 
in_cleared bool, in_memo text, in_business_units int[],
) RETURNS journal_line AS $$
DECLARE retval journal_line;
BEGIN
	INSERT INTO journal_line(account_id, journal_id, amount, cleared, memo)
	VALUES (in_account_id, in_journal_id, in_amount, 
		coalesce(in_cleared, false), in_memo);

        INSERT INTO business_unit_jl(entry_id, bu_class, bu_id)
        SELECT currval('journal_line_line_id_seq'), business_unit_class, bu
          FROM business_unit
         WHERE id = any(in_business_units);

	SELECT * INTO retval FROM journal_line where line_id = currval('journal_line_line_id_seq');
	return retval;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION journal__validate_entry(in_id int) RETURNS bool AS
$$
	SELECT sum(amount) = 0 FROM journal_line WHERE journal_id = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION journal__make_invoice(
in_order_id int,  in_journal_id int, in_on_hold bool, in_reverse bool,
in_credit_id int, in_language_code varchar
) returns eca_invoice AS $$
DECLARE retval eca_invoice;
BEGIN	
	INSERT INTO eca_invoice (order_id, journal_id, on_hold, reverse,
		credit_id, language_code)
	VALUES (in_order_id, in_journal_id, coalesce(in_on_hold, false), 
		in_reverse, in_credit_id, in_language_code);

	SELECT * INTO retval FROM eca_invoice WHERE journal_id = in_journal_id;

	RETURN retval;
END;
$$ language plpgsql;

CREATE TYPE journal_search_result AS (
id bigint,
source text,
description text,
entry_type int,
transaction_date date,
approved bool,
is_template bool,
meta_number text,
entity_name text,
entity_class text
);

CREATE OR REPLACE FUNCTION journal__search(
in_source text,
in_description text,
in_entry_type int,
in_transaction_date date,
in_approved bool,
in_department_id int, 
in_is_template bool,
in_meta_number text,
in_entity_class int	
) RETURNS SETOF journal_search_result AS $$
DECLARE retval journal_search_result;
BEGIN
	FOR retval IN 
		SELECT j.id, j.source, j.description, j.entry_type, 
			j.transaction_date, j.approved, 
			j.is_template, eca.meta_number, 
			e.name, ec.class
		FROM journal_entry j
		LEFT JOIN eca_invoice i ON (i.journal_id = j.id)
		LEFT JOIN entity_credit_account eca ON (eca.id = credit_id)
		LEFT JOIN entity e ON (eca.entity_id = e.id)
		LEFT JOIN entity_class ec ON (eca.entity_class = ec.id)
		WHERE (in_source IS NULL OR in_source = j.source) AND
			(in_description IS NULL 
				or in_description = j.description) AND
			(in_entry_type is null or in_entry_type = j.entry_type)
			and (in_transaction_date is null 
				or in_transaction_date = j.transaction_date) and
			j.approved = coalesce(in_approved, true) and
			j.is_template = coalesce(in_is_template, false) and
			(in_department_id is null 
				or j.department_id = in_department_id) and
			(in_meta_number is null 
				or eca.meta_number = in_meta_number) and
			(in_entity_class is null
				or eca.entity_class = in_entity_class)
	LOOP
		RETURN NEXT retval;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION journal__get_invoice(in_id int) RETURNS eca_invoice AS
$$
SELECT * FROM eca_invoice where journal_id = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION journal__get_entry(in_id int) RETURNS journal AS
$$
SELECT * FROM journal_entry where id = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION journal__lines(in_id int) RETURNS SETOF journal_line AS
$$
select * from journal_line where journal_id = $1;
$$ language sql;
-- orders with inventory not supported yet.
