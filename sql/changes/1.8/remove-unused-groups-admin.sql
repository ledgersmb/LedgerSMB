

drop function if exists admin__add_function_to_group(TEXT, TEXT);
drop function if exists admin__remove_function_from_group(TEXT, TEXT);
drop function if exists admin__create_group(TEXT);
drop function if exists admin__add_group_to_role(text, text);
drop function if exists admin__remove_group_from_role(text, text);
drop function if exists admin__list_group_grants(text);
drop function if exists admin__delete_group(TEXT);
drop function if exists admin__is_group(text);

DROP VIEW if exists role_view CASCADE;

drop table if exists lsmb_group_grants;
drop table if exists lsmb_group;
