BEGIN;

ALTER TABLE ap ADD PRIMARY KEY (id);

ALTER TABLE ar ADD PRIMARY KEY (id);

ALTER TABLE assembly ADD PRIMARY KEY (id, parts_id);

ALTER TABLE business ADD PRIMARY KEY (id);

ALTER TABLE customer ADD PRIMARY KEY (id);

ALTER TABLE customertax ADD PRIMARY KEY (customer_id, chart_id);

ALTER TABLE department ADD PRIMARY KEY (id);

ALTER TABLE dpt_trans ADD PRIMARY KEY (trans_id);

ALTER TABLE employee ADD PRIMARY KEY (id);

ALTER TABLE exchangerate ADD PRIMARY KEY (curr, transdate);

ALTER TABLE gifi ADD PRIMARY KEY (accno);

ALTER TABLE gl ADD PRIMARY KEY (id);

ALTER TABLE invoice ADD PRIMARY KEY (id);

ALTER TABLE jcitems ADD PRIMARY KEY (id);

ALTER TABLE language ADD PRIMARY KEY (code);

ALTER TABLE makemodel ADD PRIMARY KEY (parts_id);

ALTER TABLE oe ADD PRIMARY KEY (id);

SELECT setval('orderitemsid', 1);
UPDATE orderitems SET id = nextval('orderitemsid');

ALTER TABLE orderitems ADD PRIMARY KEY (id);

ALTER TABLE parts ADD PRIMARY KEY (id);

ALTER TABLE partsgroup ADD PRIMARY KEY (id);

ALTER TABLE partstax ADD PRIMARY KEY (parts_id, chart_id);
ALTER TABLE partstax ADD FOREIGN KEY (chart_id) REFERENCES chart (id);
ALTER TABLE partstax ADD FOREIGN KEY (parts_id) REFERENCES parts (id);

ALTER TABLE pricegroup ADD PRIMARY KEY (id);

ALTER TABLE project ADD PRIMARY KEY (id);

ALTER TABLE recurringemail ADD PRIMARY KEY (id);

ALTER TABLE recurring ADD PRIMARY KEY (id);

ALTER TABLE recurringprint ADD PRIMARY KEY (id);

ALTER TABLE sic ADD PRIMARY KEY (code);

ALTER TABLE status ADD PRIMARY KEY (trans_id);

