-- Central DB structure
-- This is the central database stuff which is used across all datasets
-- in the ledger-smb.conf it is called 'ledgersmb' by default, but obviously
-- can be named anything.

-- USERS stuff --
CREATE TABLE users (id serial UNIQUE, username varchar(30) primary key);
COMMENT ON TABLE users IS $$username is the actual primary key here because we do not want duplicate users$$;
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

-- Per conversation with ChrisM, if the admin user has a null password a couple of things happen.
-- 1. It is implicit that this is an initial install
-- 2. If the admin password does not match the ledger-smb.conf admin password, we throw a hijack alert
-- The two below statements must be run from a single session
INSERT INTO users(username) VALUES ('admin');
INSERT INTO users_conf(id,password) VALUES (currval('users_id_seq'),NULL);


CREATE OR REPLACE FUNCTION create_user(text) RETURNS bigint AS $$
   INSERT INTO users(username) VALUES ($1);
   SELECT currval('users_id_seq');
   $$ LANGUAGE 'SQL';

COMMENT ON FUNCTION create_user(text) IS $$ Function to create user. Returns users.id if successful, else it is an error. $$;

CREATE OR REPLACE FUNCTION update_user(int4,text) RETURNS int4 AS $$
   UPDATE users SET username = $2 WHERE id = $1;
   SELECT 1;
   $$ LANGUAGE 'SQL';

COMMENT ON FUNCTION update_user(int4,text) IS $$ Takes int4 which is users.id and text which is username. Will update username based on id. Username is unique $$;


-- Session tracking table


CREATE TABLE session(
session_id serial PRIMARY KEY,
sl_login VARCHAR(50),
token VARCHAR(32) CHECK(length(token) = 32),
last_used TIMESTAMP default now(),
users_id INTEGER  -- NOT NULL references users(id)
);

