CREATE OR REPLACE FUNCTION person__list_bank_account(in_entity_id int)
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

CREATE OR REPLACE FUNCTION person__list_notes(in_entity_id int)
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


