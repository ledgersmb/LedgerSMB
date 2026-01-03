
set client_min_messages = 'warning';



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

BEGIN;
-- work in progress, not documenting yet.
CREATE OR REPLACE FUNCTION admin__add_user_to_role(in_username TEXT, in_role TEXT) returns INT AS $$

    declare
        stmt TEXT;
        a_role name;
        a_user name;
        t_userid int;
        t_in_role TEXT;
    BEGIN

        -- Issue the grant
        -- Make sure to evaluate the role once because the optimizer
        -- uses it as a filter on every row otherwise
        SELECT lsmb__role(in_role) INTO t_in_role;
        select rolname into a_role from pg_roles
          where rolname = t_in_role;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions of a non-existant role.';
        END IF;

        select rolname into a_user from pg_roles
         where rolname = in_username;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions to a non-existant database user.';
        END IF;

        select id into t_userid from users where username = in_username;
        if not FOUND then
          RAISE EXCEPTION 'Cannot grant permissions to a non-existant application user.';
        end if;

        stmt := 'GRANT '|| quote_ident(a_role) ||' to '|| quote_ident(in_username);

        EXECUTE stmt;

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
        t_in_role TEXT;
    BEGIN

        -- Issue the grant
        -- Make sure to evaluate the role once because the optimizer
        -- uses it as a filter on every row otherwise
        SELECT lsmb__role(in_role) INTO t_in_role;
        select rolname into a_role from pg_roles
         where rolname = t_in_role;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions of a non-existant role.';
        END IF;

        select rolname into a_user from pg_roles
         where rolname = in_username;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot revoke permissions from a non-existant user.';
        END IF;

        stmt := 'REVOKE '|| quote_ident(a_role) ||' FROM '|| quote_ident(in_username);

        EXECUTE stmt;

        return 1;
    END;

$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__remove_user_from_role(TEXT, TEXT) FROM PUBLIC;


DROP FUNCTION IF EXISTS  admin__get_user(in_entity_id INT);
CREATE OR REPLACE FUNCTION admin__get_user(in_id INT) returns users as $$

        select * from users where id = in_id;

$$ language sql;

COMMENT ON FUNCTION admin__get_user(in_user_id INT) IS
$$ Returns a set of (only one) user specified by the id.$$;

DROP FUNCTION IF EXISTS admin__get_user_by_entity(in_entity_id INT);

CREATE OR REPLACE FUNCTION admin__get_user_by_entity(in_entity_id INT) returns users as $$

        select * from users where entity_id = in_entity_id;

$$ language sql;

COMMENT ON FUNCTION admin__get_user_by_entity(in_entity_id INT) IS
$$ Returns a set of (only one) user specified by the entity_id.$$;

DROP FUNCTION IF EXISTS admin__get_roles_for_user(in_entity_id INT);
CREATE OR REPLACE FUNCTION admin__get_roles_for_user(in_user_id INT) returns setof text as $$

    declare
        u_role record;
        a_user users;
        t_role_prefix TEXT;
    begin
        select * into a_user from admin__get_user(in_user_id);

        -- this function used to be security definer, but that hides the true
        -- CURRENT_USER, returning the DEFINER instead of the caller
        IF a_user.username != CURRENT_USER THEN
            -- super users and application users match the first criterion
            -- db owners and db owner group members match the second criterion
            IF pg_has_role(lsmb__role('users_manage'), 'USAGE') IS FALSE
               AND pg_has_role((select rolname
                                 from pg_database db inner join pg_roles rol
                                   on db.datdba = rol.oid
                                where db.datname = current_database()),
                               'USAGE') IS FALSE THEN
               RAISE EXCEPTION 'User % querying permissions for %, not authorised', CURRENT_USER, a_user.username;
            END IF;
        END IF;

        -- Make sure to evaluate the role prefix once because the optimizer
        -- uses it as a filter on every row otherwise
        SELECT lsmb__role_prefix() INTO t_role_prefix;
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
            and position(t_role_prefix in r.rolname) = 1
         LOOP

            RETURN NEXT lsmb__global_role(u_role.rolname);

        END LOOP;
        RETURN;
    end;

