
begin;

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

update defaults set value = 'yes' where setting_key = 'module_load_ok';


commit;