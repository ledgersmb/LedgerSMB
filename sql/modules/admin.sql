
-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General 
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

-- README:  This module is unlike most others in that it requires most functions
-- to run as superuser.  For this reason it is CRITICAL that the following
-- practices are adhered to:
-- 1:  When using EXECUTE, all user-supplied information MUST be passed through 
--     quote_literal.
-- 2:  This file MUST be frequently audited to ensure the above rule is followed
--
-- -CT

-- work in progress, not documenting yet.
CREATE OR REPLACE FUNCTION admin__add_user_to_role(in_username TEXT, in_role TEXT) returns INT AS $$
    
    declare
        stmt TEXT;
        a_role name;
        a_user name;
    BEGIN
    
        -- Issue the grant
        select rolname into a_role from pg_roles where rolname = in_role;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions of a non-existant role.';
        END IF;
        
        select rolname into a_user from pg_roles where rolname = in_username;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions to a non-existant user.';
        END IF;
        
        stmt := 'GRANT '|| quote_ident(in_role) ||' to '|| quote_ident(in_username);
        
        EXECUTE stmt;
        insert into lsmb_roles (user_id, role) 
        SELECT id, in_role from users where username = in_username;
        return 1;
    END;
    
$$ language 'plpgsql' security definer;

REVOKE EXECUTE ON FUNCTION admin__add_user_to_role(TEXT, TEXT) FROM PUBLIC;

-- work in progress.  Not documenting yet.
CREATE OR REPLACE FUNCTION admin__remove_user_from_role(in_username TEXT, in_role TEXT) returns INT AS $$
    
    declare
        stmt TEXT;
        a_role name;
        a_user name;
    BEGIN
    
        -- Issue the grant
        select rolname into a_role from pg_roles where rolname = in_role;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions of a non-existant role.';
        END IF;
        
        select rolname into a_user from pg_roles where rolname = in_username;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions from a non-existant user.';
        END IF;
        
        stmt := 'REVOKE '|| quote_ident(in_role) ||' FROM '|| quote_ident(in_username);
        
        EXECUTE stmt;
        
        return 1;    
    END;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__remove_user_from_role(TEXT, TEXT) FROM PUBLIC;

-- work in progress. Not documenting yet.
CREATE OR REPLACE FUNCTION admin__add_function_to_group(in_func TEXT, in_role TEXT) returns INT AS $$
    
    declare
        stmt TEXT;
        a_role name;
        a_user name;
    BEGIN
    
        -- Issue the grant
        select rolname into a_role from pg_roles where rolname = in_role;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions of a non-existant role.';
        END IF;
        
        select rolname into a_user from pg_roles where rolname = in_username;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions to a non-existant user.';
        END IF;
        
        stmt := 'GRANT EXECUTE ON FUNCTION '|| quote_ident(in_func) ||' to '|| quote_ident(in_role);
        
        EXECUTE stmt;
        
        return 1;
    END;
    
$$ language 'plpgsql' SECURITY DEFINER;


REVOKE EXECUTE ON FUNCTION admin__add_function_to_group(TEXT, TEXT) FROM PUBLIC;

-- work in progress, not documenting yet.
CREATE OR REPLACE FUNCTION admin__remove_function_from_group(in_func TEXT, in_role TEXT) returns INT AS $$
    
    declare
        stmt TEXT;
        a_role name;
        a_user name;
    BEGIN
    
        -- Issue the grant
        select rolname into a_role from pg_roles where rolname = in_role;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions of non-existant role $.';
        END IF;
        
        select rolname into a_user from pg_roles where rolname = in_username;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions from a non-existant function.';
        END IF;
        
        stmt := 'REVOKE EXECUTE ON FUNCTION '|| quote_ident(in_func) ||' FROM '|| quote_ident(in_role);
        
        EXECUTE stmt;
        
        return 1;    
    END;
    
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__remove_function_from_group(text, text) 
FROM public;

-- not even sure if these should be here --CT
--CREATE OR REPLACE FUNCTION admin__add_table_to_group(in_table TEXT, in_role TEXT, in_perm TEXT) returns INT AS $$
    -- Do we need this table stuff at the moment? CT 
