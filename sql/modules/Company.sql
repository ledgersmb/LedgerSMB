-- BEGIN;

CREATE TYPE company_search_result AS (
	entity_id int,
	company_id int,
	entity_credit_id int,
	meta_number text,
	entity_class int,
	legal_name text,
	sic_code text,
	business_type text,
	curr text
);

CREATE OR REPLACE FUNCTION company__search
(in_account_class int, in_contact text, in_contact_info text[], 
	in_meta_number text, in_address text, in_city text, in_state text, 
	in_mail_code text, in_country text, in_date_from date, in_date_to date,
	in_business_id int, in_legal_name text)
RETURNS SETOF company_search_result AS $$
DECLARE
	out_row company_search_result;
	loop_count int;
	t_contact_info text[];
BEGIN
	t_contact_info = in_contact_info;


	FOR out_row IN
		SELECT e.id, c.id, ec.id, ec.meta_number, ec.entity_class, 
			c.legal_name, c.sic_code, b.description , ec.curr::text
		FROM entity e
		JOIN company c ON (e.id = c.entity_id)
		JOIN entity_credit_account ec ON (ec.entity_id = e.id)
		LEFT JOIN business b ON (ec.business_id = b.id)
		WHERE ec.entity_class = in_account_class
			AND (c.id IN (select company_id FROM company_to_contact
				WHERE contact LIKE ALL(t_contact_info))
				OR '' LIKE ALL(t_contact_info))
			
			AND (ec.meta_number = in_meta_number 
				OR in_meta_number IS NULL)
			AND (c.legal_name like '%' || in_legal_name || '%'
				OR in_legal_name IS NULL)
			AND ((in_address IS NULL AND in_city IS NULL 
					AND in_state IS NULL 
					AND in_country IS NULL)
				OR (c.id IN 
				(select company_id FROM company_to_location
				WHERE location_id IN 
					(SELECT id FROM location
					WHERE line_one 
						ilike '%' || 
							coalesce(in_address, '')
							|| '%'
						AND city ILIKE 
							'%' || 
							coalesce(in_city, '') 
							|| '%'
						AND state ILIKE
							'%' || 
							coalesce(in_state, '') 
							|| '%'
						AND mail_code ILIKE
							'%' || 
							coalesce(in_mail_code,
								'')
							|| '%'
						AND country_id IN 
							(SELECT id FROM country
							WHERE name LIKE '%' ||
								in_country ||'%'
								OR short_name
								ilike 
								in_country)))))
			AND (ec.business_id = 
				coalesce(in_business_id, ec.business_id)
				OR (ec.business_id IS NULL 
					AND in_business_id IS NULL))
			AND (ec.startdate <= coalesce(in_date_to, 
						ec.startdate)
				OR (ec.startdate IS NULL))
			AND (ec.enddate >= coalesce(in_date_from, ec.enddate)
				OR (ec.enddate IS NULL))
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ language plpgsql;	

CREATE OR REPLACE FUNCTION entity__save_notes(in_entity_id int, in_note text)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN
	-- TODO, change this to create vector too
	INSERT INTO entity_note (ref_key, note_class, entity_id, note, vector)
	VALUES (in_entity_id, 1, in_entity_id, in_note, '');

	SELECT currval('note_id_seq') INTO out_id;
	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION eca__save_notes(in_credit_id int, in_note text)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN
	-- TODO, change this to create vector too
	INSERT INTO eca_note (ref_key, note_class, note, vector)
	VALUES (in_credit_id, 3, in_note, '');

	SELECT currval('note_id_seq') INTO out_id;
	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION entity_credit_get_id_by_meta_number
(in_meta_number text, in_account_class int) 
returns int AS
$$
DECLARE out_credit_id int;
BEGIN
	SELECT id INTO out_credit_id 
	FROM entity_credit_account 
	WHERE meta_number = in_meta_number 
		AND entity_class = in_account_class;

	RETURN out_credit_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION entity_list_contact_class() 
RETURNS SETOF contact_class AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT * FROM contact_class ORDER BY id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ language plpgsql;


CREATE TYPE entity_credit_search_return AS (
        legal_name text,
        id int,
        entity_id int,
        entity_class int,
        discount numeric,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        meta_number text,
        business_id int,
        language_code text,
        pricegroup_id int,
        curr char(3),
        startdate date,
        enddate date,
        ar_ap_account_id int,
        cash_account_id int,
	tax_id text,
        threshold numeric
);

CREATE TYPE entity_credit_retrieve AS (
        id int,
        entity_id int,
        entity_class int,
        discount numeric,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        meta_number text,
        business_id int,
        language_code text,
        pricegroup_id int,
        curr text,
        startdate date,
        enddate date,
        ar_ap_account_id int,
        cash_account_id int,
        threshold numeric,
	control_code text,
	credit_id int
);

