
DROP TRIGGER IF EXISTS eclass_perms_check ON entity;

alter table entity drop column entity_class;