$$ language 'plpgsql';

REVOKE EXECUTE ON FUNCTION admin__get_roles_for_user(in_entity_id INT) from PUBLIC;

COMMENT ON FUNCTION admin__get_roles_for_user(in_user_id INT) IS
$$Returns a set of roles that  a user is a part of.

Note: this function can only be used by
 - super users
 - database admins (setup.pl users):
   - database owners
   - database users (roles) which were granted the database owner role
 - application users:
   - application admins (users with 'manage_users' role)
   - application users (roles) which query their own roles
$$;

CREATE OR REPLACE FUNCTION admin__get_roles_for_user_by_entity(in_entity_id INT) returns setof text as $$

    declare
        u_role record;
        a_user users;
        t_role_prefix TEXT;
    begin
        select * into a_user from admin__get_user_by_entity(in_entity_id);

        -- this function used to be security definer, but that hides the true
        -- CURRENT_USER, returning the DEFINER instead of the caller
        IF a_user.username != CURRENT_USER THEN
            -- super users and application users match the first criterion
            -- db owners and db owner group members match the second criterion
            IF pg_has_role(lsmb__role('users_manage'), 'USAGE') IS FALSE
               AND pg_has_role((select rolname
                                 from pg_database db inner join pg_roles rol
                                   on db.datdba = rol.oid
                                where db.datname = current_database()),
                               'USAGE') IS FALSE THEN
               RAISE EXCEPTION 'User % querying permissions for %, not authorised', CURRENT_USER, a_user.username;
            END IF;
        END IF;

        -- Make sure to evaluate the role prefix once because the optimizer
        -- uses it as a filter on every row otherwise
        SELECT lsmb__role_prefix() INTO t_role_prefix;
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
            and position(t_role_prefix in r.rolname) = 1
         LOOP

            RETURN NEXT lsmb__global_role(u_role.rolname);

        END LOOP;
        RETURN;
    end;

$$ language 'plpgsql';

REVOKE EXECUTE ON FUNCTION admin__get_roles_for_user_by_entity(in_entity_id INT) from PUBLIC;

COMMENT ON FUNCTION admin__get_roles_for_user_by_entity(in_entity_id INT) IS
$$Returns a set of roles that  a user is a part of.

Note: this function can only be used by
 - super users
 - database admins (setup.pl users):
   - database owners
   - database users (roles) which were granted the database owner role
 - application users:
   - application admins (users with 'manage_users' role)
   - application users (roles) which query their own roles
$$;


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

CREATE OR REPLACE FUNCTION user__change_password(in_new_password text)
returns int SET datestyle = 'ISO, YMD' as -- datestyle needed due to legacy code
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
$$ Allows a user to change his or her own password.  The password is set to
expire setting_get('password_duration') days after the password change.$$;

DROP FUNCTION IF EXISTS admin__save_user(int, int, text, text, bool);

CREATE OR REPLACE FUNCTION admin__save_user(
    in_id int,
    in_entity_id INT,
    in_username text,
    in_password TEXT,
    in_pls_import BOOL
) returns int
SET datestyle = 'ISO, YMD' -- needed due to legacy code regarding datestyles
AS $$
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

       IF t_is_role is true and t_is_user is false and in_pls_import is NOT TRUE THEN
          RAISE EXCEPTION 'Duplicate user';
        END IF;

        if t_is_role and in_password is not null then
                execute 'ALTER USER ' || quote_ident( in_username ) ||
                     ' WITH ENCRYPTED PASSWORD ' || quote_literal (in_password)
                     || $e$ valid until $e$ ||
                      quote_literal(now() + '1 day'::interval);
        elsif in_pls_import is false AND t_is_user is false
              AND in_password IS NULL THEN
                RAISE EXCEPTION 'No password';
        elsif  t_is_role is false and in_pls_import IS NOT TRUE THEN
            -- create an actual user
                execute 'CREATE USER ' || quote_ident( in_username ) ||
                     ' WITH ENCRYPTED PASSWORD ' || quote_literal (in_password)
                     || $e$ valid until $e$ || quote_literal(now() + '1 day'::interval);
       END IF;

        select * into a_user from users lu where lu.id = in_id;
        IF FOUND THEN
            PERFORM admin__add_user_to_role(a_user.username, 'base_user');
            return a_user.id;
        ELSE
            -- Insert cycle

            --- The entity is expected to already BE created. See admin.pm.

            PERFORM * FROM USERS where username = in_username;
            IF NOT FOUND THEN
                v_user_id := nextval('users_id_seq');
                insert into users (id, username, entity_id) VALUES (
                    v_user_id,
                    in_username,
                    in_entity_id
                );
            END IF;

            IF NOT exists(SELECT * FROM entity_employee WHERE entity_id = in_entity_id) THEN
                INSERT into entity_employee (entity_id) values (in_entity_id);
            END IF;
            -- Finally, issue the create user statement
            PERFORM admin__add_user_to_role(in_username, 'base_user');
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



