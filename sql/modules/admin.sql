-- README:  This module is unlike most others in that it requires most functions
-- to run as superuser.  For this reason it is CRITICAL that the following
-- practices are adhered to:
-- 1:  When using EXECUTE, all user-supplied information MUST be passed through 
--     quote_literal.
-- 2:  This file MUST be frequently audited to ensure the above rule is followed
--
-- -CT


create table lsmb_roles (
    
    user_id integer not null references users,
    role text not null
    
);

CREATE OR REPLACE FUNCTION admin__add_user_to_role(in_user TEXT, in_role TEXT) returns INT AS $$
    
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
        
        select rolname into a_user from pg_roles where rolname = in_user;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions to a non-existant user.';
        END IF;
        
        stmt := 'GRANT '|| quote_ident(in_role) ||' to '|| quote_ident(in_user);
        
        EXECUTE stmt;
        insert into lsmb_roles (user_id, role) values (in_user, in_role);
        return 1;
    END;
    
$$ language 'plpgsql' security definer;

REVOKE EXECUTE ON FUNCTION admin__add_user_to_role(TEXT, TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION admin__remove_user_from_role(in_user TEXT, in_role TEXT) returns INT AS $$
    
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
        
        select rolname into a_user from pg_roles where rolname = in_user;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions from a non-existant user.';
        END IF;
        
        stmt := 'REVOKE '|| quote_ident(in_role) ||' FROM '|| quote_ident(in_user);
        
        EXECUTE stmt;
        
        return 1;    
    END;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__remove_user_from_role(TEXT, TEXT) FROM PUBLIC;

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
        
        select rolname into a_user from pg_roles where rolname = in_user;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions to a non-existant user.';
        END IF;
        
        stmt := 'GRANT EXECUTE ON FUNCTION '|| quote_ident(in_func) ||' to '|| quote_ident(in_role);
        
        EXECUTE stmt;
        
        return 1;
    END;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__add_function_to_group(TEXT, TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION admin__remove_function_from_group(in_func TEXT, in_role TEXT) returns INT AS $$
    
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
        
        select rolname into a_user from pg_roles where rolname = in_user;
        
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

CREATE OR REPLACE FUNCTION admin__add_table_to_group(in_table TEXT, in_role TEXT, in_perm TEXT) returns INT AS $$
    -- Do we need this table stuff at the moment? CT 
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
        
        select table_name into a_table from information_schema.tables 
        where table_schema NOT IN ('information_schema','pg_catalog','pg_toast') 
        and table_type='BASE TABLE' 
        and table_name = in_table;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions to a non-existant table.';
        END IF;
        
        if lower(in_perm) not in ('select','insert','update','delete') THEN
            raise exception 'Cannot add unknown permission';
        END IF;
        
        stmt := 'GRANT '|| quote_ident(in_perm) || 'ON TABLE '|| quote_ident(in_table) ||' to '|| quote_ident(in_role);
        
        EXECUTE stmt;
        
        return 1;
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin__remove_table_from_group(in_table TEXT, in_role TEXT) returns INT AS $$
    -- do we need this table stuff at the moment?  CT
    declare
        stmt TEXT;
        a_role name;
        a_table text;
    BEGIN
    
        -- Issue the grant
        select rolname into a_role from pg_roles where rolname = in_role;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions of a non-existant role.';
        END IF;
        
        select table_name into a_table from information_schema.tables 
        where table_schema NOT IN ('information_schema','pg_catalog','pg_toast') 
        and table_type='BASE TABLE' 
        and table_name = in_table;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions from a non-existant table.';
        END IF;
        
        stmt := 'REVOKE '|| quote_literal(in_role) ||' FROM '|| quote_literal(in_user);
        
        EXECUTE stmt;
        
        return 1;    
    END;
        
$$ language 'plpgsql';

create or replace function admin__get_user(in_user INT) returns setof users as $$
    
    DECLARE
        a_user users;
    BEGIN
        
        select * into a_user from users where id = in_user;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'cannot find user %', in_user;
        END IF;
        
        return next a_user;
        return;
    
    END;    
$$ language plpgsql;

create or replace function admin__get_roles_for_user(in_user_id INT) returns setof text as $$
    
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
        
            RETURN NEXT u_role.rolname;
        
        END LOOP;
        RETURN;
    end;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__get_roles_for_user(in_user_id INT) from PUBLIC;

CREATE OR REPLACE FUNCTION user__check_my_expiration()
returns interval as
$$
DECLARE
    outval interval;
BEGIN
    SELECT CASE WHEN isfinite(rolvaliduntil) is not true THEN '1 year'::interval
                ELSE rolvaliduntil - now() END AS expiration INTO outval 
    FROM pg_authid WHERE rolname = SESSION_USER;
    RETURN outval;
end;
$$ language plpgsql security definer;

CREATE OR REPLACE FUNCTION user__expires_soon()
RETURNS BOOL AS
$$
   SELECT user__check_my_expiration() < '1 week';
$$ language sql;

CREATE OR REPLACE FUNCTION user__change_password(in_new_password text)
returns int as
$$
DECLARE
	t_expires timestamp;
BEGIN
    SELECT now() + (value::numeric::text || ' days')::interval INTO t_expires
    FROM defaults WHERE setting_key = 'password_duration';

    UPDATE users SET notify_password = DEFAULT where username = SESSION_USER;

    EXECUTE 'ALTER USER ' || quote_ident(SESSION_USER) || 
            ' with ENCRYPTED password ' || quote_literal(in_new_password);

    IF t_expires IS NOT NULL THEN
         EXECUTE 'ALTER USER ' || quote_ident(SESSION_USER) ||
                 ' VALID UNTIL '|| quote_literal(t_expires);
    END IF;
    return 1;
END;
$$ language plpgsql security definer;

CREATE OR REPLACE FUNCTION admin__save_user(
    in_id int, 
    in_entity_id INT,
    in_username text, 
    in_password TEXT
) returns int AS $$
    DECLARE
    
        a_user users;
        v_user_id int;
        p_id int;
        l_id int;
        stmt text;
    BEGIN
        -- WARNING TO PROGRAMMERS:  This function runs as the definer.
        -- PLEASE BE VERY CAREFUL ABOUT SQL-INJECTION INSIDE THIS FUNCTION.
    
        select * into a_user from users lu where lu.id = in_id;
        
        IF NOT FOUND THEN 
            -- Insert cycle
            
            --- The entity is expected to already BE created. See admin.pm.
            
            if admin__is_user(in_username) then
                
                -- uhm, this is bad. -AS.  Not necessarily.  -CT 
                RAISE EXCEPTION 'Fatal exception: Username already exists in Postgres; not
                    a valid lsmb user.';
            end if;         
            -- create an actual user
            
            v_user_id := nextval('users_id_seq');
            insert into users (id, username, entity_id) VALUES (
                v_user_id,
                in_username,
                in_entity_id
            );
            
            insert into user_preference (id) values (v_user_id);

            -- Finally, issue the create user statement
            
            execute 'CREATE USER ' || quote_ident( in_username ) || 
                     ' WITH ENCRYPTED PASSWORD ' || quote_literal (in_password)
                     || $e$ valid until now() + '1 day'::interval $e$;
            
            return v_user_id ;

        ELSIF FOUND THEN
            
            -- update cycle
            
            execute ' alter user '|| quote_ident(in_username) || 
                     ' with encrypted password ' 
                             || quote_literal(in_password) || 
                     $e$ valid until now()::timezone + '1 day'::interval $e$;
            
                      
            return a_user.id;
        
        END IF;
    
    END;
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__save_user(
    in_id int,
    in_entity_id INT,
    in_username text,
    in_password TEXT
) FROM public; 

create view role_view as 
    select * from pg_auth_members m join pg_authid a ON (m.roleid = a.oid);
        

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

CREATE OR REPLACE FUNCTION admin__delete_user(in_username TEXT) returns INT as $$
    
    DECLARE
        stmt text;
        a_user users;
    BEGIN
    
        select * into a_user from users where username = in_username;
        
        IF NOT FOUND THEN
        
            raise exception 'User not found.';
        ELSIF FOUND THEN
    
            stmt := ' drop user ' || quote_ident(a_user.username);
            execute stmt;
            
            -- also gets user_connection
            delete from entity where id = a_user.entity_id;
                                        
        END IF;   
    END;
    
$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__delete_user(in_username TEXT) from public;

comment on function admin__delete_user(text) is $$ 
    Drops the provided user, as well as deletes the user configuration data.
It leaves the entity and person references.
$$;

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

CREATE OR REPLACE FUNCTION admin__list_roles(in_username text)
RETURNS SETOF text AS
$$
DECLARE out_rolename RECORD;
BEGIN
	FOR out_rolename IN 
		SELECT rolname FROM pg_authid 
		WHERE oid IN (SELECT id FROM connectby (
			'(SELECT m.member, m.roleid, r.oid FROM pg_authid r 
			LEFT JOIN pg_auth_members m ON (r.oid = m.roleid)) a',
			'oid', 'member', 'oid', '320461', '0', ','
			) c(id integer, parent integer, "level" integer, 
				path text, list_order integer)
			)
	LOOP
		RETURN NEXT out_rolename.rolname;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

REVOKE execute on function admin__list_roles(in_username text) from public;

-- TODO:  Add admin user

--CREATE OR REPLACE FUNCTION admin_audit_log () returns int as $$
    
    
    
--$$ language plpgsql;

create or replace function admin__is_user (in_user text) returns bool as $$
    DECLARE
        pg_user pg_roles;
    
    BEGIN
    
        select * into pg_user from pg_roles where rolname = in_user;
        
        IF NOT FOUND THEN
            return 'f'::bool;
        END IF;
        return 't'::bool;
    
    END;
    
$$ language plpgsql;


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
        SELECT 
            rolname
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

create or replace function user__get_preferences (in_user int) returns setof user_preference as $$
    
declare
    v_row user_preference;
BEGIN
    select * into v_row from user_preference where id = in_user;
    
    IF NOT FOUND THEN
    
        RAISE EXCEPTION 'Could not find user preferences for id %', in_user;
    ELSE
        return next v_row;
    END IF;
END;
$$ language plpgsql;

