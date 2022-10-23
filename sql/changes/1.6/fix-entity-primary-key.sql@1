-- Change primary key on entity table
-- Existing primary key is (control_code, entity_class), but that serves no
-- purpose as control_code already has a unique index.
-- Drop the useless primary key, making id the new primary key

-- Drop the existing primary key
ALTER TABLE entity DROP CONSTRAINT entity_pkey;

-- Temporarily drop the foreign key references to entity(id)
-- Do this individually, rather than using CASCADE, so that we can be
-- sure to recreate them all later.
ALTER TABLE ap DROP CONSTRAINT ap_entity_id_fkey;
ALTER TABLE ar DROP CONSTRAINT ar_entity_id_fkey;
ALTER TABLE asset_report DROP CONSTRAINT asset_report_approved_by_fkey;
ALTER TABLE asset_report DROP CONSTRAINT asset_report_entered_by_fkey;
ALTER TABLE budget_info DROP CONSTRAINT budget_info_approved_by_fkey;
ALTER TABLE budget_info DROP CONSTRAINT budget_info_entered_by_fkey;
ALTER TABLE budget_info DROP CONSTRAINT budget_info_obsolete_by_fkey;
ALTER TABLE company DROP CONSTRAINT company_entity_id_fkey;
ALTER TABLE cr_report DROP CONSTRAINT cr_report_approved_by_fkey;
ALTER TABLE cr_report DROP CONSTRAINT cr_report_deleted_by_fkey;
ALTER TABLE cr_report DROP CONSTRAINT cr_report_entered_by_fkey;
ALTER TABLE cr_report_line DROP CONSTRAINT cr_report_line_user_fkey;
ALTER TABLE entity_bank_account DROP CONSTRAINT entity_bank_account_entity_id_fkey;
ALTER TABLE entity_credit_account DROP CONSTRAINT entity_credit_account_entity_id_fkey;
ALTER TABLE entity_employee DROP CONSTRAINT entity_employee_entity_id_fkey;
ALTER TABLE entity_employee DROP CONSTRAINT entity_employee_manager_id_fkey;
ALTER TABLE entity_note DROP CONSTRAINT entity_note_entity_id_fkey;
ALTER TABLE entity_note DROP CONSTRAINT entity_note_ref_key_fkey;
ALTER TABLE entity_other_name DROP CONSTRAINT entity_other_name_entity_id_fkey;
ALTER TABLE entity_to_contact DROP CONSTRAINT entity_to_contact_entity_id_fkey;
ALTER TABLE entity_to_location DROP CONSTRAINT entity_to_location_entity_id_fkey;
ALTER TABLE file_base DROP CONSTRAINT file_base_uploaded_by_fkey;
ALTER TABLE file_entity DROP CONSTRAINT file_entity_ref_key_fkey;
ALTER TABLE file_secondary_attachment DROP CONSTRAINT file_secondary_attachment_attached_by_fkey;
ALTER TABLE journal_entry DROP CONSTRAINT journal_entry_approved_by_fkey;
ALTER TABLE journal_entry DROP CONSTRAINT journal_entry_entered_by_fkey;
ALTER TABLE oe DROP CONSTRAINT oe_entity_id_fkey;
ALTER TABLE payroll_deduction DROP CONSTRAINT payroll_deduction_entity_id_fkey;
ALTER TABLE payroll_paid_timeoff DROP CONSTRAINT payroll_paid_timeoff_employee_id_fkey;
ALTER TABLE payroll_report_line DROP CONSTRAINT payroll_report_line_employee_id_fkey;
ALTER TABLE payroll_wage DROP CONSTRAINT payroll_wage_entity_id_fkey;
ALTER TABLE person DROP CONSTRAINT person_entity_id_fkey;
ALTER TABLE transactions DROP CONSTRAINT transactions_approved_by_fkey;
ALTER TABLE users DROP CONSTRAINT users_entity_id_fkey;
ALTER TABLE robot DROP CONSTRAINT robot_entity_id_fkey;

