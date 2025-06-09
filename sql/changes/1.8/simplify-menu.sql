

alter table menu_node add column url text;
alter table menu_node add column standalone boolean;
alter table menu_node add column menu boolean;

drop table menu_attribute;

drop function if exists to_args(text[], text[]) cascade;