--    declare
--        stmt TEXT;
--        a_role name;
--        a_user name;
--    BEGIN
    
        -- Issue the grant
--        select rolname into a_role from pg_roles where rolname = in_role;
        
--        IF NOT FOUND THEN
--            RAISE EXCEPTION 'Cannot grant permissions of a non-existant role.';
--        END IF;
        
--        select table_name into a_table from information_schema.tables 
--        where table_schema NOT IN ('information_schema','pg_catalog','pg_toast') 
--        and table_type='BASE TABLE' 
--        and table_name = in_table;
        
--        IF NOT FOUND THEN
--            RAISE EXCEPTION 'Cannot grant permissions to a non-existant table.';
--        END IF;
        
--        if lower(in_perm) not in ('select','insert','update','delete') THEN
--            raise exception 'Cannot add unknown permission';
--        END IF;
        
 --       stmt := 'GRANT '|| quote_ident(in_perm) || 'ON TABLE '|| quote_ident(in_table) ||' to '|| quote_ident(in_role);
        
--        EXECUTE stmt;
        
--        return 1;
--    END;
    
--$$ language 'plpgsql';

--CREATE OR REPLACE FUNCTION admin__remove_table_from_group(in_table TEXT, in_role TEXT) returns INT AS $$
    -- do we need this table stuff at the moment?  CT
--    declare
--        stmt TEXT;
--        a_role name;
--        a_table text;
--    BEGIN
    
        -- Issue the grant
--        select rolname into a_role from pg_roles where rolname = in_role;
        
--        IF NOT FOUND THEN
 --           RAISE EXCEPTION 'Cannot revoke permissions of a non-existant role.';
--        END IF;
--        
--        select table_name into a_table from information_schema.tables 
 --       where table_schema NOT IN ('information_schema','pg_catalog','pg_toast') 
 --       and table_type='BASE TABLE' 
 --       and table_name = in_table;
        
--        IF NOT FOUND THEN
--            RAISE EXCEPTION 'Cannot revoke permissions from a non-existant table.';
--        END IF;
        
--        stmt := 'REVOKE '|| quote_literal(in_role) ||' FROM '|| quote_literal(in_user);
        
 --       EXECUTE stmt;
        
  --      return 1;    
--    END;
        
--$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin__get_user(in_entity_id INT) returns setof users as $$
    
    DECLARE
        a_user users;
    BEGIN
        
        select * into a_user from users where entity_id = in_entity_id;
        return next a_user;
        return;
    
    END;    
$$ language plpgsql;

COMMENT ON FUNCTION admin__get_user(in_user_id INT) IS
$$ Returns a set of (only one) user specified by the id.$$;

CREATE OR REPLACE FUNCTION admin__get_roles_for_user(in_user_id INT) returns setof text as $$
    
    declare
        u_role record;
        a_user users;
    begin
        select * into a_user from admin__get_user(in_user_id);
        
        FOR u_role IN 
        select r.rolname 
        from 
            pg_roles r,
            (select 
                m.roleid 
             from 
                pg_auth_members m, pg_roles b 
             where 
                m.member = b.oid 
             and 
                b.rolname = a_user.username
            ) as ar
         where 
            r.oid = ar.roleid
         LOOP
        
            RETURN NEXT u_role.rolname::text;
        
        END LOOP;
        RETURN;
    end;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__get_roles_for_user(in_user_id INT) from PUBLIC;

COMMENT ON FUNCTION admin__get_roles_for_user(in_user_id INT) IS
$$ Returns a set of roles that  a user is a part of.$$;

CREATE OR REPLACE FUNCTION user__check_my_expiration()
returns interval as
$$
DECLARE
    outval interval;
BEGIN
    SELECT CASE WHEN isfinite(rolvaliduntil) is not true THEN '1 year'::interval
                ELSE rolvaliduntil - now() END AS expiration INTO outval 
    FROM pg_roles WHERE rolname = SESSION_USER;
    RETURN outval;
