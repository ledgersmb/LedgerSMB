begin;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

commit;
