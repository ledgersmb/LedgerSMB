DELETE FROM transactions;

CREATE OR REPLACE FUNCTION track_global_sequence() RETURNS TRIGGER AS
$$
BEGIN
	IF tg_op = 'INSERT' THEN
		INSERT INTO transactions (id, table_name) 
		VALUES (new.id, TG_RELNAME);
	ELSEIF tg_op = 'UPDATE' THEN
		IF new.id = old.id THEN
			return new;
		ELSE
			UPDATE transactions SET id = new.id WHERE id = old.id;
		END IF;
	ELSE 
		DELETE FROM transactions WHERE id = old.id;
	END IF;
	RETURN new;
END;
$$ LANGUAGE PLPGSQL;

INSERT INTO transactions (id, table_name) SELECT id, 'ap' FROM ap;
DROP RULE ap_id_track_i ON ap; 
DROP RULE ap_id_track_u ON ap; 

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON ap
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON ap
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'ar' FROM ar;

DROP RULE ar_id_track_i ON ar;
DROP RULE ar_id_track_u ON ar;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON ar
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON ar
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'business' FROM business;

DROP RULE business_id_track_i ON business;
DROP RULE business_id_track_u ON business; 

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON business
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON business
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'chart' FROM chart;

DROP RULE chart_id_track_i ON chart;
DROP RULE chart_id_track_u ON chart;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON chart
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON chart
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'customer' FROM customer;

DROP RULE customer_id_track_i ON customer;
DROP RULE customer_id_track_u ON customer;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON customer
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON customer
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'department' FROM department;

DROP RULE department_id_track_i ON department;
DROP RULE department_id_track_u ON department;

INSERT INTO transactions (id, table_name) SELECT id, 'employee' FROM employee;

DROP RULE employee_id_track_i ON employee;
DROP RULE employee_id_track_u ON employee;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON employee
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON employee
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'gl' FROM gl;

DROP RULE gl_id_track_i ON gl;
DROP RULE gl_id_track_u ON gl;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON gl
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON gl
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'oe' FROM oe;

DROP RULE oe_id_track_i ON oe;
DROP RULE oe_id_track_u ON oe;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON oe
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON oe
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'parts' FROM parts;

DROP RULE parts_id_track_i ON parts;
DROP RULE parts_id_track_u ON parts;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON parts
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON parts
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'partsgroup' FROM partsgroup;

DROP RULE partsgroup_id_track_i ON partsgroup;
DROP RULE partsgroup_id_track_u ON partsgroup;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON partsgroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON partsgroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'pricegroup' FROM pricegroup;

DROP RULE pricegroup_id_track_i ON pricegroup;
DROP RULE pricegroup_id_track_u ON pricegroup; 

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON pricegroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON pricegroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'project' FROM project;

DROP RULE project_id_track_i ON project;
DROP RULE project_id_track_u ON project; 

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON project
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON project
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'vendor' FROM vendor;

DROP RULE vendor_id_track_i ON vendor;
DROP RULE employee_id_track_u ON vendor; 

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON vendor
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON vendor
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'warehouse' FROM warehouse;

DROP RULE warehouse_id_track_i ON warehouse;
DROP RULE warehouse_id_track_u ON warehouse;

CREATE TRIGGER track_global_inserts_iu BEFORE INSERT OR UPDATE ON warehouse
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts_d AFTER DELETE ON warehouse
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();
