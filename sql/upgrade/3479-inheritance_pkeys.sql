alter table entity_note add primary key(id);
alter table eca_note add primary key(id);
alter table invoice_note add primary key(id);

alter table parts_translation add PRIMARY KEY (trans_id, language_code);
alter table project_translation add PRIMARY KEY (trans_id, language_code);
