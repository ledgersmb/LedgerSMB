
-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General 
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

BEGIN;

DROP TYPE IF EXISTS  company_search_result CASCADE;

CREATE TYPE company_search_result AS (
	entity_id int,
	entity_control_code text,
	company_id int,
	entity_credit_id int,
	meta_number text,
	credit_description text,
	entity_class int,
	legal_name text,
	sic_code text,
	business_type text,
	curr text
);

DROP TYPE IF EXISTS eca_history_result CASCADE;

create type eca_history_result as (
   id int,
   name text,
   meta_number text,
   inv_id int,
   invnumber text,
   curr text,
   parts_id int,
   partnumber text,
   description text,
   qty numeric,
   unit text,
   sellprice numeric,
   discount numeric,
   delivery_date date,
   project_id int,
   projectnumber text,
   serialnumber text,
   exchngerate numeric,
   salesperson_id int,
   salesperson_name text
);

CREATE OR REPLACE FUNCTION eca_history
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text, 
 in_country_id int, in_from_date date, in_to_date date, in_type char(1), 
 in_start_from date, in_start_to date, in_account_class int, 
 in_inc_open bool, in_inc_closed bool)
RETURNS SETOF  eca_history_result AS
$$
     SELECT eca.id, e.name, eca.meta_number, 
            a.id as invoice_id, a.invnumber, a.curr::text, 
            p.id AS parts_id, p.partnumber, 
            i.description, i.qty, i.unit::text, i.sellprice, i.discount, 
            i.deliverydate, pr.id as project_id, pr.projectnumber,
            i.serialnumber, 
            case when $16 = 1 then xr.buy else xr.sell end as exchange_rate,
            ee.id as salesperson_id, 
            ep.last_name || ', ' || ep.first_name as salesperson_name
     FROM (select * from entity_credit_account 
            where meta_number = $2
           UNION 
          select * from entity_credit_account WHERE $2 is null
          ) eca  -- broken into unions for performance
     join entity e on eca.entity_id = e.id
     JOIN (select  invnumber, curr, transdate, entity_credit_account, id,
                   person_id
             FROM ar 
            where $16 = 2 and $13 = 'i'
                  and (($17 and amount = paid) or ($18 and amount <> paid))
            UNION 
           select invnumber, curr, transdate, entity_credit_account, id,
                  person_id
             FROM ap 
            where $16 = 1 and $13 = 'i'
                  and (($17 and amount = paid) or ($18 and amount <> paid))
           union 
           select ordnumber, curr, transdate, entity_credit_account, id,
                  person_id
           from oe 
           where ($16= 1 and oe.oe_class_id = 2 and $13 = 'o' 
                  and quotation is not true)
                  and (($17 and not closed) or ($18 and closed))
           union 
           select ordnumber, curr, transdate, entity_credit_account, id,
                  person_id
           from oe 
           where ($16= 2 and oe.oe_class_id = 1 and $13 = 'o'
                  and quotation is not true)
                  and (($17 and not closed) or ($18 and closed))
           union 
           select quonumber, curr, transdate, entity_credit_account, id,
                  person_id
           from oe 
           where($16= 1 and oe.oe_class_id = 4 and $13 = 'q'
                and quotation is true)
                  and (($17 and not closed) or ($18 and closed))
           union 
           select quonumber, curr, transdate, entity_credit_account, id,
                  person_id
           from oe 
           where($16= 2 and oe.oe_class_id = 4 and $13 = 'q'
                 and quotation is true)
                  and (($17 and not closed) or ($18 and closed))
          ) a ON (a.entity_credit_account = eca.id) -- broken into unions 
                                                    -- for performance
     JOIN ( select trans_id, parts_id, qty, description, unit, discount,
                   deliverydate, serialnumber, project_id, sellprice
             FROM  invoice where $13 = 'i'
            union 
            select trans_id, parts_id, qty, description, unit, discount,
                   reqdate, serialnumber, project_id, sellprice
             FROM orderitems where $13 <> 'i'
          ) i on i.trans_id = a.id
     JOIN parts p ON (p.id = i.parts_id)
