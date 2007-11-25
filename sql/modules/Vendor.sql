BEGIN;

-- TODO:  Move indexes to Pg-database

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

COMMIT;
