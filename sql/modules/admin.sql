
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
    BEGIN

        -- Issue the grant
        select rolname into a_role from pg_roles where rolname = in_role;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions of a non-existant role.';
        END IF;

        select rolname into a_user from pg_roles where rolname = in_username;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Cannot grant permissions to a non-existant database user.';
        END IF;

        stmt := 'GRANT '|| quote_ident(in_role) ||' to '|| quote_ident(in_username);

        EXECUTE stmt;

	select id into t_userid from users where username = in_username;
	if not FOUND then
	  RAISE EXCEPTION 'Cannot grant permissions to a non-existant application user.';
        end if;

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
            and r.rolname like (lsmb__role_prefix() || '%')
         LOOP

            RETURN NEXT u_role.rolname::text;

        END LOOP;
        RETURN;
    end;

$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__get_roles_for_user(in_entity_id INT) from PUBLIC;

COMMENT ON FUNCTION admin__get_roles_for_user(in_user_id INT) IS
$$ Returns a set of roles that  a user is a part of.$$;

CREATE OR REPLACE FUNCTION admin__get_roles_for_user_by_entity(in_entity_id INT) returns setof text as $$

    declare
        u_role record;
        a_user users;
    begin
        select * into a_user from admin__get_user_by_entity(in_entity_id);

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
            and r.rolname like (lsmb__role_prefix() || '%')
         LOOP

            RETURN NEXT u_role.rolname::text;

        END LOOP;
        RETURN;
    end;

$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION admin__get_roles_for_user_by_entity(in_entity_id INT) from PUBLIC;

COMMENT ON FUNCTION admin__get_roles_for_user_by_entity(in_entity_id INT) IS
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
$$ Alloes a user to change his or her own password.  The password is set to
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
            PERFORM admin__add_user_to_role(
                        a_user.username,
                        lsmb__role_prefix() || 'base_user');
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

                insert into user_preference (id) values (v_user_id);
            END IF;

            IF NOT exists(SELECT * FROM entity_employee WHERE entity_id = in_entity_id) THEN
                INSERT into entity_employee (entity_id) values (in_entity_id);
            END IF;
            -- Finally, issue the create user statement
            PERFORM admin__add_user_to_role(
                        in_username,
                        lsmb__role_prefix() || 'base_user');

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


DROP VIEW if exists role_view CASCADE;
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
        group_name text;
    BEGIN
        group_name := lsmb__role(in_group_name);
        stmt := 'create role '|| quote_ident(group_name);
        execute stmt;
        INSERT INTO lsmb_group (role_name)
             values (group_name);
        return 1;
    END;

$$ language 'plpgsql' SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION  admin__create_group(TEXT) FROM PUBLIC;

CREATE OR REPLACE FUNCTION admin__add_group_to_role
(in_group_name text, in_role_name text)
RETURNS BOOL AS
$$
DECLARE
   t_group_name text;
   t_role_name  text;
BEGIN
   t_group_name := lsmb__role(in_group_name);
   t_role_name := lsmb__role(in_role_name);
   PERFORM * FROM lsmb_group_grants
     WHERE group_name = t_group_name AND
           granted_role = t_role_name;

   IF NOT FOUND THEN
      INSERT INTO lsmb_group_grants(group_name, granted_role)
           VALUES (t_group_name, t_role_name);
   END IF;

   EXECUTE 'GRANT ' || quote_ident(t_role_name) || ' TO ' ||
           quote_literal(t_group_name);
   RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

revoke execute on function admin__add_group_to_role
(in_group_name text, in_role_name text) FROM public;

COMMENT ON function admin__add_group_to_role
(in_group_name text, in_role_name text) IS
$$ This function inserts the arguments into lsmb_group_grants for future
reference and issues the db-level grant.  It then returns true if there are no
exceptions.$$;

CREATE OR REPLACE FUNCTION admin__remove_group_from_role
(in_group_name text, in_role_name text) RETURNS BOOL AS $$
BEGIN

   EXECUTE 'REVOKE ' || quote_ident(in_role_name) || ' FROM ' ||
           quote_literal('lsmb_' || t_dbname || '__' || in_group_name);

   DELETE FROM lsmb_group_grants
    WHERE group_name = in_group_name AND granted_role = in_role_name;

   RETURN FOUND;

END;

$$ LANGUAGE PLPGSQL SECURITY DEFINER;

revoke execute on function admin__remove_group_from_role
(in_group_name text, in_role_name text) FROM public;

COMMENT ON  FUNCTION admin__remove_group_from_role
(in_group_name text, in_role_name text) IS $$
Returns true if the grant record was found and deleted, false otherwise.
Issues db-level revoke in all cases.$$;

CREATE OR REPLACE FUNCTION admin__list_group_grants(in_group_name text)
RETURNS SETOF lsmb_group_grants AS $$
SELECT * FROM lsmb_group_grants WHERE group_name = $1
ORDER BY granted_role;
$$ LANGUAGE SQL;

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

-- Work in progress, not for ducmenting yet.
CREATE OR REPLACE FUNCTION admin__delete_group (in_group_name TEXT) returns bool as $$

    DECLARE
        stmt text;
        a_role role_view;
        group_name text;
    BEGIN
        select * into a_role from role_view where rolname = in_group_name;

        if not found then
            return 'f'::bool;
        else
            group_name := lsmb__role(in_group_name);
            stmt := 'drop role lsmb_' || quote_ident(group_name);
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
        SELECT *
        FROM
            pg_roles
        WHERE
            rolname ~ ('^' || lsmb__role_prefix())
            AND NOT rolcanlogin
        ORDER BY rolname ASC
$$ language sql;

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

DROP FUNCTION IF EXISTS user__get_preferences (in_user_id int);
create or replace function user__get_preferences (in_user_id int) returns user_preference as $$

declare
    v_row user_preference;
BEGIN
    select * into v_row from user_preference where id = in_user_id;

    IF NOT FOUND THEN

        RAISE EXCEPTION 'Could not find user preferences for id %', in_user_id;
    ELSE
        return v_row;
    END IF;
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

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