LEFT JOIN exchangerate ex ON (ex.transdate = a.transdate)
LEFT JOIN project pr ON (pr.id = i.project_id)
LEFT JOIN entity ee ON (a.person_id = ee.id)
LEFT JOIN person ep ON (ep.entity_id = ee.id)
     JOIN exchangerate xr ON a.transdate = xr.transdate
    -- these filters don't perform as well on large databases
    WHERE (e.name ilike '%' || $1 || '%' or $1 is null)
          and ($3 is null or eca.id in 
                 (select credit_id from eca_to_contact
                   where contact ilike '%' || $3 || '%'))
          and (($4 is null and $5 is null and $6 is null and $7 is null)
               or eca.id in
                  (select credit_id from eca_to_location 
                    where location_id in
                          (select id from location
                            where ($4 is null or line_one ilike '%' || $4 || '%'
                                   or line_two ilike '%' || $4 || '%') 
                                  and ($5 is null or city 
                                                     ilike '%' || $5 || '%')
                                  and ($6 is null or state 
                                                    ilike '%' || $6 || '%')
                                  and ($7 is null or mail_code 
                                                    ilike '%' || $7 || '%')
                                  and ($10 is null or country_id = $10))
                   )
              )
          and (a.transdate >= $11 or $11 is null)
          and (a.transdate <= $12 or $12 is null)
          and (eca.startdate >= $14 or $14 is null)
          and (eca.startdate <= $15 or $15 is null)
 ORDER BY eca.meta_number;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION eca_history
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_account_class int,
 in_inc_open bool, in_inc_closed bool) IS
$$This produces a history detail report, i.e. a list of all products purchased by
a customer over a specific date range.  

meta_number is an exact match, as are in_open and inc_closed.  All other fields
allow for partial matches.  NULL matches all values.$$;


CREATE OR REPLACE FUNCTION eca_history_summary
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text, 
 in_country_id int, in_from_date date, in_to_date date, in_type char(1), 
 in_start_from date, in_start_to date, in_account_class int, 
 in_inc_open bool, in_inc_closed bool)
RETURNS SETOF  eca_history_result AS
$$
SELECT id, name, meta_number, null::int, null::text, curr, parts_id, partnumber,
       description, sum(qty), unit, null::numeric, null::numeric, null::date, 
       null::int, null::text, null::text, null::numeric,
       null::int, null::text
FROM   eca_history($1, $2, $3, $4, $5, $6, $7, $8, $9,
                   $10, $11, $12, $13, $14, $15, $16, $17, $18)
 group by id, name, meta_number, curr, parts_id, partnumber, description, unit
 order by meta_number;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION company__search
(in_account_class int, in_contact text, in_contact_info text[], 
	in_meta_number text, in_address text, in_city text, in_state text, 
	in_mail_code text, in_country text, in_date_from date, in_date_to date,
	in_business_id int, in_legal_name text, in_control_code text)
RETURNS SETOF company_search_result AS $$
DECLARE
	out_row company_search_result;
	loop_count int;
	t_contact_info text[];
