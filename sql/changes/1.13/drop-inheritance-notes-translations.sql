
alter table asset_note no inherit note;
alter table asset_note
  alter column id drop default,
  alter column id add generated always as identity;
alter table budget_note no inherit note;
alter table budget_note
  alter column id drop default,
  alter column id add generated always as identity;
alter table eca_note no inherit note;
alter table eca_note
  alter column id drop default,
  alter column id add generated always as identity;
alter table entity_note no inherit note;
alter table entity_note
  alter column id drop default,
  alter column id add generated always as identity;
alter table invoice_note no inherit note;
alter table invoice_note
  alter column id drop default,
  alter column id add generated always as identity;
alter table journal_note no inherit note;
alter table journal_note
  alter column id drop default,
  alter column id add generated always as identity;

select setval('asset_note_id_seq',
              coalesce((select max(id) from asset_note) + 1, 1),
              false);
select setval('budget_note_id_seq',
              coalesce((select max(id) from budget_note) + 1, 1),
              false);
select setval('eca_note_id_seq',
              coalesce((select max(id) from eca_note) + 1, 1),
              false);
select setval('entity_note_id_seq',
              coalesce((select max(id) from entity_note) + 1, 1),
              false);
select setval('invoice_note_id_seq',
              coalesce((select max(id) from invoice_note) + 1, 1),
              false);
select setval('journal_note_id_seq',
              coalesce((select max(id) from journal_note) + 1, 1),
              false);


drop table note;

alter table account_heading_translation no inherit "translation";
alter table account_translation no inherit "translation";
alter table business_unit_translation no inherit "translation";
alter table parts_translation no inherit "translation";
alter table partsgroup_translation no inherit "translation";

drop table "translation";
