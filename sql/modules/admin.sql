CREATE OR REPLACE FUNCTION admin_add_user_to_role(in_user TEXT, in_role TEXT) returns INT AS $$
    
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
        
        stmt := 'GRANT '|| in_role ||' to '|| in_user;
        
        EXECUTE stmt;
        
        return 1;
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_remove_user_from_role(in_user TEXT, in_role TEXT) returns INT AS $$
    
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
        
        stmt := 'REVOKE '|| in_role ||' FROM '|| in_user;
        
        EXECUTE stmt;
        
        return 1;    
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_add_function_to_group(in_func TEXT, in_role TEXT) returns INT AS $$
    
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
        
        stmt := 'GRANT EXECUTE ON FUNCTION '|| in_func ||' to '|| in_role;
        
        EXECUTE stmt;
        
        return 1;
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_remove_function_from_group(in_func TEXT, in_role TEXT) returns INT AS $$
    
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
        
        stmt := 'REVOKE EXECUTE ON FUNCTION '|| in_func ||' FROM '|| in_role;
        
        EXECUTE stmt;
        
        return 1;    
    END;
    
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_add_table_to_group(in_table TEXT, in_role TEXT, in_perm TEXT) returns INT AS $$
    
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
        
        stmt := 'GRANT '|| in_perm|| 'ON TABLE '|| in_table ||' to '|| in_role;
        
        EXECUTE stmt;
        
        return 1;
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_remove_table_from_group(in_table TEXT, in_role TEXT) returns INT AS $$
    
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
        
        SELECT table_schema, table_name from 
        
        select table_name into a_table from information_schema.tables 
        where table_schema NOT IN ('information_schema','pg_catalog','pg_toast') 
        and table_type='BASE TABLE' 
        and table_name = in_table;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions from a non-existant table.';
        END IF;
        
        stmt := 'REVOKE '|| in_role ||' FROM '|| in_user;
        
        EXECUTE stmt;
        
        return 1;    
    END;
        
$$ language 'plpgsql';

create or replace function admin_get_user(in_user TEXT) returns setof user as $$
    
    DECLARE
        a_user user;
    BEGIN
        
        select * into a_user from user where username = in_user;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'cannot find user %', in_user;
        END IF;
        
        return a_user;
    
    END;    
$$ language plpgsql;

create or replace function admin_get_roles_for_user(in_user TEXT) returns setof lsmb_roles as $$
    
    declare
        u_role lsmb_roles;
        a_user user;
    begin
        select * into a_user from admin_get_user(in_user);
        
        FOR u_role IN select * from lsmb_roles WHERE user = a_user.id LOOP
        
            RETURN NEXT a_role;
        
        END LOOP;
        RETURN;
    end;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_save_user(
    in_id int, 
    in_username text, 
    in_password TEXT, 
    in_dbname TEXT, 
    in_host TEXT, 
    in_port TEXT
) returns int AS $$
    DECLARE
    
        a_user user;
        v_entity_id int;
        p_id int;
        l_id int;
        stmt text;
    BEGIN
    
        select * into a_user from user where id = in_id;
        
        IF NOT FOUND THEN 
            -- Insert cycle
            
            --- First, create an entity.
            
            if admin_is_user(in_username) then
                
                -- uhm, this is bad.
                RAISE EXCEPTION 
                    "Fatal exception: Username already exists in Postgres; not
                    a valid lsmb user.";
            end if;
            
            v_entity_id := nextval('entity_id_seq');
                
            INSERT INTO entity (id, name, entity_class) VALUES (
                v_entity_id,
                in_first_name || ' ' || in_last_name,
                3
            );
            
            -- create an actual user
            insert into users (name, entity_id) VALUES (
                in_username,
                v_entity_id
            );
            
            insert into user_connection (entity_id, database, host, port) 
                VALUES (
                    v_entity_id,
                    in_database,
                    in_host,
                    in_port                    
                );
            
            -- Finally, issue the create user statement
            
            stmt := $$CREATE USER $$||in_username||$$WITH ENCRYPTED PASSWORD '$$||in_password||$$;'$$;
            execute stmt;
            
            return v_entity_id;

        ELSIF FOUND THEN
            
            -- update cycle
            
            -- Only update if it's changed. Wewt.
            UPDATE entity SET name = in_first_name || ' ' || in_last_name 
            WHERE entity_id = a_user.entity_id and 
            name <> in_first_name || ' ' || in_last_name;
            
            stmt := $$ alter user $$ || in_username || $$ with encrypted password $1$$$ || in_password || $$$1$ $$;
            execute stmt;
            
            update user_connection set database = in_database, host = in_host, port = in_port
            where database <> in_database
            OR host <> in_host
            OR port <> in_port;
            
            return a_user.id;
        
        END IF;
    
    END;
$$ language 'plpgsql';

create view role_view as 
    select * from pg_auth_members m join pg_authid a ON (m.roleid = a.oid);
        

create or replace function admin_is_group(in_group_name text) returns bool as $$
    
    DECLARE
        
        existant_role role_view;
        stmt text;
        
    BEGIN
        select * into role_view from role_view where rolname = in_group_name;
        
        if not found then
            return 'f'::bool;
            
        else
            return 't'::bool;
        end if;            
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_create_group(in_group_name TEXT, in_dbname TEXT) RETURNS int as $$
    
    DECLARE
        
        stmt text;
        
    BEGIN
        stmt := 'create role '||in_dbname||'_lsmb_$$' || in_group_name || '$$;';
        execute stmt;
        return 1;
    END;
    
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION admin_delete_user(in_username TEXT) returns INT as $$
    
    DECLARE
        stmt text;
        a_user user;
    BEGIN
    
        select * into a_user from users where username = in_username;
        
        IF NOT FOUND THEN
        
            raise exception "User not found.";
        ELSIF FOUND THEN
    
            stmt := $$ drop user $$ || a_user.username ||;
            execute stmt;
            
            -- also gets user_connection
            delete from users where id = a_user.id; 
            delete from entity where id = a_user.entity_id;
                                        
        END IF;   
    END;
    
$$ language 'plpgsql';

comment on function admin_delete_user(text) is $$ 
    Drops the provided user, as well as deletes the entity and user configuration data.
$$;

CREATE OR REPLACE FUNCTION admin_delete_group (in_group_name TEXT) returns bool as $$
    
    DECLARE
        stmt text;
        a_role role_view;
    BEGIN
        
        select * into a_role from role_view where rolname = in_group_name;
        
        if not found then
            return 'f'::bool;
        else
            stmt := 'drop role $dbname_lsmb_$$' || in_group_name || '$$;';
            execute stmt;
            return 't'::bool;
        end if;
    END;
$$ language 'plpgsql';

comment on function admin_delete_group(text) IS $$ 
    Deletes the input group from the database. Not designed to be used to 
    remove a login-capable user.
$$;

CREATE OR REPLACE FUNCTION admin_list_roles(in_username text)
RETURNS SETOF text AS
$$
DECLARE out_rolename RECORD;
BEGIN
	FOR out_rolename IN 
		SELECT rolname FROM pg_authid 
		WHERE oid IN (SELECT id FROM connectby(
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
$$ LANGUAGE PLPGSQL;

-- TODO:  Add admin user


CREATE OR REPLACE FUNCTION admin_audit_log () returns int as $$
    
    
    
$$ language plpgsql;