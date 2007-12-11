BEGIN;


CREATE OR REPLACE FUNCTION customer_location_save (
    in_entity_id int,
    in_location_class int, in_line_one text, in_line_two text, 
    in_line_three text,
    in_city TEXT, in_state text, in_mail_code text, in_country_id int
) returns int AS $$
    BEGIN
    return _entity_location_save(
        in_entity_id, NULL,
        in_location_class, in_line_one, in_line_two, in_line_three,
        in_city, in_state, in_mail_code, in_country_id);
    END;

$$ language 'plpgsql';

/* Disabling until we can work on this a little more.

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
*/

COMMIT;
