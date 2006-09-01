
CREATE SEQUENCE session_session_id_seq;

CREATE TABLE session(
session_id INTEGER PRIMARY KEY DEFAULT nextval('session_session_id_seq'),
sl_login VARCHAR(50),
token CHAR(32),
last_used TIMESTAMP default now()
);

ALTER TABLE acc_trans ALTER COLUMN chart_id SET NOT NULL;
