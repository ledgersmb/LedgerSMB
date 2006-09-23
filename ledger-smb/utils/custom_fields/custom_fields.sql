
CREATE OR REPLACE FUNCTION add_custom_field (VARCHAR, VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
new_field_name ALIAS FOR $2;
field_datatype ALIAS FOR $3;

BEGIN
	EXECUTE ''SELECT TABLE_ID FROM custom_table_catalog 
		WHERE extends = '''''' || table_name || '''''' '';
	IF NOT FOUND THEN
		BEGIN
			INSERT INTO custom_table_catalog (extends) 
				VALUES (table_name);
			EXECUTE ''CREATE TABLE custom_''||table_name || 
				'' (row_id INT)'';
		EXCEPTION WHEN duplicate_table THEN
			-- do nothing
		END;
	END IF;
	EXECUTE ''INSERT INTO custom_field_catalog (field_name, table_id)
	VALUES ( '''''' || new_field_name ||'''''', (SELECT table_id FROM custom_table_catalog
		WHERE extends = ''''''|| table_name || ''''''))'';
	EXECUTE ''ALTER TABLE custom_''||table_name || '' ADD COLUMN '' 
		|| new_field_name || '' '' || field_datatype;
	RETURN TRUE;
END;
' LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION drop_custom_field (VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
custom_field_name ALIAS FOR $2;
BEGIN
	DELETE FROM custom_field_catalog 
	WHERE field_name = custom_field_name AND 
		table_id = (SELECT table_id FROM custom_table_catalog 
			WHERE extends = table_name);
	EXECUTE ''ALTER TABLE custom_'' || table_name || 
		'' DROP COLUMN '' || custom_field_name;
	RETURN TRUE;	
END;
' LANGUAGE PLPGSQL;