BEGIN
	t_contact_info = in_contact_info;


	FOR out_row IN
		SELECT e.id, e.control_code, c.id, ec.id, ec.meta_number, 
			ec.description, ec.entity_class, 
			c.legal_name, c.sic_code, b.description , ec.curr::text
		FROM (select * from entity where in_control_code = control_code
                      union
                      select * from entity where in_control_code is null) e
		JOIN (SELECT * FROM company 
                       WHERE legal_name ilike  '%' || in_legal_name || '%'
                      UNION ALL
                      SELECT * FROM company
                       WHERE in_legal_name IS NULL) c ON (e.id = c.entity_id)
		LEFT JOIN (SELECT * FROM entity_credit_account 
                       WHERE meta_number = in_meta_number
                      UNION ALL
                      SELECT * from entity_credit_account
                       WHERE in_meta_number IS NULL) ec ON (ec.entity_id = e.id)
		LEFT JOIN business b ON (ec.business_id = b.id)
		WHERE ec.entity_class = in_account_class
			AND (c.id IN (select company_id FROM company_to_contact
				WHERE contact ILIKE ALL(t_contact_info))
				OR '' ILIKE ALL(t_contact_info))
			
			AND (c.legal_name ilike '%' || in_legal_name || '%'
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
							WHERE name ILIKE '%' ||
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

COMMENT ON FUNCTION eca_history_summary
(in_name text, in_meta_number text, in_contact_info text, in_address_line text,
 in_city text, in_state text, in_zip text, in_salesperson text, in_notes text,
 in_country_id int, in_from_date date, in_to_date date, in_type char(1),
 in_start_from date, in_start_to date, in_account_class int,
 in_inc_open bool, in_inc_closed bool) IS
$$Creates a summary account (no quantities, just parts group by invoice).

meta_number must match exactly or be NULL.  inc_open and inc_closed are exact
matches too.  All other values specify ranges or may match partially.$$;

CREATE OR REPLACE FUNCTION eca__get_taxes(in_credit_id int)
returns setof customertax AS
$$
select * from customertax where customer_id = $1
union
select * from vendortax where vendor_id = $1;
$$ language sql;

COMMENT ON FUNCTION eca__get_taxes(in_credit_id int) IS
$$ Returns a set of taxable account id's.$$; --'

CREATE OR REPLACE FUNCTION eca__set_taxes(in_credit_id int, in_tax_ids int[])
RETURNS bool AS
$$
DECLARE 
    eca entity_credit_account;
    iter int;
BEGIN
     SELECT * FROM entity_credit_account into eca WHERE id = in_credit_id;

     IF eca.entity_class = 1 then
        DELETE FROM vendortax WHERE vendor_id = in_credit_id;
        FOR iter in array_lower(in_tax_ids, 1) .. array_upper(in_tax_ids, 1)
        LOOP
             INSERT INTO vendortax (vendor_id, chart_id)
             values (in_credit_id, in_tax_ids[iter]);
        END LOOP;
     ELSIF eca.entity_class = 2 then
        DELETE FROM customertax WHERE customer_id = in_credit_id;
        FOR iter in array_lower(in_tax_ids, 1) .. array_upper(in_tax_ids, 1)
        LOOP
             INSERT INTO customertax (customer_id, chart_id)
             values (in_credit_id, in_tax_ids[iter]);
        END LOOP;
     ELSE 
        RAISE EXCEPTION 'Wrong entity class or credit account not found!';
     END IF;
     RETURN TRUE;
end;
$$ language plpgsql;

comment on function eca__set_taxes(in_credit_id int, in_tax_ids int[]) is
$$Sets the tax values for the customer or vendor.

The entity credit account must exist before calling this function, and must
have a type of either 1 or 2.
$$;

CREATE OR REPLACE FUNCTION entity__save_notes(in_entity_id int, in_note text, in_subject text)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN
	-- TODO, change this to create vector too
	INSERT INTO entity_note (ref_key, note_class, entity_id, note, vector, subject)
	VALUES (in_entity_id, 1, in_entity_id, in_note, '', in_subject);

	SELECT currval('note_id_seq') INTO out_id;
	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION entity__save_notes
(in_entity_id int, in_note text, in_subject text) IS
$$ Saves an entity-level note.  Such a note is valid for all credit accounts 
attached to that entity.  Returns the id of the note.  $$;

CREATE OR REPLACE FUNCTION eca__save_notes(in_credit_id int, in_note text, in_subject text)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN
	-- TODO, change this to create vector too
	INSERT INTO eca_note (ref_key, note_class, note, vector, subject)
	VALUES (in_credit_id, 3, in_note, '', in_subject);

	SELECT currval('note_id_seq') INTO out_id;
	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eca__save_notes
(in_entity_id int, in_note text, in_subject text) IS
$$ Saves an entity credit account-level note.  Such a note is valid for only one
credit account. Returns the id of the note.  $$;


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

COMMENT ON FUNCTION entity_credit_get_id_by_meta_number
(in_meta_number text, in_account_class int) is
$$ Returns the credit id from the meta_number and entity_class.$$;

CREATE OR REPLACE FUNCTION entity_credit__get(in_id int)
RETURNS entity_credit_account AS
$$
SELECT * FROM entity_credit_account WHERE id = $1;
$$ language sql;

COMMENT ON FUNCTION entity_credit__get(in_id int) IS
$$ Returns the entity credit account info.$$;

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

COMMENT ON FUNCTION entity_list_contact_class() IS
$$ Returns a list of contact classes ordered by ID.$$;

DROP TYPE IF EXISTS entity_credit_search_return CASCADE;
CREATE TYPE entity_credit_search_return AS (
        legal_name text,
        id int,
        entity_id int,
	entity_control_code text,
        entity_class int,
        discount numeric,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        meta_number text,
	credit_description text,
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

DROP TYPE IF EXISTS entity_credit_retrieve CASCADE;

CREATE TYPE entity_credit_retrieve AS (
        id int,
        entity_id int,
        entity_class int,
        discount numeric,
        discount_terms int,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        meta_number text,
	description text,
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
	credit_id int,
	pay_to_name text,
        taxform_id int
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

COMMENT ON FUNCTION entity_credit_get_id
(in_entity_id int, in_entity_class int, in_meta_number text) IS
$$ Returns an entity credit id, based on entity_id, entity_class, 
and meta_number.  This is the preferred way to locate an account if all three of 
these are known$$;

CREATE OR REPLACE FUNCTION entity__list_credit
(in_entity_id int, in_entity_class int) 
RETURNS SETOF entity_credit_retrieve AS
$$
DECLARE out_row entity_credit_retrieve;
BEGIN
	
	FOR out_row IN 
		SELECT  c.id, e.id, ec.entity_class, ec.discount, 
                        ec.discount_terms,
			ec.taxincluded, ec.creditlimit, ec.terms, 
			ec.meta_number, ec.description, ec.business_id, 
			ec.language_code, 
			ec.pricegroup_id, ec.curr, ec.startdate, 
			ec.enddate, ec.ar_ap_account_id, ec.cash_account_id, 
			ec.threshold, e.control_code, ec.id, ec.pay_to_name,
                        ec.taxform_id
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

COMMENT ON FUNCTION entity__list_credit (in_entity_id int, in_entity_class int) 
IS $$ Returns a list of entity credit account entries for the entity and of the
entity class.$$;

CREATE OR REPLACE FUNCTION company_retrieve (in_entity_id int) RETURNS company AS
$$
DECLARE t_company company;
BEGIN
	SELECT * INTO t_company FROM company WHERE entity_id = in_entity_id;
	RETURN t_company;
END;
$$ language plpgsql;

COMMENT ON FUNCTION company_retrieve (in_entity_id int) IS
$$ Returns all attributes for the company attached to the entity.$$;

CREATE OR REPLACE FUNCTION entity__get_by_cc (in_control_code text)
RETURNS SETOF entity AS $$
SELECT * FROM entity WHERE control_code = $1 $$ language sql;

COMMENT ON FUNCTION entity__get_by_cc (in_control_code text) IS
$$ Returns the entity row attached to the control code. $$;

create or replace function save_taxform 
(in_country_code int, in_taxform_name text)
RETURNS bool AS
$$
BEGIN
	INSERT INTO country_tax_form(country_id, form_name) 
	values (in_country_code, in_taxform_name);

	RETURN true;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON function save_taxform (in_country_code int, in_taxform_name text) IS
$$ Saves tax form information. Returns true or raises exception.$$;

CREATE OR REPLACE FUNCTION list_taxforms (in_entity_id int) RETURNS SETOF country_tax_form AS
$$
DECLARE t_country_tax_form country_tax_form;
BEGIN

	FOR t_country_tax_form IN 

		      SELECT * 
		            FROM country_tax_form where country_id in(SELECT country_id from entity where id=in_entity_id)
        LOOP

	RETURN NEXT t_country_tax_form;
	
	END LOOP;

END;
$$ language plpgsql;

COMMENT ON FUNCTION list_taxforms (in_entity_id int) IS
$$Returns a list of tax forms for the entity's country.$$; --'

DROP TYPE IF EXISTS company_billing_info CASCADE;
CREATE TYPE company_billing_info AS (
legal_name text,
meta_number text,
control_code text,
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
	select coalesce(eca.pay_to_name, c.legal_name), eca.meta_number, 
		e.control_code, c.tax_id, a.line_one, a.line_two, a.line_three, 
		a.city, a.state, a.mail_code, cc.name
	into out_var
	FROM company c
	JOIN entity e ON (c.entity_id = e.id)
	JOIN entity_credit_account eca ON (eca.entity_id = e.id)
	LEFT JOIN eca_to_location cl ON (eca.id = cl.credit_id)
	LEFT JOIN location a ON (a.id = cl.location_id)
	LEFT JOIN country cc ON (cc.id = a.country_id)
	WHERE eca.id = in_id AND (location_class = 1 or location_class is null);

	RETURN out_var;
END;
$$ language plpgsql;

COMMENT ON FUNCTION company_get_billing_info (in_id int) IS
$$ Returns billing information (billing name and address) for a given credit 
account.$$;


DROP FUNCTION IF EXISTS company_save(int, text, int, text, text, int, text, int);
CREATE OR REPLACE FUNCTION company_save (
    in_id int, in_control_code text, in_entity_class int,
    in_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text,in_country_id int
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

	UPDATE entity 
	SET name = in_name, 
		entity_class = in_entity_class,
		control_code = in_control_code
	WHERE id = in_entity_id;

	IF FOUND THEN
		t_entity_id = in_entity_id;
	ELSE
		INSERT INTO entity (name, entity_class, control_code,country_id)
		VALUES (in_name, in_entity_class, t_control_code,in_country_id);
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

COMMENT ON  FUNCTION company_save (
    in_id int, in_control_code text, in_entity_class int,
    in_name text, in_tax_id TEXT,
    in_entity_id int, in_sic_code text,in_country_id int
 ) is
$$ Saves a company.  Returns the id number of the record stored.$$;

CREATE OR REPLACE FUNCTION entity_credit_save (
    in_credit_id int, in_entity_class int,
    in_entity_id int, in_description text,
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric, 
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int, 
    in_language varchar(6), in_pricegroup_id int, 
    in_curr char, in_startdate date, in_enddate date, 
    in_threshold NUMERIC,
    in_ar_ap_account_id int,
    in_cash_account_id int,
    in_pay_to_name text,
    in_taxform_id int
    
) returns INT as $$
    
    DECLARE
        t_entity_class int;
        l_id int;
	t_meta_number text; 
	t_mn_default_key text;
    BEGIN
	-- TODO:  Move to mapping table.
            IF in_entity_class = 1 THEN
	       t_mn_default_key := 'vendornumber';
	    ELSIF in_entity_class = 2 THEN
	       t_mn_default_key := 'customernumber';
	    END IF;
	    IF in_meta_number IS NULL THEN
		t_meta_number := setting_increment(t_mn_default_key);
	    ELSE
		t_meta_number := in_meta_number;
	    END IF;
            update entity_credit_account SET
                discount = in_discount,
                taxincluded = in_taxincluded,
                creditlimit = in_creditlimit,
		description = in_description,
                terms = in_terms,
                ar_ap_account_id = in_ar_ap_account_id,
                cash_account_id = in_cash_account_id,
                meta_number = t_meta_number,
                business_id = in_business_id,
                language_code = in_language,
                pricegroup_id = in_pricegroup_id,
                curr = in_curr,
                startdate = in_startdate,
                enddate = in_enddate,
                threshold = in_threshold,
		discount_terms = in_discount_terms,
		pay_to_name = in_pay_to_name,
		taxform_id = in_taxform_id
            where id = in_credit_id;
        
         IF FOUND THEN
            RETURN in_credit_id;
         ELSE
            INSERT INTO entity_credit_account (
                entity_id,
                entity_class,
                discount, 
                description,
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
                pay_to_name,
                taxform_id,
                cash_account_id

            )
            VALUES (
                in_entity_id,
                in_entity_class,
                in_discount, 
                in_description,
                in_taxincluded,
                in_creditlimit,
                in_terms,
                t_meta_number,
                in_business_id,
                in_language,
                in_pricegroup_id,
                in_curr,
                in_startdate,
                in_enddate,
                in_discount_terms,
                in_threshold,
                in_ar_ap_account_id,
                in_pay_to_name,
                in_taxform_id,
		in_cash_account_id
            );
            RETURN currval('entity_credit_account_id_seq');
       END IF;

    END;
    
$$ language 'plpgsql';

COMMENT ON  FUNCTION entity_credit_save (
    in_credit_id int, in_entity_class int,
    in_entity_id int, in_description text,
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric,
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int,
    in_language varchar(6), in_pricegroup_id int,
    in_curr char, in_startdate date, in_enddate date,
    in_threshold NUMERIC,
    in_ar_ap_account_id int,
    in_cash_account_id int,
    in_pay_to_name text,
    in_taxform_id int

) IS
$$ Saves an entity credit account.  Returns the id of the record saved.  $$;

CREATE OR REPLACE FUNCTION company__list_locations(in_entity_id int)
RETURNS SETOF location_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT l.id, l.line_one, l.line_two, l.line_three, l.city, 
			l.state, l.mail_code, c.id, c.name, lc.id, lc.class
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

COMMENT ON FUNCTION company__list_locations(in_entity_id int) IS
$$ Lists all locations for an entity.$$;

DROP TYPE IF EXISTS contact_list CASCADE;
CREATE TYPE contact_list AS (
	class text,
	class_id int,
	description text,
	contact text
);

CREATE OR REPLACE FUNCTION company__list_contacts(in_entity_id int) 
RETURNS SETOF contact_list AS $$
DECLARE out_row contact_list;
BEGIN
	FOR out_row IN
		SELECT cl.class, cl.id, c.description, c.contact
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

COMMENT ON FUNCTION company__list_contacts(in_entity_id int) IS
$$ Lists all contact info for the entity.$$;

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

COMMENT ON FUNCTION company__list_bank_account(in_entity_id int) IS
$$ Lists all bank accounts for the entity.$$;

CREATE OR REPLACE FUNCTION eca__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text,
in_bank_account_id int)
RETURNS int AS
$$
DECLARE out_id int;
BEGIN
        UPDATE entity_bank_account
           SET bic = in_bic,
               iban = in_iban
         WHERE id = in_bank_account_id;

        IF FOUND THEN
                out_id = in_bank_account_id;
        ELSE
	  	INSERT INTO entity_bank_account(entity_id, bic, iban)
		VALUES(in_entity_id, in_bic, in_iban);
	        SELECT CURRVAL('entity_bank_account_id_seq') INTO out_id ;
	END IF;

	IF in_credit_id IS NOT NULL THEN
		UPDATE entity_credit_account SET bank_account = out_id
		WHERE id = in_credit_id;
	END IF;

	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON  FUNCTION eca__save_bank_account
(in_entity_id int, in_credit_id int, in_bic text, in_iban text,
in_bank_account_id int) IS
$$ Saves bank account to the credit account.$$;

CREATE OR REPLACE FUNCTION entity__save_bank_account
(in_entity_id int, in_bic text, in_iban text, in_bank_account_id int)
RETURNS int AS
$$
DECLARE out_id int;
BEGIN
        UPDATE entity_bank_account
           SET bic = in_bic,
               iban = in_iban
         WHERE id = in_bank_account_id;

        IF FOUND THEN
                out_id = in_bank_account_id;
        ELSE
	  	INSERT INTO entity_bank_account(entity_id, bic, iban)
		VALUES(in_entity_id, in_bic, in_iban);
	        SELECT CURRVAL('entity_bank_account_id_seq') INTO out_id ;
	END IF;

	RETURN out_id;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION entity__save_bank_account
(in_entity_id int, in_bic text, in_iban text, in_bank_account_id int) IS
$$Saves a bank account to the entity.$$;

CREATE OR REPLACE FUNCTION company__delete_contact
(in_company_id int, in_contact_class_id int, in_contact text)
returns bool as $$
BEGIN

DELETE FROM company_to_contact
 WHERE company_id = in_company_id and contact_class_id = in_contact_class_id
       and contact= in_contact;
RETURN FOUND;

END;

$$ language plpgsql;

COMMENT ON FUNCTION company__delete_contact
(in_company_id int, in_contact_class_id int, in_contact text) IS
$$ Returns true if at least one record was deleted.  False if no records were 
affected.$$;

CREATE OR REPLACE FUNCTION eca__delete_contact
(in_credit_id int, in_contact_class_id int, in_contact text)
returns bool as $$
BEGIN

DELETE FROM eca_to_contact
 WHERE credit_id = in_credit_id and contact_class_id = in_contact_class_id
       and contact= in_contact;
RETURN FOUND;

END;

$$ language plpgsql;

COMMENT ON FUNCTION eca__delete_contact
(in_credit_id int, in_contact_class_id int, in_contact text) IS
$$ Returns true if at least one record was deleted.  False if no records were
affected.$$;

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

COMMENT ON FUNCTION company__save_contact
(in_entity_id int, in_contact_class int, in_description text, in_contact text) IS
$$ Saves company contact information.  The return value is meaningless. $$;

DROP TYPE IF EXISTS entity_note_list CASCADE;
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

COMMENT ON FUNCTION company__list_notes(in_entity_id int) IS
$$ Returns a set of notes (including content) attached to the entity.$$;
		
CREATE OR REPLACE FUNCTION eca__list_notes(in_credit_id int) 
RETURNS SETOF note AS 
$$
DECLARE out_row record;
	t_entity_id int;
BEGIN
        -- ALERT: security definer function.  Be extra careful about EXECUTE
        -- in here. --CT
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

COMMENT ON FUNCTION eca__list_notes(in_credit_id int) IS
$$Returns a list of notes attached to the entity credit account.$$;

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

COMMENT ON FUNCTION company__location_save (
    in_entity_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_city TEXT, in_state TEXT, in_mail_code text, in_country_code int,
    in_created date
) IS
$$ Saves a location to a company.  Returns the location id.$$;

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

	SELECT location_save(NULL, in_line_one, in_line_two, in_line_three, in_city,
		in_state, in_mail_code, in_country_code) 
	INTO l_id;

	INSERT INTO company_to_location 
		(company_id, location_class, location_id)
	VALUES  (t_company_id, in_location_class, l_id);

	RETURN l_id;    
    END;

$$ language 'plpgsql';


COMMENT ON FUNCTION _entity_location_save(
    in_entity_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_code int
) IS
$$ Private method for storing locations to an entity.  Do not call directly.
Returns the location id that was inserted or updated.$$;

create or replace function eca__location_save(
    in_credit_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text, 
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text, 
    in_country_code int, in_old_location_class int
) returns int AS $$

    DECLARE
        l_row location;
        l_id INT;
        l_orig_id INT;
    BEGIN
       
        UPDATE eca_to_location
           SET location_class = in_location_class
         WHERE credit_id = in_credit_id
           AND location_class = in_old_location_class
           AND location_id = in_location_id;
           
         IF FOUND THEN
            SELECT location_save(
                in_location_id, 
                in_line_one, 
                in_line_two, 
                in_line_three, 
                in_city,
                in_state, 
                in_mail_code, 
                in_country_code
            )
        	INTO l_id; 
        ELSE
            SELECT location_save(
                NULL, 
                in_line_one, 
                in_line_two, 
                in_line_three, 
                in_city,
                in_state, 
                in_mail_code, 
                in_country_code
            )
        	INTO l_id; 
            INSERT INTO eca_to_location 
        		(credit_id, location_class, location_id)
        	VALUES  (in_credit_id, in_location_class, l_id);
        
        END IF;

	RETURN l_id;    
    END;

$$ language 'plpgsql';

COMMENT ON function eca__location_save(
    in_credit_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_code int, in_old_location_class int
) IS
$$ Saves a location to an entity credit account. Returns id of saved record.$$;

CREATE OR REPLACE FUNCTION eca__delete_location
(in_credit_id int, in_location_id int, in_location_class int)
RETURNS BOOL AS
$$
BEGIN

DELETE FROM eca_to_location
 WHERE credit_id = in_credit_id AND location_id = in_location_id 
       AND location_class = in_location_class;

RETURN FOUND;

END;
$$ language plpgsql;

COMMENT ON FUNCTION eca__delete_location
(in_credit_id int, in_location_id int, in_location_class int) IS
$$ Deletes the record identified.  Returns true if successful, false if no record
found.$$;

CREATE OR REPLACE FUNCTION company__delete_location
(in_company_id int, in_location_id int, in_location_class int)
RETURNS BOOL AS
$$
BEGIN

DELETE FROM eca_to_location
 WHERE company_id = in_company_id AND location_id = in_location_id 
       AND location_class = in_location_class;

RETURN FOUND;

END;
$$ language plpgsql;

COMMENT ON FUNCTION company__delete_location
(in_company_id int, in_location_id int, in_location_class int) IS
$$ Deletes the record identified.  Returns true if successful, false if no record
found.$$;

CREATE OR REPLACE FUNCTION eca__list_locations(in_credit_id int)
RETURNS SETOF location_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT l.id, l.line_one, l.line_two, l.line_three, l.city, 
			l.state, l.mail_code, c.id, c.name, lc.id, lc.class
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

COMMENT ON FUNCTION eca__list_locations(in_credit_id int) IS
$$ Returns a list of locations attached to the credit account.$$;

CREATE OR REPLACE FUNCTION eca__list_contacts(in_credit_id int) 
RETURNS SETOF contact_list AS $$
DECLARE out_row contact_list;
BEGIN
	FOR out_row IN
		SELECT cl.class, cl.id, c.description, c.contact
		FROM eca_to_contact c
		JOIN contact_class cl ON (c.contact_class_id = cl.id)
		WHERE credit_id = in_credit_id
	LOOP
		return next out_row;
	END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION eca__list_contacts(in_credit_id int) IS
$$ Returns a list of contact info attached to the entity credit account.$$;

CREATE OR REPLACE FUNCTION eca__save_contact
(in_credit_id int, in_contact_class int, in_description text, in_contact text,
in_old_contact text, in_old_contact_class int)
RETURNS INT AS
$$
DECLARE out_id int;
BEGIN

    PERFORM *
       FROM eca_to_contact
      WHERE credit_id = in_credit_id
        AND contact_class_id = in_old_contact_class
        AND contact = in_old_contact;
        
    IF FOUND THEN
        UPDATE eca_to_contact
           SET contact = in_contact,
               description = in_description,
               contact_class_id = in_contact_class
         WHERE credit_id = in_credit_id
           AND contact_class_id = in_old_contact_class
           AND contact = in_old_contact;
    ELSE
        INSERT INTO eca_to_contact(credit_id, contact_class_id, 
                description, contact)
        VALUES (in_credit_id, in_contact_class, in_description, in_contact);
        
    END IF;

	RETURN 1;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eca__save_contact
(in_credit_id int, in_contact_class int, in_description text, in_contact text,
in_old_contact text, in_old_contact_class int) IS
$$ Saves the contact record at the entity credit account level.  Returns 1.$$;

CREATE OR REPLACE FUNCTION company__get_all_accounts (
    in_entity_id int,
    in_entity_class int
) RETURNS SETOF entity_credit_account AS $body$
    
    SELECT * 
      FROM entity_credit_account 
     WHERE entity_id = $1
       AND entity_class = $2;
    
$body$ language SQL;

COMMENT ON FUNCTION company__get_all_accounts (
    in_entity_id int,
    in_entity_class int
) IS 
$$ Returns a list of all entity credit accounts attached to that entity.$$;
COMMIT;
