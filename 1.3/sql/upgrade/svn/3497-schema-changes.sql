ALTER TABLE invoice ADD FOREIGN KEY (trans_id) REFERENCES transactions(id);
ALTER TABLE invoice ADD FOREIGN KEY (parts_id) REFERENCES parts(id);

ALTER TABLE tax ADD FOREIGN KEY (chart_id) REFERENCES account(id);
CREATE TRIGGER ap_audit_trail AFTER insert or update or delete ON ap
FOR EACH ROW EXECUTE PROCEDURE gl_audit_trail_append();


