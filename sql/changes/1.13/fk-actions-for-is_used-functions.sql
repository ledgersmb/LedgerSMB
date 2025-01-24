
/*

  This file contains the revisited foreign key constraints which need ON DELETE
  set to CASCADE, instead of 'NO ACTION', in order to make the *__is_used()
  functions work.  These functions try to delete a record (e.g., an account);
  when that succeeds, it concludes that the account isn't used (and aborts the
  deletion!).

  However, accounts will have associated account_link records and
  cr_coa_to_account records. These should not block deletion however, meaning
  that the delete should cascade. This way, the delete gets blocked when the
  deletion of the cr_coa_to_account row deletion fails due to further foreign
  keys being checked (and failing).

 */


-- ACCOUNT (gl accounts)
ALTER TABLE account_link
  DROP CONSTRAINT account_link_account_id_fkey,
  ADD FOREIGN KEY (account_id) REFERENCES account (id) ON DELETE CASCADE;

ALTER TABLE cr_coa_to_account
  DROP CONSTRAINT cr_coa_to_account_chart_id_fkey,
  ADD FOREIGN KEY (chart_id) REFERENCES account (id) ON DELETE CASCADE;

-- ENTITY

-- entity additional data
ALTER TABLE entity_other_name
  DROP CONSTRAINT entity_other_name_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE entity_to_contact
  DROP CONSTRAINT entity_to_contact_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE entity_to_location
  DROP CONSTRAINT entity_to_location_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE entity_bank_account
  DROP CONSTRAINT entity_bank_account_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE entity_note
  DROP CONSTRAINT entity_note_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE entity_note
  DROP CONSTRAINT entity_note_ref_key_fkey,
  ADD FOREIGN KEY (ref_key) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE file_entity
  DROP CONSTRAINT file_entity_ref_key_fkey,
  ADD FOREIGN KEY (ref_key) REFERENCES entity (id) ON DELETE CASCADE;

-- entity type specialization
ALTER TABLE company
  DROP CONSTRAINT company_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE person
  DROP CONSTRAINT person_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE robot
  DROP CONSTRAINT robot_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

-- entity roles
ALTER TABLE entity_credit_account
  DROP CONSTRAINT entity_credit_account_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

ALTER TABLE entity_employee
  DROP CONSTRAINT entity_employee_entity_id_fkey,
  ADD FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE;

-- explicitly not adding 'users': cascading will delete the user
-- but whether users are used or not isn't detectable in the schema


-- ENTITY_CREDIT_ACCOUNT

-- eca additional data

ALTER TABLE eca_to_contact
  DROP CONSTRAINT eca_to_contact_credit_id_fkey,
  ADD FOREIGN KEY (credit_id) REFERENCES entity_credit_account (id) ON DELETE CASCADE;

ALTER TABLE eca_to_location
  DROP CONSTRAINT eca_to_location_credit_id_fkey,
  ADD FOREIGN KEY (credit_id) REFERENCES entity_credit_account (id) ON DELETE CASCADE;

ALTER TABLE eca_note
  DROP CONSTRAINT eca_note_ref_key_fkey,
  ADD FOREIGN KEY (ref_key) REFERENCES entity_credit_account (id) ON DELETE CASCADE;

ALTER TABLE eca_tax
  DROP CONSTRAINT eca_tax_eca_id_fkey,
  ADD FOREIGN KEY (eca_id) REFERENCES entity_credit_account (id) ON DELETE CASCADE;

ALTER TABLE file_eca
  DROP CONSTRAINT file_eca_ref_key_fkey,
  ADD FOREIGN KEY (ref_key) REFERENCES entity_credit_account (id) ON DELETE CASCADE;

-- (price matrix data as customer)
ALTER TABLE partscustomer
  DROP CONSTRAINT partscustomer_credit_id_fkey,
  ADD FOREIGN KEY (credit_id) REFERENCES entity_credit_account (id) ON DELETE CASCADE;

-- (price matrix data as vendor)
ALTER TABLE partsvendor
  DROP CONSTRAINT partsvendor_credit_id_fkey,
  ADD FOREIGN KEY (credit_id) REFERENCES entity_credit_account (id) ON DELETE CASCADE;

-- eca as business reporting unit
ALTER TABLE business_unit
  DROP CONSTRAINT business_unit_credit_id_fkey,
  ADD FOREIGN KEY (credit_id) REFERENCES entity_credit_account (id) ON DELETE CASCADE;
