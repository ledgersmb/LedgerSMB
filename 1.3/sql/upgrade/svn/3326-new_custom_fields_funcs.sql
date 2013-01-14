

CREATE OR REPLACE FUNCTION add_custom_field (VARCHAR, VARCHAR, VARCHAR) 
RETURNS BOOL AS
'
DECLARE
table_name ALIAS FOR $1;
new_field_name ALIAS FOR $2;
field_datatype ALIAS FOR $3;

BEGIN
	perform TABLE_ID FROM custom_table_catalog 
		WHERE extends = table_name;
	IF NOT FOUND THEN
		BEGIN
			INSERT INTO custom_table_catalog (extends) 
				VALUES (table_name);
			EXECUTE ''CREATE TABLE '' || 
                               quote_ident(''custom_'' ||table_name) ||
				'' (row_id INT PRIMARY KEY)'';
		EXCEPTION WHEN duplicate_table THEN
			-- do nothing
		END;
	END IF;
	INSERT INTO custom_field_catalog (field_name, table_id)
	values (new_field_name, (SELECT table_id 
                                        FROM custom_table_catalog
		WHERE extends = table_name));
	EXECUTE ''ALTER TABLE ''|| quote_ident(''custom_''||table_name) || 
                '' ADD COLUMN '' || quote_ident(new_field_name) || '' '' || 
                  quote_ident(field_datatype);
	RETURN TRUE;
END;
' LANGUAGE PLPGSQL;
-- end function

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
	EXECUTE ''ALTER TABLE '' || quote_ident(''custom_'' || table_name) || 
		'' DROP COLUMN '' || quote_ident(custom_field_name);
	RETURN TRUE;	
END;
' LANGUAGE PLPGSQL;
-- end function
