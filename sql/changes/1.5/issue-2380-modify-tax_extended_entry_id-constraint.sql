
ALTER TABLE tax_extended DROP CONSTRAINT tax_extended_entry_id_fkey,
      ADD CONSTRAINT tax_extended_entry_id_fkey FOREIGN KEY (entry_id)
                     REFERENCES acc_trans (entry_id) ON DELETE CASCADE;
