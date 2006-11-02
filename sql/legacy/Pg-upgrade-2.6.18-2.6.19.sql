BEGIN;

ALTER TABLE ap ADD PRIMARY KEY (id);

ALTER TABLE ar ADD PRIMARY KEY (id);

ALTER TABLE assembly ADD PRIMARY KEY (id, parts_id);

ALTER TABLE business ADD PRIMARY KEY (id);

ALTER TABLE customer ADD PRIMARY KEY (id);

ALTER TABLE customertax ADD PRIMARY KEY (customer_id, chart_id);

ALTER TABLE defaults ADD PRIMARY KEY (version);

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

ALTER TABLE orderitems ADD PRIMARY KEY (id);

ALTER TABLE parts ADD PRIMARY KEY (id);

ALTER TABLE partsgroup ADD PRIMARY KEY (id);

ALTER TABLE partstax ADD PRIMARY KEY (parts_id, chart_id);

ALTER TABLE pricegroup ADD PRIMARY KEY (id);

ALTER TABLE project ADD PRIMARY KEY (id);

ALTER TABLE recurringemail ADD PRIMARY KEY (id);

ALTER TABLE recurring ADD PRIMARY KEY (id);

ALTER TABLE recurringprint ADD PRIMARY KEY (id);

ALTER TABLE sic ADD PRIMARY KEY (code);

ALTER TABLE status ADD PRIMARY KEY (trans_id);

ALTER TABLE tax ADD PRIMARY KEY (chart_id);
ALTER TABLE tax ADD FOREIGN KEY (chart_id) REFERENCES chart (id);

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

LOCK tax IN EXCLUSIVE MODE;
ALTER TABLE tax ADD COLUMN pass int DEFAULT 0;
UPDATE tax SET pass = 0;
ALTER TABLE tax ALTER COLUMN pass SET NOT NULL;

ALTER TABLE tax ADD COLUMN taxmodule_id int REFERENCES taxmodule DEFAULT 1;
UPDATE tax SET taxmodule_id = 1;
ALTER TABLE tax ALTER COLUMN taxmodule_id SET NOT NULL;

-- Fixed session table and add users table --
BEGIN;
LOCK session in EXCLUSIVE MODE;
ALTER TABLE session ADD CONSTRAINT session_token_check check (length(token::text) = 32);
ALTER TABLE session ADD column user_id integer not null references users(id);

-- comment this out when user db is working:
ALTER TABLE session ALTER COLUMN user_id DROP NOT NULL;

LOCK users in EXCLUSIVE MODE;
CREATE TABLE users (id serial UNIQUE, username varchar(30) PRIMARY KEY);
COMMENT ON TABLE users 'username is the primary key because we don\'t want duplicate users';
LOCK users_conf in EXCLUSIVE MODE;
CREATE TABLE users_conf(id integer primary key references users(id) deferrable initially deferred,
                        acs text,
                        address text,
                        businessnumber text,
                        company text,
                        countrycode text,
                        currency text,
                        dateformat text,
                        dbconnect text,
                        dbdriver text default 'Pg',
                        dbhost text default 'localhost',
                        dbname text,
                        dboptions text,
                        dbpasswd text,
                        dbport text,
                        dbuser text,
                        email text,
                        fax text,
                        menuwidth text,
                        name text,
                        numberformat text,
                        password varchar(32) check(length(password) = 32),
                        print text,
                        printer text,
                        role text,
                        sid text,
                        signature text,
                        stylesheet text,
                        tel text,
                        templates text,
                        timeout numeric,
                        vclimit numeric);
COMMENT ON TABLE users_conf IS 'This is a completely dumb table that is a place holder to get usersconf into the database. Next major release will have a much more sane implementation';
COMMENT ON COLUMN users_conf.id IS 'Yes primary key with a FOREIGN KEY to users(id) is correct';
COMMENT ON COLUMN users_conf.password IS 'This means we have to get rid of the current password stuff and move to presumably md5()';
COMMIT;

-- Admin user --
BEGIN;
INSERT INTO users(username) VALUES ('admin');
INSERT INTO users_conf(id,password) VALUES (currval('users_id_seq'),NULL);
COMMIT;

-- Functions

CREATE FUNCTION create_user(text) RETURNS int4 AS $$
   INSERT INTO users(username) VALUES ('$1');
   SELECT currval('user_id_seq');
   $$ LANGUAGE 'SQL';

COMMENT ON FUNCTION create_user(text) IS $$ Function to create user Returns users.id if successful, else it is an error. $$;

CREATE FUNCTION update_user(int4,text) RETURNS int4 AS $$
   UPDATE users SET username = '$2' WHERE id = $1;
   SELECT 1;
   $$ LANGUAGE 'SQL';

COMMENT ON FUNCTION update_user(int4,text) IS $$ Takes int4 which is users.id and text which is username. Will update username based on id. Username is unique $$;

ALTER TABLE defaults RENAME TO old_defaults;

CREATE TABLE defaults (
	setting_key TEXT PRIMARY KEY,
	value TEXT
);

COMMENT ON TABLE defaults IS $$This table replaces the old one column per value system with a simple key => value table$$;


INSERT INTO defaults (setting_key, value) 
SELECT 'inventory_accno_id', inventory_accno_id FROM old_defaults
UNION
SELECT 'income_accno_id', income_accno_id FROM old_defaults
UNION
SELECT 'expense_accno_id', expense_accno_id FROM old_defaults
UNION
SELECT 'fxloss_accno_id', fxloss_accno_id FROM old_defaults
UNION
SELECT 'fxgain_accno_id', fxgain_accno_id FROM old_defaults
UNION
SELECT 'sinumber', sinumber FROM old_defaults
UNION
SELECT 'sonumber', sonumber FROM old_defaults
UNION
SELECT 'yearend', yearend FROM old_defaults
UNION
SELECT 'weightunit', weightunit FROM old_defaults
UNION
SELECT 'businessnumber', businessnumber FROM old_defaults
UNION
SELECT 'version', '1.2.0'
UNION
SELECT 'curr', curr FROM old_defaults
UNION
SELECT 'closedto', closedto FROM old_defaults
UNION
SELECT 'revtrans', revtrans FROM old_defaults
UNION
SELECT 'ponumber', ponumber FROM old_defaults
UNION
SELECT 'sqnumber', sqnumber FROM old_defaults
UNION
SELECT 'rfqnumber', rfqnumber FROM old_defaults
UNION
SELECT 'audittrail', audittrail FROM old_defaults
UNION
SELECT 'vinumber', vinumber FROM old_defaults
UNION
SELECT 'employeenumber', employeenumber FROM old_defaults
UNION
SELECT 'partnumber', partnumber FROM old_defaults
UNION
SELECT 'customernumber', customernumber FROM old_defaults
UNION
SELECT 'vendornumber', vendornumber FROM old_defaults
UNION
SELECT 'glnumber', glnumber FROM old_defaults
UNION
SELECT 'projectnumber', projectnumber FROM old_defaults
UNION
SELECT 'appname', 'LedgerSMB';

DROP TABLE old_defaults;

COMMIT;
