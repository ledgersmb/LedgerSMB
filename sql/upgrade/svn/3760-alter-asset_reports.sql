alter table asset_report alter column entered_by 
set default person__get_my_entity_id();

DROP TYPE asset_nbv_line CASCADE;
