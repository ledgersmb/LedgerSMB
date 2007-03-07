create table modules (
id SERIAL PRIMARY KEY,
mod_name TEXT UNIQUE NOT NULL,
comments text default ''
);
comment on table modules is $$name may be used as an alternate key.  
Comments should be used to provide the admin of the system with an 
understanding of what the module does.  Names and comments are also subject to 
string freezes since they may be translated by the application.$$;

-- not adding comments to these because they are translated anyway.
insert into modules (mod_name) values ('AR');
insert into modules (mod_name) values ('AP');
insert into modules (mod_name) values ('HR');
insert into modules (mod_name) values ('Order Entry');
insert into modules (mod_name) values ('Goods and Services');
insert into modules (mod_name) values ('Recurring Transactions');
insert into modules (mod_name) values ('System');

create or replace function add_module (text, text) returns int AS $$
insert into modules (mod_name, comments) values ($1, $2);
select currval(modules_id_seq);
$$ language sql;

create or replace function get_all_modules () returns setof modules as $$
select id, mod_name, comments from modules;
$$ language sql;

create or replace function get_module_by_id (int) returns modules as $$
select id, modname, comments from modules where id = $1;
$$ language sql;

create or replace function get_module_by_name (text) returns modules as $$
select id, modname, comments from modules where mod_name = $1;
$$ language sql;

create or replace function save_module (int, text, text) returns bool as $$
update modules set mod_name = $2, comments=$3 where id = $1;
$$ language sql;

create table mod_relation (
id serial primary key,
mod_id int not null references modules(id),
rel_name text NOT NULL,
rel_type "char" CHECK IN ('t', 's')
);

comment on table mod_relation is $$reltype is 't' for tables or views and 's' 
for sequences.  rel_name is the name of the table.$$;

create or replace function register_table (text, text) returns int AS $$
insert into mod_relation (mod_id, relname, reltype) values
((select id from modules where mod_name = $1), $2, 't');
select 1;
$$ language sql;

create or replace function register_sequence (text, text) returns int as $$
insert into module_relation (mod_id, relname, reltype) values
((select id from modules where mod_name = $1), $2, 's');
select 1;
$$ language sql;

select register_table('System', 'modules');
select register_table('System', 'mod_relation');
select register_sequence('System', 'modules_id_seq');
select register_sequence('System', 'mod_relation_id_seq');

create or replace function change_my_password(text) returns bool as $$
begin
execute 'alter user ''' || session_user || ''' with encrypted password ''' 
	|| $1 || '''';
return true;
end;
$$ language plpgsql security definer;

comment on function change_my_password is $$ This function must be created as a superuser to work!$$;

create table db_users (
id serial primary key,
username text unique not null,
active bool default true not null
);

comment on db_users is $$This is a list of users applicable to this 
dataset.  Note that the user creation script must connect to the dataset to be 
used and add the username to this table.  Otherwise the user will not be able 
to log in.$$;

create table preferences
(id integer primary key references db_users(id) deferrable initially deferred,
employee_id integer references employees(id), deferrable initially deferred,
                        countrycode text,
                        currency text,
                        dateformat text,
                        menuwidth text,
                        printer text,
                        signature text,
                        stylesheet text,
                        templates text,
                        timeout numeric,
                        vclimit numeric
	
);

create or replace function add_user (text) returns bool as $$
insert into dataset_users (username) values ($1);
select true;
$$ language sql;