--  not sure if this is exposed to the front end yet. --CT
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
            -- delete cascades into user_preference by schema definition
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
        e.created,
        e.name,
        e.control_code
    from entity e
    join users u on u.entity_id = e.id;


create or replace function user__get_all_users () returns setof user_listable as $$

    select * from user_listable;

$$ language sql;


DROP FUNCTION IF EXISTS admin__get_roles();

create or replace function admin__get_roles () returns setof pg_roles as $$
DECLARE
   u_role pg_roles;
   t_role_prefix TEXT;
begin
    -- Make sure to evaluate the role prefix once because the optimizer
    -- uses it as a filter on every row otherwise
     SELECT lsmb__role_prefix() INTO t_role_prefix;
     FOR u_role IN
        SELECT *
        FROM
            pg_roles
        WHERE
            rolname ~ ('^' || t_role_prefix)
            AND NOT rolcanlogin
        ORDER BY lsmb__global_role(rolname) ASC
     LOOP
        u_role.rolname = lsmb__global_role(u_role.rolname);

        RETURN NEXT u_role;
     END LOOP;
end;
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
    perform preference__set('dateformat', in_dateformat);
    perform preference__set('numberformat', in_numberformat);
    perform preference__set('language', in_language);
    perform preference__set('stylesheet', in_stylesheet);
    perform preference__set('printer', in_printer);

    RETURN true;
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


DROP TYPE if exists user_preferences CASCADE;
CREATE TYPE user_preferences AS (
  dateformat text,
  numberformat text,
  language text,
  stylesheet text,
  printer text
);

DROP FUNCTION IF EXISTS user__get_preferences (in_user_id int);
create or replace function user__get_preferences (in_user_id int)
returns user_preferences as $$

declare
    v_row user_preferences;
BEGIN
    --TODO This is a workaround waiting to be replaced with something more
    -- appropriate for returning a flexible set of preference values
    select preference__get('dateformat'),
           preference__get('numberformat'),
           preference__get('language'),
           preference__get('stylesheet'),
           preference__get('printer')
       into v_row;

    return v_row;
END;
$$ language plpgsql;

COMMENT ON function user__get_preferences (in_user_id int) IS
$$ Returns the preferences row for the user.$$;

DROP TYPE if exists user_result CASCADE;
CREATE TYPE user_result AS (
        id int,
        username text,
        first_name text,
        last_name text,
        ssn text,
        dob date
);


CREATE OR REPLACE FUNCTION  admin__search_users(in_username text, in_first_name text, in_last_name text, in_ssn text, in_dob date) RETURNS SETOF user_result AS
$$
                SELECT u.id, u.username, p.first_name, p.last_name, e.ssn, e.dob
                FROM users u
                JOIN person p ON (u.entity_id = p.entity_id)
                JOIN entity_employee e ON (e.entity_id = p.entity_id)
                WHERE u.username LIKE '%' || coalesce(in_username,'') || '%' AND
                        (p.first_name = in_first_name or in_first_name is null)
                        AND (p.last_name = in_last_name or in_last_name is null)
                        AND (in_ssn is NULL or in_ssn = e.ssn)
                        AND (e.dob = in_dob::date or in_dob is NULL)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION  admin__search_users(in_username text, in_first_name text, in_last_name text, in_ssn text, in_dob date) IS