end;
$$ language plpgsql security definer;

COMMENT ON FUNCTION user__check_my_expiration() IS
$$ Returns the time when password of the current logged in user is set to 
expire.$$; 

CREATE OR REPLACE FUNCTION user__expires_soon()
RETURNS BOOL AS
$$
   SELECT user__check_my_expiration() < '1 week';
$$ language sql;

COMMENT ON FUNCTION user__expires_soon() IS
$$ Returns true if the password of the current logged in user is set to expire 
within on week.$$;

CREATE OR REPLACE FUNCTION user__change_password(in_new_password text)
returns int as
$$
DECLARE
	t_expires timestamp;
        t_password_duration text;
BEGIN
    SELECT value INTO t_password_duration FROM defaults 
     WHERE setting_key = 'password_duration';
    IF t_password_duration IS NULL or t_password_duration='' THEN
        t_expires := 'infinity';
    ELSE
        t_expires := now() 
                     + (t_password_duration::numeric::text || ' days')::interval;
    END IF;


    UPDATE users SET notify_password = DEFAULT where username = SESSION_USER;

    EXECUTE 'ALTER USER ' || quote_ident(SESSION_USER) || 
            ' with ENCRYPTED password ' || quote_literal(in_new_password) ||
                 ' VALID UNTIL '|| quote_literal(t_expires);
    return 1;
END;
$$ language plpgsql security definer;

COMMENT ON FUNCTION user__change_password(in_new_password text) IS
$$ Alloes a user to change his or her own password.  The password is set to 
expire setting_get('password_duration') days after the password change.$$;

CREATE OR REPLACE FUNCTION admin__save_user(
    in_id int, 
    in_entity_id INT,
    in_username text, 
    in_password TEXT,
    in_import BOOL
) returns int AS $$
    DECLARE
    
        a_user users;
        v_user_id int;
        p_id int;
        l_id int;
        stmt text;
        t_is_role bool;
        t_is_user bool;
    BEGIN
        -- WARNING TO PROGRAMMERS:  This function runs as the definer and runs
        -- utility statements via EXECUTE.
        -- PLEASE BE VERY CAREFUL ABOUT SQL-INJECTION INSIDE THIS FUNCTION.

       PERFORM rolname FROM pg_roles WHERE rolname = in_username;
       t_is_role := found;
       t_is_user := admin__is_user(in_username);

       IF t_is_role is true and t_is_user is false and in_import is false THEN
          RAISE EXCEPTION 'Duplicate user';
        END IF;

        if t_is_role and in_password is not null then
                execute 'ALTER USER ' || quote_ident( in_username ) || 
                     ' WITH ENCRYPTED PASSWORD ' || quote_literal (in_password)
                     || $e$ valid until $e$ || 
                      quote_literal(now() + '1 day'::interval);
        elsif in_import is false AND t_is_user is false 
              AND in_password IS NULL THEN
                RAISE EXCEPTION 'No password';
        elsif  t_is_role is false THEN
            -- create an actual user
                execute 'CREATE USER ' || quote_ident( in_username ) || 
                     ' WITH ENCRYPTED PASSWORD ' || quote_literal (in_password)
                     || $e$ valid until $e$ || quote_literal(now() + '1 day'::interval);
       END IF;         
        
        select * into a_user from users lu where lu.id = in_id;
        IF FOUND THEN 
            return a_user.id;
        ELSE
            -- Insert cycle
            
            --- The entity is expected to already BE created. See admin.pm.
            
            
            v_user_id := nextval('users_id_seq');
            insert into users (id, username, entity_id) VALUES (
                v_user_id,
                in_username,
                in_entity_id
            );
            
            insert into user_preference (id) values (v_user_id);

            IF NOT exists(SELECT * FROM entity_employee WHERE entity_id = in_entity_id) THEN
                INSERT into entity_employee (entity_id) values (in_entity_id);
            END IF;
            -- Finally, issue the create user statement
            
            return v_user_id ;

            
        
        END IF;
    
    END;
$$ language 'plpgsql' SECURITY DEFINER;

