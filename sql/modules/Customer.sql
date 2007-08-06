BEGIN;

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

CREATE OR REPLACE FUNCTION customer_save (
    in_id int,
    
    in_discount numeric, in_taxincluded bool, in_creditlimit numeric, 
    in_terms int, in_meta_number varchar(32), in_cc text, in_bcc text, 
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
                meta_number,
                cc,
                bcc,
                business_id,
                language_code,
                pricegroup_id,
                curr,
                startdate,
                enddate
            )
            VALUES (
                new_entity_id,
                t_entity_class,
                in_discount, 
                in_taxincluded,
                in_creditlimit,
                in_terms,
                in_meta_number,
                in_cc,
                in_bcc,
                in_business_id,
                in_language,
                in_pricegroup_id,
                in_curr,
                in_startdate,
                in_enddate
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
                meta_number = in_meta_number,
                cc = in_cc,
                bcc = in_bcc,
                business_id = in_business_id,
                language_code = in_language,
                pricegroup_id = in_pricegroup_id,
                curr = in_curr,
                startdate = in_startdate,
                enddate = in_enddate                
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

CREATE OR REPLACE FUNCTION customer_location_save (
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
COMMIT;

CREATE OR REPLACE FUNCTION customer_next_customer_id() returns int as $$
    
    select nextval('company_id_seq');
    
$$ language 'sql';ƒ