-- Removing the primary key below since this is not quite the best way
-- do this.  The tax table could have multiple rows per chart_id.
-- We need a better fix for 1.3 (perhaps changing date to timestamp and
-- and defaulting to infinity.
-- ALTER TABLE tax ADD PRIMARY KEY (chart_id);
-- ALTER TABLE tax ADD FOREIGN KEY (chart_id) REFERENCES chart (id);

ALTER TABLE translation ADD PRIMARY KEY (trans_id, language_code);

ALTER TABLE vendor ADD PRIMARY KEY (id);

ALTER TABLE vendortax ADD PRIMARY KEY (vendor_id, chart_id);

ALTER TABLE warehouse ADD PRIMARY KEY (id);

ALTER TABLE yearend ADD PRIMARY KEY (trans_id);

LOCK inventory in EXCLUSIVE mode;
ALTER TABLE inventory ADD COLUMN entry_id bigint;
CREATE SEQUENCE inventory_entry_id_seq;

ALTER TABLE inventory ALTER COLUMN entry_id 
SET DEFAULT nextval('inventory_entry_id_seq');

UPDATE inventory SET entry_id = nextval('inventory_entry_id_seq');
ALTER TABLE inventory ADD PRIMARY key (entry_id);

LOCK partscustomer IN EXCLUSIVE MODE;
ALTER TABLE partscustomer ADD COLUMN entry_id int;
CREATE SEQUENCE partscustomer_entry_id_seq;

ALTER TABLE partscustomer ALTER COLUMN entry_id 
SET DEFAULT nextval('partscustomer_entry_id_seq');

UPDATE partscustomer SET entry_id = nextval('partscustomer_entry_id_seq');
ALTER TABLE partscustomer ADD PRIMARY KEY (entry_id);

LOCK partsvendor IN EXCLUSIVE MODE;
ALTER TABLE partsvendor ADD COLUMN entry_id int;
CREATE SEQUENCE partsvendor_entry_id_seq;

ALTER TABLE partsvendor ALTER COLUMN entry_id 
SET DEFAULT nextval('partsvendor_entry_id_seq');

UPDATE partsvendor SET entry_id = nextval('partsvendor_entry_id_seq');
ALTER TABLE partsvendor ADD PRIMARY KEY (entry_id);

LOCK audittrail IN EXCLUSIVE MODE;
ALTER TABLE audittrail ADD COLUMN entry_id int;
CREATE SEQUENCE audittrail_entry_id_seq ;

ALTER TABLE audittrail ALTER COLUMN entry_id 
SET DEFAULT nextval('audittrail_entry_id_seq');

UPDATE audittrail SET entry_id = nextval('audittrail_entry_id_seq');
ALTER TABLE audittrail ADD PRIMARY KEY (entry_id);

LOCK shipto IN EXCLUSIVE MODE;
ALTER TABLE shipto ADD COLUMN entry_id int;
CREATE SEQUENCE shipto_entry_id_seq ;

ALTER TABLE shipto ALTER COLUMN entry_id 
SET DEFAULT nextval('shipto_entry_id_seq');

UPDATE shipto SET entry_id = nextval('shipto_entry_id_seq');
ALTER TABLE shipto ADD PRIMARY KEY (entry_id);

CREATE TABLE taxmodule (
  taxmodule_id serial PRIMARY KEY,
  taxmodulename text NOT NULL
);

INSERT INTO taxmodule (
  taxmodule_id, taxmodulename
  ) VALUES (
  1, 'Simple'
);

CREATE TABLE taxcategory (
  taxcategory_id serial PRIMARY KEY,
  taxcategoryname text NOT NULL,
  taxmodule_id int NOT NULL REFERENCES taxmodule (taxmodule_id)
);

ALTER TABLE partstax ADD COLUMN taxcategory_id int REFERENCES taxcategory (taxcategory_id);

LOCK tax IN EXCLUSIVE MODE;
ALTER TABLE tax ADD COLUMN pass int DEFAULT 0;
UPDATE tax SET pass = 0;
ALTER TABLE tax ALTER COLUMN pass SET NOT NULL;

ALTER TABLE tax ADD COLUMN taxmodule_id int REFERENCES taxmodule DEFAULT 1;
UPDATE tax SET taxmodule_id = 1;
ALTER TABLE tax ALTER COLUMN taxmodule_id SET NOT NULL;

ALTER TABLE defaults RENAME TO old_defaults;

CREATE TABLE defaults (
	setting_key TEXT PRIMARY KEY,
	value TEXT
);

COMMENT ON TABLE defaults IS $$This table replaces the old one column per value system with a simple key => value table$$;


INSERT INTO defaults (setting_key, value) 
SELECT 'inventory_accno_id', inventory_accno_id::text FROM old_defaults
UNION
SELECT 'income_accno_id', income_accno_id::text FROM old_defaults
UNION
SELECT 'expense_accno_id', expense_accno_id::text FROM old_defaults
UNION
SELECT 'fxloss_accno_id', fxloss_accno_id::text FROM old_defaults
UNION
SELECT 'fxgain_accno_id', fxgain_accno_id::text FROM old_defaults
UNION
SELECT 'sinumber', sinumber::text FROM old_defaults
UNION
SELECT 'sonumber', sonumber::text FROM old_defaults
UNION
SELECT 'yearend', yearend::text FROM old_defaults
UNION
SELECT 'weightunit', weightunit::text FROM old_defaults
UNION
SELECT 'businessnumber', businessnumber::text FROM old_defaults
UNION
SELECT 'version', '1.2.0'::text
UNION
SELECT 'curr', curr::text FROM old_defaults
UNION
SELECT 'closedto', to_char(closedto, 'YYYY-MM-DD') FROM old_defaults
UNION
SELECT 'revtrans', (CASE WHEN revtrans IS NULL THEN NULL
			WHEN revtrans THEN '1' 
			ELSE '0' END) FROM old_defaults
UNION
SELECT 'ponumber', ponumber::text FROM old_defaults
UNION
SELECT 'sqnumber', sqnumber::text FROM old_defaults
UNION
SELECT 'rfqnumber', rfqnumber::text FROM old_defaults
UNION
SELECT 'audittrail', (CASE WHEN audittrail IS NULL THEN NULL
			WHEN audittrail THEN '1' 
			ELSE '0' END) FROM old_defaults
UNION
SELECT 'vinumber', vinumber::text FROM old_defaults
UNION
SELECT 'employeenumber', employeenumber::text FROM old_defaults
UNION
SELECT 'partnumber', partnumber::text FROM old_defaults
UNION
SELECT 'customernumber', customernumber::text FROM old_defaults
UNION
SELECT 'vendornumber', vendornumber::text FROM old_defaults
UNION
SELECT 'glnumber', glnumber::text FROM old_defaults
UNION
SELECT 'projectnumber', projectnumber::text FROM old_defaults
UNION
SELECT 'appname', 'LedgerSMB'::text;

DROP TABLE old_defaults;

CREATE OR REPLACE FUNCTION del_exchangerate() RETURNS TRIGGER AS '

declare
  t_transdate date;
  t_curr char(3);
  t_id int;
  d_curr text;

begin

  select into d_curr substr(value,1,3) from defaults where setting_key = ''curr'';
  
  if TG_RELNAME = ''ar'' then
    select into t_curr, t_transdate curr, transdate from ar where id = old.id;
  end if;
  if TG_RELNAME = ''ap'' then
    select into t_curr, t_transdate curr, transdate from ap where id = old.id;
  end if;
  if TG_RELNAME = ''oe'' then
    select into t_curr, t_transdate curr, transdate from oe where id = old.id;
  end if;

  if d_curr != t_curr then

    select into t_id a.id from acc_trans ac
    join ar a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate

    except select a.id from ar a where a.id = old.id
    
    union
    
    select a.id from acc_trans ac
    join ap a on (a.id = ac.trans_id)
    where a.curr = t_curr
    and ac.transdate = t_transdate
    
    except select a.id from ap a where a.id = old.id
    
    union
    
    select o.id from oe o
    where o.curr = t_curr
    and o.transdate = t_transdate
    
    except select o.id from oe o where o.id = old.id;

    if not found then
      delete from exchangerate where curr = t_curr and transdate = t_transdate;
    end if;
  end if;
return old;

end;
' language 'plpgsql';

CREATE OR REPLACE FUNCTION add_custom_field (VARCHAR, VARCHAR, VARCHAR)
RETURNS BOOL AS
'BEGIN
        EXECUTE ''SELECT TABLE_ID FROM custom_table_catalog
                WHERE extends = '''''' || table_name || '''''' '';
        IF NOT FOUND THEN
                BEGIN
                        INSERT INTO custom_table_catalog (extends)
                                VALUES (table_name);
                        EXECUTE ''CREATE TABLE custom_''||table_name ||
                                '' (row_id INT PRIMARY KEY)'';
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

COMMIT;