COMMENT ON TYPE entity_credit_search_return IS
$$ This may change in 1.4 and should not be relied upon too much $$;

CREATE OR REPLACE FUNCTION entity_credit_get_id
(in_entity_id int, in_entity_class int, in_meta_number text)
RETURNS int AS $$
DECLARE out_var int;
BEGIN
	SELECT id INTO out_var FROM entity_credit_account
	WHERE entity_id = in_entity_id 
		AND in_entity_class = entity_class
		AND in_meta_number = meta_number;

	RETURN out_var;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION entity__list_credit
(in_entity_id int, in_entity_class int) 
RETURNS SETOF entity_credit_retrieve AS
$$
DECLARE out_row entity_credit_retrieve;
BEGIN
	
	FOR out_row IN 
		SELECT  c.id, e.id, ec.entity_class, ec.discount,
			ec.taxincluded, ec.creditlimit, ec.terms, 
			ec.meta_number, ec.business_id, ec.language_code, 
			ec.pricegroup_id, ec.curr, ec.startdate, 
			ec.enddate, ec.ar_ap_account_id, ec.cash_account_id, 
			ec.threshold, e.control_code, ec.id
		FROM company c
		JOIN entity e ON (c.entity_id = e.id)
		JOIN entity_credit_account ec ON (c.entity_id = ec.entity_id)
		WHERE e.id = in_entity_id
			AND ec.entity_class = 
				CASE WHEN in_entity_class = 3 THEN 2
				     WHEN in_entity_class IS NULL 
					THEN ec.entity_class
				ELSE in_entity_class END
	LOOP

		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION company_retrieve (in_entity_id int) RETURNS company AS
$$
DECLARE t_company company;
BEGIN
	SELECT * INTO t_company FROM company WHERE entity_id = in_entity_id;
	RETURN t_company;
END;
$$ language plpgsql;

CREATE TYPE company_billing_info AS (
legal_name text,
meta_number text,
tax_id text,
street1 text,
street2 text,
street3 text,
city text,
state text,
mail_code text,
country text
);

CREATE OR REPLACE FUNCTION company_get_billing_info (in_id int) 
returns company_billing_info as
$$
DECLARE out_var company_billing_info;
	t_id INT;
BEGIN
	select c.legal_name, eca.meta_number, c.tax_id, a.line_one, a.line_two, a.line_three, 
		a.city, a.state, a.mail_code, cc.name
	into out_var
	FROM company c
	JOIN entity_credit_account eca ON (eca.entity_id = c.entity_id)
	JOIN eca_to_location cl ON (eca.id = cl.credit_id)
	JOIN location a ON (a.id = cl.location_id)
	JOIN country cc ON (cc.id = a.country_id)
	WHERE eca.id = in_id AND location_class = 1;

	RETURN out_var;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION company_save (
    in_id int, in_control_code text, in_entity_class int,
    in_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text
) RETURNS INT AS $$
DECLARE t_entity_id INT;
	t_company_id INT;
	t_control_code TEXT;