COMMENT ON FUNCTION admin__save_user(
    in_id int,
    in_entity_id INT,
    in_username text,
    in_password TEXT,
    in_import BOOL
)  IS
$$ Creates a user and relevant records in LedgerSMB and PostgreSQL.$$;

REVOKE EXECUTE ON FUNCTION admin__save_user(
    in_id int,
    in_entity_id INT,
    in_username text,
    in_password TEXT,
    in_import bool
) FROM public; 

create view role_view as 
    select * from pg_auth_members m join pg_roles a ON (m.roleid = a.oid);
        
-- work in progress, not for public docs yet
create or replace function admin__is_group(in_group_name text) returns bool as $$
    -- This needs some work.  CT 
    DECLARE
        
        existant_role pg_roles;
        stmt text;
        
    BEGIN
        select * into existant_role from pg_roles 
        where rolname = in_group_name AND rolcanlogin is false;
        
        if not found then
            return 'f'::bool;
            
        else
            return 't'::bool;
        end if;            
    END;
    
$$ language 'plpgsql';

-- work in progress, not for public docs yet
CREATE OR REPLACE FUNCTION admin__create_group(in_group_name TEXT) RETURNS int as $$
    
    DECLARE
        
        stmt text;
        t_dbname text;
    BEGIN
	t_dbname := current_database();
        stmt := 'create role lsmb_'|| quote_ident(t_dbname || '__' || in_group_name);
        execute stmt;
        return 1;
    END;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION  admin__create_group(TEXT) FROM PUBLIC;

-- not sure if this is exposed to the front end yet. --CT
CREATE OR REPLACE FUNCTION admin__delete_user
(in_username TEXT, in_drop_role bool) returns INT as $$
    
    DECLARE
        stmt text;
        a_user users;
    BEGIN
    
        select * into a_user from users where username = in_username;
        
        IF NOT FOUND THEN
        
            raise exception 'User not found.';
        ELSIF FOUND THEN
            IF in_drop_role IS TRUE then 
                stmt := ' drop user ' || quote_ident(a_user.username);
                execute stmt;
            END IF;    
            -- also gets user_connection
            delete from user_preference where id = (
                   select id from users where entity_id = a_user.entity_id);
            delete from users where entity_id = a_user.entity_id;
            return 1;
        END IF;   
    END;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__delete_user(in_username TEXT, 
in_drop_role bool) from public;

comment on function admin__delete_user(text, bool) is $$ 
    Drops the provided user, as well as deletes the user configuration data.
It leaves the entity and person references.

If in_drop_role is set, it drops the role too.
$$;

-- Work oin progress, not for ducmenting yet.
CREATE OR REPLACE FUNCTION admin__delete_group (in_group_name TEXT) returns bool as $$
    
    DECLARE
        stmt text;
        a_role role_view;
        t_dbname text;
    BEGIN
        t_dbname := current_database();
        

        select * into a_role from role_view where rolname = in_group_name;
        
        if not found then
            return 'f'::bool;
        else
            stmt := 'drop role lsmb_' || quote_ident(t_dbname || '__' || in_group_name);
            execute stmt;
            return 't'::bool;
        end if;
    END;
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE on function admin__delete_group(text) from public;

comment on function admin__delete_group(text) IS $$ 
    Deletes the input group from the database. Not designed to be used to 
    remove a login-capable user.
$$;

-- TODO:  Add admin user

--CREATE OR REPLACE FUNCTION admin_audit_log () returns int as $$
    
    
    
--$$ language plpgsql;

create or replace function admin__is_user (in_user text) returns bool as $$
    BEGIN
    
        PERFORM * from users where username = in_user;
        RETURN found;     
    
    END;
    
$$ language plpgsql;

COMMENT ON function admin__is_user (in_user text) IS
$$ Returns true if user is set up in LedgerSMB.  False otherwise.$$;

create or replace view user_listable as 
    select 
        u.id,
        u.username,
        e.created
    from entity e
    join users u on u.entity_id = e.id;
        

create or replace function user__get_all_users () returns setof user_listable as $$
    
    select * from user_listable;
    