-- Drop the existing UNIQUE constraint on id
ALTER TABLE entity DROP CONSTRAINT entity_id_key;

-- Recreate it as a PRIMARY KEY
ALTER TABLE entity ADD CONSTRAINT entity_pkey PRIMARY KEY (id);

-- Recreate the foreign key constraints we removed earlier
-- These will make use of the new primary key
ALTER TABLE ap ADD CONSTRAINT ap_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE ar ADD CONSTRAINT ar_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE asset_report ADD CONSTRAINT asset_report_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES entity(id);
ALTER TABLE asset_report ADD CONSTRAINT asset_report_entered_by_fkey FOREIGN KEY (entered_by) REFERENCES entity(id);
ALTER TABLE budget_info ADD CONSTRAINT budget_info_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES entity(id);
ALTER TABLE budget_info ADD CONSTRAINT budget_info_entered_by_fkey FOREIGN KEY (entered_by) REFERENCES entity(id);
ALTER TABLE budget_info ADD CONSTRAINT budget_info_obsolete_by_fkey FOREIGN KEY (obsolete_by) REFERENCES entity(id);
ALTER TABLE company ADD CONSTRAINT company_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE cr_report ADD CONSTRAINT cr_report_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES entity(id);
ALTER TABLE cr_report ADD CONSTRAINT cr_report_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES entity(id);
ALTER TABLE cr_report ADD CONSTRAINT cr_report_entered_by_fkey FOREIGN KEY (entered_by) REFERENCES entity(id);
ALTER TABLE cr_report_line ADD CONSTRAINT cr_report_line_user_fkey FOREIGN KEY ("user") REFERENCES entity(id);
ALTER TABLE entity_bank_account ADD CONSTRAINT entity_bank_account_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE entity_credit_account ADD CONSTRAINT entity_credit_account_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE entity_employee ADD CONSTRAINT entity_employee_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE entity_employee ADD CONSTRAINT entity_employee_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES entity(id);
ALTER TABLE entity_note ADD CONSTRAINT entity_note_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE entity_note ADD CONSTRAINT entity_note_ref_key_fkey FOREIGN KEY (ref_key) REFERENCES entity(id);
ALTER TABLE entity_other_name ADD CONSTRAINT entity_other_name_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE entity_to_contact ADD CONSTRAINT entity_to_contact_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE entity_to_location ADD CONSTRAINT entity_to_location_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE file_base ADD CONSTRAINT file_base_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES entity(id);
ALTER TABLE file_entity ADD CONSTRAINT file_entity_ref_key_fkey FOREIGN KEY (ref_key) REFERENCES entity(id);
ALTER TABLE file_secondary_attachment ADD CONSTRAINT file_secondary_attachment_attached_by_fkey FOREIGN KEY (attached_by) REFERENCES entity(id);
ALTER TABLE journal_entry ADD CONSTRAINT journal_entry_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES entity(id);
ALTER TABLE journal_entry ADD CONSTRAINT journal_entry_entered_by_fkey FOREIGN KEY (entered_by) REFERENCES entity(id);
ALTER TABLE oe ADD CONSTRAINT oe_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE payroll_deduction ADD CONSTRAINT payroll_deduction_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE payroll_paid_timeoff ADD CONSTRAINT payroll_paid_timeoff_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES entity(id);
ALTER TABLE payroll_report_line ADD CONSTRAINT payroll_report_line_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES entity(id);
ALTER TABLE payroll_wage ADD CONSTRAINT payroll_wage_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE person ADD CONSTRAINT person_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE transactions ADD CONSTRAINT transactions_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES entity(id);
ALTER TABLE users ADD CONSTRAINT users_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
ALTER TABLE robot ADD CONSTRAINT robot_entity_id_fkey FOREIGN KEY (entity_id) REFERENCES entity(id);
