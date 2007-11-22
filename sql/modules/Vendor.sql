BEGIN;

CREATE TYPE vendor_search_return AS (
        legal_name text,
        id int,
        entity_id int,
        entity_class int,
        discount numeric,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        vendornumber int,
        cc text,
        bcc text,
        business_id int,
        language_code text,
        pricegroup_id int,
        curr char,
        startdate date,
        enddate date,
        bic varchar, 
        iban varchar, 
        note text
);

CREATE OR REPLACE FUNCTION vendor_save (
    in_id int,
    
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric, 
    in_discount_terms int, in_threshold numeric,
    in_terms int, in_vendornumber varchar(32), in_cc text, in_bcc text, 
    in_business_id int, in_language varchar(6), in_pricegroup_id int, 
    in_curr char, in_startdate date, in_enddate date, 
    
    in_bic text, in_iban text, 
    
    in_notes text, 
    
    in_name text, in_tax_id TEXT
    
) returns INT as $$
    
    -- does not require entity_class, as entity_class is a known given to be 1
    
    DECLARE
        t_entity_class int;
        new_entity_id int;
        v_row company;
        l_id int;
    BEGIN
        
        t_entity_class := 1;
        
        SELECT INTO v_row * FROM company WHERE id = in_id;
        
        IF NOT FOUND THEN
            -- do some inserts
            
            new_entity_id := nextval('entity_id_seq');
            
            insert into entity (id, name, entity_class) 
                VALUES (new_entity_id, in_name, t_entity_class);
            
            INSERT INTO company ( id, entity_id, legal_name, tax_id ) 
                VALUES ( in_id, new_entity_id, in_name, in_tax_id );
            
            INSERT INTO entity_credit_account (
                entity_id,
                entity_class,
                discount, 
                taxincluded,
                creditlimit,
                terms,
                cc,
                bcc,
                business_id,
                language_code,
                pricegroup_id,
                curr,
                startdate,
                enddate,
                meta_number,
                discount_terms,
                threshold
            )
            VALUES (
                new_entity_id,
                t_entity_class,
                in_discount, 
                in_taxincluded,
                in_creditlimit,
                in_terms,
                in_cc,
                in_bcc,
                in_business_id,
                in_language,
                in_pricegroup_id,
                in_curr,
                in_startdate,
                in_enddate,
                in_vendornumber,
                in_discount_terms,
                in_threshold
            );
            INSERT INTO entity_bank_account (
                entity_id,
                bic,
                iban
            )
            VALUES (
                new_entity_id,
                in_bic,
                in_iban
            );            
            -- entity note class
            insert into entity_note (note_class, note, ref_key, vector) VALUES (
                1, in_notes, new_entity_id, '');
             
        ELSIF FOUND THEN
        
            update company set tax_id = in_tax_id where id = in_id;
            update entity_credit_account SET
                discount = in_discount,
                taxincluded = in_taxincluded,
                creditlimit = in_creditlimit,
                terms = in_terms,
                cc = in_cc,
                bcc = in_bcc,
                business_id = in_business_id,
                language_code = in_language,
                pricegroup_id = in_pricegroup_id,
                curr = in_curr,
                startdate = in_startdate,
                enddate = in_enddate,
                meta_number = in_vendornumber,
                threshold = in_threshold,
                discount_terms = in_discount_terms
            where entity_id = v_row.entity_id;
            
            UPDATE entity_bank_account SET
                bic = in_bic,
                iban = in_iban
            WHERE entity_id = v_row.entity_id;
            
            UPDATE entity_note SET
                note = in_note
            WHERE ref_key = v_row.entity_id;
        
        END IF;
        return in_id;
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION vendor_location_save (
    in_company_id int,
    in_location_class int, in_line_one text, in_line_two text, 
    in_city_province TEXT, in_mail_code text, in_country_code int,
    in_created date
) returns int AS $$
    BEGIN
    return _entity_location_save(
        in_company_id,
        in_location_class, in_line_one, in_line_two, 
        in_city_province , in_mail_code, in_country_code,
        in_created);
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

CREATE INDEX company_name_gist__idx ON company USING gist(legal_name gist_trgm_ops);
CREATE INDEX location_address_one_gist__idx ON location USING gist(line_one gist_trgm_ops);
CREATE INDEX location_address_two_gist__idx ON location USING gist(line_two gist_trgm_ops);
CREATE INDEX location_address_three_gist__idx ON location USING gist(line_three gist_trgm_ops);
    
CREATE INDEX location_city_prov_gist_idx ON location USING gist(city gist_trgm_ops);
CREATE INDEX entity_name_gist_idx ON entity USING gist(name gist_trgm_ops);

CREATE OR REPLACE FUNCTION vendor_search(in_name TEXT, in_address TEXT, 
    in_city_prov TEXT) 
    RETURNS SETOF vendor_search_return AS $$
    
    -- searches vendor name, account number, street address, city, state,
    -- other location-based stuff
    
    declare
        v_row vendor_search_return;
        query text;
    begin
            
        for v_row in select c.legal_name, v.* from vendor v
                    join company c on c.entity_id = v.entity_id 
                    join entity e on e.id = v.entity_id 
                    join company_to_location ctl on c.id = ctl.company_id
                    join location l on l.id = ctl.location_id
                    where (
                        l.line_one % in_address
                        OR l.line_two % in_address
                        OR l.line_three % in_address
                    )
                    OR l.city_province % in_city_prov
                    OR (
                        c.legal_name % in_name
                        OR e.name % in_name
                    )
        LOOP
        
            RETURN NEXT v_row;
        
        END LOOP;
        
        RETURN;
    
    end;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION vendor_retrieve(INT) returns setof vendor as $$
    
    select v.* from vendor v 
    join company c on c.entity_id = v.entity_id
    where v.id = $1;
    
$$ language 'sql';

CREATE OR REPLACE FUNCTION vendor_next_vendor_id() returns bigint as $$
    
    select nextval('company_id_seq');
    
$$ language 'sql';
COMMIT;