$$ language sql;

create or replace function admin__get_roles () returns setof pg_roles as $$
DECLARE
    v_rol record;
    t_dbname text;
BEGIN
    t_dbname := current_database();
    FOR v_rol in 
        SELECT *
        from 
            pg_roles
        where 
            rolname ~ ('^lsmb_' || t_dbname || '__') 
            and rolcanlogin is false
        order by rolname ASC
    LOOP
        RETURN NEXT v_rol;
    END LOOP;
END;
$$ language plpgsql;

create or replace function user__save_preferences(
	in_dateformat text,
	in_numberformat text,
	in_language text,
	in_stylesheet text,
	in_printer text
) returns bool as 
$$
BEGIN
    UPDATE user_preference
    SET dateformat = in_dateformat,
        numberformat = in_numberformat,
        language = in_language,
        stylesheet = in_stylesheet,
        printer = in_printer
    WHERE id = (select id from users where username = SESSION_USER);
    RETURN FOUND;
END;
$$ language plpgsql;

COMMENT ON function user__save_preferences(
        in_dateformat text,
        in_numberformat text,
        in_language text,
        in_stylesheet text,
        in_printer text
) IS
$$ Saves user preferences.  Returns true if successful, false if no preferences
were found to update.$$;

create or replace function user__get_preferences (in_user_id int) returns setof user_preference as $$
    
declare
    v_row user_preference;
BEGIN
    select * into v_row from user_preference where id = in_user_id;
    
    IF NOT FOUND THEN
    
        RAISE EXCEPTION 'Could not find user preferences for id %', in_user_id;
    ELSE
        return next v_row;
    END IF;
END;
$$ language plpgsql;

COMMENT ON function user__get_preferences (in_user_id int) IS
$$ Returns the preferences row for the user.$$;

CREATE TYPE user_result AS (
	id int,
	username text,
	first_name text,
	last_name text,
	ssn text,
	dob text
);


CREATE OR REPLACE FUNCTION  admin__search_users(in_username text, in_first_name text, in_last_name text, in_ssn text, in_dob date) RETURNS SETOF user_result AS
$$
DECLARE t_return_row user_result;
BEGIN
	FOR t_return_row IN
		SELECT u.id, u.username, p.first_name, p.last_name, e.ssn, e.dob
		FROM users u
		JOIN person p ON (u.entity_id = p.entity_id)
		JOIN entity_employee e ON (e.entity_id = p.entity_id)
		WHERE u.username LIKE '%' || coalesce(in_username,'') || '%' AND
			(p.first_name = in_first_name or in_first_name is null)
			AND (p.last_name = in_last_name or in_last_name is null)
			AND (in_ssn is NULL or in_ssn = e.ssn) 
			AND (e.dob = in_dob::date or in_dob is NULL)
	LOOP
		RETURN NEXT t_return_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION  admin__search_users(in_username text, in_first_name text, in_last_name text, in_ssn text, in_dob date) IS
$$ Returns a list of users matching search criteria.  Nulls match all values.
only username is not an exact match.$$;

CREATE TYPE session_result AS (
	id int,
	username text,
	last_used timestamp,
	locks_active bigint
);

CREATE OR REPLACE FUNCTION admin__list_sessions() RETURNS SETOF session_result
AS $$
SELECT s.session_id, u.username, s.last_used, count(t.id)
FROM "session" s
JOIN users u ON (s.users_id = u.id)
LEFT JOIN transactions t ON (t.locked_by = s.session_id)
GROUP BY s.session_id, u.username, s.last_used
ORDER BY u.username;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION admin__list_sessions() IS 
$$ Lists all active sessions.$$;

CREATE OR REPLACE FUNCTION admin__drop_session(in_session_id int) RETURNS bool AS
$$
BEGIN
	DELETE FROM "session" WHERE session_id = in_session_id;
	RETURN FOUND;
END;
$$ language plpgsql;

COMMENT ON FUNCTION admin__drop_session(in_session_id int) IS
$$ Drops the session identified, releasing all locks held.$$;