BEGIN
	t_company_id := in_id;

	IF in_control_code IS NULL THEN
		t_control_code := setting_increment('company_control');
	ELSE
		t_control_code := in_control_code;
	END IF;

	IF in_entity_id IS NULL THEN
		IF in_id IS NULL THEN
			RAISE NOTICE 'in_id is null';
			SELECT id INTO t_company_id FROM company
			WHERE entity_id = (SELECT id FROM entity WHERE 
				control_code = t_control_code);
		END IF;
		IF t_company_id IS NOT NULL THEN
			SELECT entity_id INTO t_entity_id FROM company
			WHERE id = t_company_id;
			
		END IF;
	ELSE
		t_entity_id := in_entity_id;
	END IF;
	IF t_entity_id IS NULL THEN
		INSERT INTO entity (name, entity_class, control_code)
		VALUES (in_name, in_entity_class, t_control_code);
		t_entity_id := currval('entity_id_seq');
	END IF;

	UPDATE company
	SET legal_name = in_name,
		tax_id = in_tax_id,
		sic_code = in_sic_code
	WHERE id = t_company_id;

	IF NOT FOUND THEN
		INSERT INTO company(entity_id, legal_name, tax_id, sic_code)
		VALUES (t_entity_id, in_name, in_tax_id, in_sic_code);

	END IF;
	RETURN t_entity_id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION entity_credit_save (
    in_credit_id int, in_entity_class int,
    in_entity_id int,
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric, 
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int, 
    in_language varchar(6), in_pricegroup_id int, 
    in_curr char, in_startdate date, in_enddate date, 
    in_threshold NUMERIC,
    in_ar_ap_account_id int, 
    in_cash_account_id int
    
) returns INT as $$
    
    DECLARE
        t_entity_class int;
        l_id int;
    BEGIN
            update entity_credit_account SET
                discount = in_discount,
                taxincluded = in_taxincluded,
                creditlimit = in_creditlimit,
                terms = in_terms,
                ar_ap_account_id = in_ar_ap_account_id,
                cash_account_id = in_cash_account_id,
                meta_number = in_meta_number,
                business_id = in_business_id,
                language_code = in_language,
                pricegroup_id = in_pricegroup_id,
                curr = in_curr,
                startdate = in_startdate,
                enddate = in_enddate,
                threshold = in_threshold,
                discount_terms = in_discount_terms
            where id = in_credit_id;
        
         IF FOUND THEN
            RETURN in_credit_id;
         ELSE
            INSERT INTO entity_credit_account (
                entity_id,
                entity_class,
                discount, 
                taxincluded,
                creditlimit,
                terms,
                meta_number,
                business_id,
                language_code,
                pricegroup_id,
                curr,
                startdate,
                enddate,
                discount_terms,
                threshold,
		ar_ap_account_id,
                cash_account_id
            )
            VALUES (
                in_entity_id,
                in_entity_class,
                in_discount / 100, 
                in_taxincluded,
                in_creditlimit,
                in_terms,
                in_meta_number,
                in_business_id,
                in_language,
                in_pricegroup_id,
                in_curr,
                in_startdate,
                in_enddate,
                in_discount_terms,
                in_threshold,
                in_ar_ap_account_id,
                in_cash_account_id
            );
            -- entity note class
            RETURN currval('entity_credit_account_id_seq');
       END IF;

    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION company__list_locations(in_entity_id int)
RETURNS SETOF location_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT l.id, l.line_one, l.line_two, l.line_three, l.city, 
			l.state, l.mail_code, c.name, lc.class
		FROM location l
		JOIN company_to_location ctl ON (ctl.location_id = l.id)
		JOIN location_class lc ON (ctl.location_class = lc.id)
		JOIN country c ON (c.id = l.country_id)
		WHERE ctl.company_id = (select id from company where entity_id = in_entity_id)
		ORDER BY lc.id, l.id, c.name
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE contact_list AS (
	class text,
	description text,
	contact text
);

CREATE OR REPLACE FUNCTION company__list_contacts(in_entity_id int) 
RETURNS SETOF contact_list AS $$
DECLARE out_row contact_list;
BEGIN
	FOR out_row IN
		SELECT cl.class, c.description, c.contact
		FROM company_to_contact c
		JOIN contact_class cl ON (c.contact_class_id = cl.id)
		WHERE company_id = 
			(select id FROM company 
			WHERE entity_id = in_entity_id)
	LOOP
		return next out_row;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION company__list_bank_account(in_entity_id int)
RETURNS SETOF entity_bank_account AS
$$
DECLARE out_row entity_bank_account%ROWTYPE;
BEGIN
	FOR out_row IN
		SELECT * from entity_bank_account where entity_id = in_entity_id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION entity__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text)
RETURNS int AS
$$
DECLARE out_id int;
BEGIN
	INSERT INTO entity_bank_account(entity_id, bic, iban)
	VALUES(in_entity_id, in_bic, in_iban);

	SELECT CURRVAL('entity_bank_account_id_seq') INTO out_id ;

	IF in_credit_id IS NOT NULL THEN
		UPDATE entity_credit_account SET bank_account = out_id
		WHERE id = in_credit_id;
	END IF;

	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION entity__save_bank_account
(in_entity_id int, in_bic text, in_iban text)
RETURNS int AS
$$
DECLARE out_id int;
BEGIN
	INSERT INTO entity_bank_account(entity_id, bic, iban)
	VALUES(in_entity_id, in_bic, in_iban);

	SELECT CURRVAL('entity_bank_account_id_seq') INTO out_id ;

	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION company__save_contact
(in_entity_id int, in_contact_class int, in_description text, in_contact text)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN
	INSERT INTO company_to_contact(company_id, contact_class_id, 
		description, contact)
	SELECT id, in_contact_class, in_description, in_contact FROM company
	WHERE entity_id = in_entity_id;

	RETURN 1;
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE entity_note_list AS (
	id int,
	note_class int,
	note text
);

CREATE OR REPLACE FUNCTION company__list_notes(in_entity_id int) 
RETURNS SETOF entity_note AS 
$$
DECLARE out_row record;
BEGIN
	FOR out_row IN
		SELECT *
		FROM entity_note
		WHERE ref_key = in_entity_id
		ORDER BY created
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
		
