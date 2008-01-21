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

insert into transactions (id, table_name) SELECT id, 'ap' FROM ap;
DROP RULE ap_id_track_i ON ap; 
DROP RULE ap_id_track_u ON update TO ap; 

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON ap
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON ap
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

insert into transactions (id, table_name) SELECT id, 'ar' FROM ar;

DROP RULE ar_id_track_i ON insert TO ar;
DROP RULE ar_id_track_u ON update TO ar;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON ar
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON ar
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'business' FROM business;

DROP RULE business_id_track_i ON insert TO business;
DROP RULE business_id_track_u ON update TO business 

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON business
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON business
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'chart' FROM chart;

DROP RULE chart_id_track_i ON insert TO chart;
DROP RULE chart_id_track_u ON update TO chart;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON chart
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON chart
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'customer' FROM customer;

DROP RULE customer_id_track_i ON insert TO customer;
DROP RULE customer_id_track_u ON update TO customer;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON customer
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON customer
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'department' FROM department;

DROP RULE department_id_track_i ON insert TO department;
DROP RULE department_id_track_u ON update TO department;

INSERT INTO transactions (id, table_name) SELECT id, 'employee' FROM employee;

DROP RULE employee_id_track_i ON insert TO employee;
DROP RULE employee_id_track_u ON update TO employee;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON employee
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON employee
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'gl' FROM gl;

DROP RULE gl_id_track_i ON insert TO gl;
DROP RULE gl_id_track_u ON update TO gl;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON gl
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON gl
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'oe' FROM oe;

DROP RULE oe_id_track_i ON insert TO oe;
DROP RULE oe_id_track_u ON update TO oe;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON oe
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON oe
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'parts' FROM parts;

DROP RULE parts_id_track_i ON insert TO parts;
DROP RULE parts_id_track_u ON update TO parts;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON parts
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON parts
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'partsgroup' FROM partsgroup;

DROP RULE partsgroup_id_track_i ON insert TO partsgroup;
DROP RULE partsgroup_id_track_u ON update TO partsgroup;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON partsgroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON partsgroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'pricegroup' FROM pricegroup;

DROP RULE pricegroup_id_track_i ON insert TO pricegroup;
DROP RULE pricegroup_id_track_u ON update TO pricegroup; 

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON pricegroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON pricegroup
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'project' FROM project;

DROP RULE project_id_track_i ON insert TO project;
DROP RULE project_id_track_u ON update TO project; 

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON project
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON project
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'vendor' FROM vendor;

DROP RULE vendor_id_track_i ON insert TO vendor;
DROP RULE employee_id_track_u ON update TO vendor; 

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON vendor
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON vendor
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

INSERT INTO transactions (id, table_name) SELECT id, 'warehouse' FROM warehouse;

DROP RULE warehouse_id_track_i ON insert TO warehouse;
DROP RULE warehouse_id_track_u ON update TO warehouse;

CREATE TRIGGER track_global_inserts BEFORE INSERT OR UPDATE ON warehouse
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();

CREATE TRIGGER track_global_inserts AFTER DELETE ON warehouse
FOR EACH ROW EXECUTE PROCEDURE track_global_sequence();
