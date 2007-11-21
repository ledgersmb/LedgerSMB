BEGIN;

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

CREATE TYPE customer_search_return AS (
        legal_name text,
        id int,
        entity_id int,
        entity_class int,
        discount numeric,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        customernumber int,
        business_id int,
        language_code text,
        pricegroup_id int,
        curr char(3),
        startdate date,
        enddate date
);

CREATE OR REPLACE FUNCTION customer__retrieve(in_entity_id int) RETURNS
customer_search_return AS
$$
DECLARE out_row customer_search_return;
BEGIN
	SELECT c.legal_name, c.id, e.id, ec.entity_class, ec.discount,
		ec.taxincluded, ec.creditlimit, ec.terms, ec.meta_number,
		ec.business_id, ec.language_code, ec.pricegroup_id, 
		ec.curr::char(3), ec.startdate, ec.enddate
	INTO out_row
	FROM company c
	JOIN entity e ON (c.entity_id = e.id)
	JOIN entity_credit_account ec ON (c.entity_id = ec.entity_id)
	WHERE e.id = in_entity_id
		AND ec.entity_class = 2;

	RETURN out_row;
END;
$$ LANGUAGE PLPGSQL;
-- COMMENT ON TYPE customer_search_result IS
-- $$ This structure will change greatly in 1.4.  
-- If you want to reply on it heavily, be prepared for breakage later.  $$;

CREATE OR REPLACE FUNCTION entity_credit_save (
    in_id int, in_entity_class int,
    
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric, 
    in_discount_terms int,
    in_terms int, in_meta_number varchar(32), in_business_id int, 
    in_language varchar(6), in_pricegroup_id int, 
    in_curr char, in_startdate date, in_enddate date, 
    in_notes text, 
    in_name text, in_tax_id TEXT,
    in_threshold NUMERIC
    
) returns INT as $$
    
    DECLARE
        t_entity_class int;
        new_entity_id int;
        v_row company;
        l_id int;
    BEGIN
        
        
        SELECT INTO v_row * FROM company WHERE id = in_id;
        
        IF NOT FOUND THEN
            -- do some inserts
            
            select nextval('entity_id_seq') into new_entity_id;
            
            insert into entity (id, name, entity_class) 
                VALUES (new_entity_id, in_name, in_entity_class);
            
            INSERT INTO company ( entity_id, legal_name, tax_id ) 
                VALUES ( new_entity_id, in_name, in_tax_id );
            
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
                threshold
            )
            VALUES (
                new_entity_id,
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
                in_threshold
            );
            -- entity note class
            insert into entity_note (note_class, note, ref_key, vector) VALUES (
                1, in_notes, new_entity_id, '');

            return new_entity_id;

        ELSIF FOUND THEN
        
            update company set tax_id = in_tax_id where id = in_id;
            update entity_credit_account SET
                discount = in_discount,
                taxincluded = in_taxincluded,
                creditlimit = in_creditlimit,
                terms = in_terms,
                meta_number = in_meta_number,
                business_id = in_business_id,
                language_code = in_language,
                pricegroup_id = in_pricegroup_id,
                curr = in_curr,
                startdate = in_startdate,
                enddate = in_enddate,
                threshold = in_threshold,
                discount_terms = in_discount_terms
            where entity_id = v_row.entity_id;
            
            
            UPDATE entity_note SET
                note = in_note
            WHERE ref_key = v_row.entity_id;
            return in_id;
        
        END IF;
    END;
    
$$ language 'plpgsql';

CREATE TYPE location_result AS (
	id int,
	line_one text,
	line_two text,
	line_three text,
	city text,
	state text,
	country text,
	class text
);


CREATE OR REPLACE FUNCTION company__list_locations(in_entity_id int)
RETURNS SETOF location_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT l.id, l.line_one, l.line_two, l.line_three, l.city, 
			l.state, c.name, lc.class
		FROM location l
		JOIN company_to_location ctl ON (ctl.location_id = l.id)
		JOIN company cp ON (ctl.company_id = cp.id)
		JOIN location_class lc ON (ctl.location_class = lc.id)
		JOIN country c ON (c.id = l.country_id)
		WHERE cp.entity_id = in_entity_id
		ORDER BY lc.id, l.id, c.name
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE contact_list AS (
	class text,
	contact text
);

CREATE OR REPLACE FUNCTION company__list_contacts(in_entity_id int)
RETURNS SETOF contact_list AS 
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN 
		SELECT cc.class, c.contact
		FROM company_to_contact c
		JOIN contact_class cc ON (c.contact_class_id = cc.id)
		JOIN company cp ON (c.company_id = cp.id)
		WHERE cp.entity_id = in_entity_id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION company__list_bank_account(in_entity_id int)
RETURNS SETOF entity_bank_account AS
$$
DECLARE out_row entity_bank_account%ROWTYPE;
BEGIN
	FOR out_row IN
		SELECT * from entity_bank_account where entity_id = in_entity_id
	LOOP
		RETURN NEXT;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE entity_note_list AS (
	id int,
	note text
);

CREATE OR REPLACE FUNCTION company__list_notes(in_entity_id int) 
RETURNS SETOF entity_note_list AS 
$$
DECLARE out_row record;
BEGIN
	FOR out_row IN
		SELECT id, note
		FROM entity_note
		WHERE ref_key = in_entity_id
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
		


CREATE OR REPLACE FUNCTION customer_location_save (
    in_company_id int,
    in_location_class int, in_line_one text, in_line_two text, 
    in_line_three text,
    in_city TEXT, in_state text, in_mail_code text, in_country_code int
) returns int AS $$
    BEGIN
    return _entity_location_save(
        in_company_id, NULL,
        in_location_class, in_line_one, in_line_two, in_line_three,
        in_city, in_state, in_mail_code, in_country_code);
    END;

$$ language 'plpgsql';


CREATE OR REPLACE FUNCTION customer_search(in_pattern TEXT) returns setof customer_search_return as $$
    
    -- searches customer name, account number, street address, city, state,
    -- other location-based stuff
    
    declare
        v_row customer_search_return;
        query text;
    begin
            
        for v_row in select c.legal_name, v.* from customer v
                    join company c on c.entity_id = v.entity_id 
                    join entity e on e.id = v.entity_id 
                    join company_to_location ctl on c.id = ctl.company_id
                    join location l on l.id = ctl.location_id
                    where l.line_one % in_pattern
                    OR l.line_two % in_pattern
                    OR l.line_three % in_pattern
                    OR l.city_province % in_pattern
                    OR c.legal_name % in_pattern
                    OR e.name % in_pattern
        LOOP
        
            RETURN NEXT v_row;
        
        END LOOP;
        
        RETURN;
    
    end;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION customer_retrieve(INT) returns setof customer as $$
    
    
    select v.* from customer v 
    join company c on c.entity_id = v.entity_id
    where v.id = $1;
    
$$ language 'sql';

CREATE OR REPLACE FUNCTION customer_next_customer_id() returns bigint as $$
    
    select nextval('company_id_seq');
    
$$ language 'sql';
COMMIT;
