DROP function eca__location_save(
    in_credit_id int, in_location_id int,
    in_location_class int, in_line_one text, in_line_two text,
    in_line_three text, in_city TEXT, in_state TEXT, in_mail_code text,
    in_country_code int);

DROP function person__save_location(
    in_entity_id int,
    in_location_id int,
    in_location_class int,
    in_line_one text,
    in_line_two text,
    in_line_three text,
    in_city TEXT,
    in_state TEXT,
    in_mail_code text,
    in_country_code int);