CREATE OR REPLACE FUNCTION eca__list_notes(in_credit_id int) 
RETURNS SETOF note AS 
$$
DECLARE out_row record;
	t_entity_id int;
BEGIN
	SELECT entity_id INTO t_entity_id
	FROM entity_credit_account
	WHERE id = in_credit_id;

	FOR out_row IN
		SELECT *
		FROM note
		WHERE (note_class = 3 and ref_key = in_credit_id) or
			(note_class = 1 and ref_key = t_entity_id)
		ORDER BY created
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION eca__list_notes(INT) FROM public;

CREATE OR REPLACE FUNCTION company__next_id() returns bigint as $$
    
    select nextval('company_id_seq');
    
$$ language 'sql';

CREATE OR REPLACE FUNCTION company__location_save (
    in_entity_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text, 
    in_city TEXT, in_state TEXT, in_mail_code text, in_country_code int,
    in_created date
) returns int AS $$
    BEGIN
    return _entity_location_save(
        in_entity_id, in_location_id,
        in_location_class, in_line_one, in_line_two, 
        '', in_city , in_state, in_mail_code, in_country_code);
    END;

$$ language 'plpgsql';

create or replace function _entity_location_save(
    in_entity_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text, 
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text, 
    in_country_code int
) returns int AS $$

    DECLARE
        l_row location;
        l_id INT;
	t_company_id int;
    BEGIN
	SELECT id INTO t_company_id
	FROM company WHERE entity_id = in_entity_id;

	DELETE FROM company_to_location
	WHERE company_id = t_company_id
		AND location_class = in_location_class
		AND location_id = in_location_id;

	SELECT location_save(in_line_one, in_line_two, in_line_three, in_city,
		in_state, in_mail_code, in_country_code) 
	INTO l_id;

	INSERT INTO company_to_location 
		(company_id, location_class, location_id)
	VALUES  (t_company_id, in_location_class, l_id);

	RETURN l_id;    
    END;

$$ language 'plpgsql';


create or replace function eca__location_save(
    in_credit_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text, 
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text, 
    in_country_code int
) returns int AS $$

    DECLARE
        l_row location;
        l_id INT;
    BEGIN

	DELETE FROM eca_to_location
	WHERE credit_id = in_credit_id
		AND location_class = in_location_class
		AND location_id = in_location_id;

	SELECT location_save(in_line_one, in_line_two, in_line_three, in_city,
		in_state, in_mail_code, in_country_code) 
	INTO l_id;

	INSERT INTO eca_to_location 
		(credit_id, location_class, location_id)
	VALUES  (in_credit_id, in_location_class, l_id);

	RETURN l_id;    
    END;

$$ language 'plpgsql';


CREATE OR REPLACE FUNCTION company_get_billing_info (in_id int) 
returns company_billing_info as
$$
DECLARE out_var company_billing_info;
	t_id INT;
BEGIN
	select c.legal_name, c.tax_id, a.line_one, a.line_two, a.line_three, 
		a.city, a.state, a.mail_code, cc.name
	into out_var
	FROM company c
	JOIN entity_credit_account eca ON (eca.entity_id = c.entity_id)
	JOIN eca_to_location cl ON (eca.id = cl.credit_id)
	JOIN location a ON (a.id = cl.location_id)
	JOIN country cc ON (cc.id = a.country_id)
	WHERE eca.id = in_id AND location_class = 1;

	RETURN out_var;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION eca__list_locations(in_credit_id int)
RETURNS SETOF location_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT l.id, l.line_one, l.line_two, l.line_three, l.city, 
			l.state, l.mail_code, c.name, lc.class
		FROM location l
		JOIN eca_to_location ctl ON (ctl.location_id = l.id)
		JOIN location_class lc ON (ctl.location_class = lc.id)
		JOIN country c ON (c.id = l.country_id)
		WHERE ctl.credit_id = in_credit_id
		ORDER BY lc.id, l.id, c.name
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION eca__list_contacts(in_credit_id int) 
RETURNS SETOF contact_list AS $$
DECLARE out_row contact_list;
BEGIN
	FOR out_row IN
		SELECT cl.class, c.description, c.contact
		FROM eca_to_contact c
		JOIN contact_class cl ON (c.contact_class_id = cl.id)
		WHERE credit_id = in_credit_id
	LOOP
		return next out_row;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION eca__save_contact
(in_credit_id int, in_contact_class int, in_description text, in_contact text)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN
	INSERT INTO eca_to_contact(credit_id, contact_class_id, 
		description, contact)
	VALUES (in_credit_id, in_contact_class, in_description, in_contact);

	RETURN 1;
END;
$$ LANGUAGE PLPGSQL;

-- COMMIT;
