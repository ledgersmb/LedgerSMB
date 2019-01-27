

ALTER TABLE oe DROP CONSTRAINT oe_person_id_fkey;

UPDATE oe
   SET person_id = (SELECT entity_id FROM person
                     WHERE person.id = oe.person_id)
 WHERE person_id IS NOT NULL;


ALTER TABLE oe ADD FOREIGN KEY (person_id) REFERENCES person (entity_id);

