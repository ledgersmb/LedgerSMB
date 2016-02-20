
ALTER TABLE business_unit_ac
  DROP CONSTRAINT business_unit_ac_entry_id_fkey,
  ADD CONSTRAINT business_unit_ac_entry_id_fkey
     FOREIGN KEY (entry_id)
     REFERENCES acc_trans(entry_id)
     ON DELETE CASCADE;
ALTER TABLE business_unit_inv
  DROP CONSTRAINT business_unit_inv_entry_id_fkey,
  ADD CONSTRAINT business_unit_inv_entry_id_fkey
     FOREIGN KEY (entry_id)
     REFERENCES invoice(id)
     ON DELETE CASCADE;
CREATE INDEX business_unit_ac_entry_id_idx ON business_unit_ac (entry_id);
CREATE INDEX business_unit_inv_entry_id_idx ON business_unit_inv(entry_id);
CREATE INDEX business_unit_oitem_entry_id_idx ON business_unit_oitem(entry_id);
