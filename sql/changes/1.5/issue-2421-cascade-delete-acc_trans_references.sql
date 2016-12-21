
ALTER TABLE cr_report
    DROP CONSTRAINT cr_report_max_ac_id_fkey,
    ADD CONSTRAINT cr_report_max_ac_id_fkey FOREIGN KEY (max_ac_id)
        REFERENCES acc_trans(entry_id) ON DELETE CASCADE;

ALTER TABLE cr_report_line
    DROP CONSTRAINT cr_report_line_report_id_fkey,
    ADD CONSTRAINT cr_report_line_report_id_fkey FOREIGN KEY (report_id)
        REFERENCES cr_report(id) ON DELETE CASCADE;

ALTER TABLE payment_links
    DROP CONSTRAINT payment_links_entry_id_fkey,
    ADD CONSTRAINT payment_links_entry_id_fkey FOREIGN KEY (entry_id)
        REFERENCES acc_trans (entry_id) ON DELETE CASCADE;

ALTER TABLE ac_tax_form
    DROP CONSTRAINT ac_tax_form_entry_id_fkey,
    ADD CONSTRAINT ac_tax_form_entry_id_fkey FOREIGN KEY (entry_id)
        REFERENCES acc_trans (entry_id) ON DELETE CASCADE;
