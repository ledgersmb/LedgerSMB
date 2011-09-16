ALTER TABLE audittrail DROP CONSTRAINT "audittrail_person_id_fkey";

\echo If the update below fails, it may be because the table is set up correctly
\echo already.  It's safe to ignore constraint errors there.
--'
UPDATE audittrail 
  SET person_id = (select entity_id from person where id = person_id);

\echo If the alter table below fails, there is something wrong.  Please correct
\echo before proceding.
ALTER TABLE audittrail ADD FOREIGN KEY (person_id) REFERENCES person(entity_id);

ALTER TABLE lsmb_roles DROP CONSTRAINT "lsmb_roles_user_id_fkey";

ALTER TABLE lsmb_roles ADD foreign key (user_id) references users(id) 
  ON DELETE CASCADE;