$$ Returns a list of users matching search criteria.  Nulls match all values.
only username is not an exact match.$$;

DROP TYPE if exists session_result CASCADE;
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

-- TOTP Management Functions

CREATE OR REPLACE FUNCTION admin__totp_enable_user(in_username TEXT, in_secret TEXT)
RETURNS bool AS
$$
BEGIN
    UPDATE users 
    SET totp_secret = in_secret,
        totp_enabled = TRUE,
        totp_failures = 0,
        totp_locked_until = NULL
    WHERE username = in_username;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION admin__totp_enable_user(TEXT, TEXT) IS
$$ Enables TOTP authentication for a user with the provided Base32-encoded secret.$$;

REVOKE EXECUTE ON FUNCTION admin__totp_enable_user(TEXT, TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION admin__totp_disable_user(in_username TEXT)
RETURNS bool AS
$$
BEGIN
    UPDATE users 
    SET totp_secret = NULL,
        totp_enabled = FALSE,
        totp_failures = 0,
        totp_locked_until = NULL,
        totp_last_used = NULL
    WHERE username = in_username;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION admin__totp_disable_user(TEXT) IS
$$ Disables TOTP authentication for a user and clears all TOTP data.$$;

REVOKE EXECUTE ON FUNCTION admin__totp_disable_user(TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION admin__totp_reset_failures(in_username TEXT)
RETURNS bool AS
$$
BEGIN
    UPDATE users 
    SET totp_failures = 0,
        totp_locked_until = NULL
    WHERE username = in_username;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION admin__totp_reset_failures(TEXT) IS
$$ Resets TOTP failure count and unlocks the user if locked.$$;

REVOKE EXECUTE ON FUNCTION admin__totp_reset_failures(TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION user__totp_verify_and_update(
    in_username TEXT,
    in_success BOOL,
    in_max_failures INT DEFAULT 5,
    in_lockout_duration INTERVAL DEFAULT '15 minutes'::interval
)
RETURNS TABLE(is_locked BOOL, failures INT) AS
$$
DECLARE
    v_failures INT;
    v_locked_until TIMESTAMP;
BEGIN
    -- Check if user is currently locked
    SELECT totp_locked_until INTO v_locked_until
    FROM users
    WHERE username = in_username;
    
    IF v_locked_until IS NOT NULL AND v_locked_until > CURRENT_TIMESTAMP THEN
        -- User is still locked
        SELECT totp_failures INTO v_failures FROM users WHERE username = in_username;
        RETURN QUERY SELECT TRUE, v_failures;
        RETURN;
    END IF;
    
    IF in_success THEN
        -- Successful verification - reset failures and update last used
        UPDATE users 
        SET totp_failures = 0,
            totp_locked_until = NULL,
            totp_last_used = CURRENT_TIMESTAMP
        WHERE username = in_username;
        
        RETURN QUERY SELECT FALSE, 0;
    ELSE
        -- Failed verification - increment failures
        UPDATE users 
        SET totp_failures = totp_failures + 1,
            totp_locked_until = CASE 
                WHEN totp_failures + 1 >= in_max_failures 
                THEN CURRENT_TIMESTAMP + in_lockout_duration
                ELSE NULL
            END
        WHERE username = in_username
        RETURNING totp_failures, (totp_locked_until IS NOT NULL)
        INTO v_failures, is_locked;
        
        RETURN QUERY SELECT is_locked, v_failures;
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION user__totp_verify_and_update(TEXT, BOOL, INT, INTERVAL) IS
$$ Updates TOTP verification state after an attempt. 
   Returns whether the user is locked and the current failure count.$$;

CREATE OR REPLACE FUNCTION user__get_totp_info(in_username TEXT)
RETURNS TABLE(
    totp_enabled BOOL,
    totp_secret TEXT,
    totp_locked_until TIMESTAMP,
    totp_failures INT
) AS
$$
    SELECT u.totp_enabled, u.totp_secret, u.totp_locked_until, u.totp_failures
    FROM users u
    WHERE u.username = in_username;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION user__get_totp_info(TEXT) IS
$$ Retrieves TOTP configuration information for a user.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
