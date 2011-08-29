CREATE SEQUENCE session_session_id_seq;

CREATE TABLE session(
session_id INTEGER PRIMARY KEY DEFAULT nextval('session_session_id_seq'),
sl_login VARCHAR(50),
token CHAR(32),
last_used TIMESTAMP default now()
);

-- LOCK TABLE acc_trans;
ALTER TABLE acc_trans ALTER COLUMN chart_id SET NOT NULL;

-- For older versions pre 8.0.3
ALTER TABLE acc_trans ADD COLUMN amount2 NUMERIC;
UPDATE acc_trans set amount2 = amount;
ALTER TABLE acc_trans DROP COLUMN amount;
ALTER TABLE acc_trans RENAME column amount2 TO amount;

UPDATE defaults SET version = '2.6.17';
