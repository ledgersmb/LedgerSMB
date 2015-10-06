-- Copyright (C) 2013 The LedgerSMB Core Team
--
-- This file may be re-used in accordance with the GNU General Public License
-- Version 2 or at your option any later version.  Please see the attached
-- LICENSE file for details.
--
-- Routines for role/permissions backups and restores per db users and roles
--
-- Note that these must be explicitly activated.  They are not done by default
-- because they pose a security info leakage risk.
--
--
-- The default backup routines do not call these functions
--
-- The API on this level consists of three functions:
--
-- lsmb__backup_roles() backs up roles and passwords
--
-- lsmb__clear_role_backup() Removes the backup of roles and passwords
--
-- lsmb__restore_roles() restores roles.

BEGIN;

CREATE OR REPLACE FUNCTION lsmb__clear_role_backup() RETURNS BOOL
LANGUAGE PLPGSQL AS
$$
BEGIN

DROP TABLE IF EXISTS lsmb_role_grants CASCADE;
DROP TABLE IF EXISTS lsmb_password_backups CASCADE;

RETURN TRUE;

END;

$$;

COMMENT ON FUNCTION lsmb__clear_role_backup() IS
$$

This functon drops the backup tables.  It is also called on the successful
completion of lsmb__restore_roles().
$$;

CREATE OR REPLACE FUNCTION lsmb__backup_roles() RETURNS BOOL LANGUAGE PLPGSQL AS
$$
BEGIN

PERFORM lsmb__clear_role_backup();

CREATE TABLE lsmb_role_grants AS
SELECT u.id, rm.rolname
  FROM users u
  JOIN pg_authid r ON r.rolname = u.username
  JOIN pg_auth_members m ON m.member = r.oid
  JOIN pg_authid rm ON rm.oid = m.roleid;

CREATE TABLE lsmb_password_backups AS
SELECT u.id, rolpassword, rolvaliduntil
  FROM users u
  JOIN pg_authid r ON r.rolname = u.username;

RETURN FOUND;

END;
$$;

COMMENT ON FUNCTION lsmb__backup_roles() IS
$$ This function creates two tables, dropping them if they exist previously:

* lsmb_role_grants
* lsmb_password_backups

These contain sensitive security information and should only be used when
creating customer-ready backups from shared hosting environments.$$;

CREATE OR REPLACE FUNCTION lsmb__restore_roles() RETURNS BOOL LANGUAGE PLPGSQL
AS $$
DECLARE temp_rec RECORD;

BEGIN

FOR temp_rec IN
    select u.username, l.*
      FROM users u
      JOIN lsmb_password_backups l ON u.id = l.id
LOOP
    PERFORM 1 FROM pg_authid WHERE rolname = temp_rec.username;

    IF FOUND THEN
        EXECUTE $e$ ALTER USER $e$ || quote_ident(temp_rec.username) ||
        $e$ WITH ENCRYPTED PASSWORD $e$ || quote_literal(temp_rec.rolpassword) ||
        $e$ VALID UNTIL $e$ || coalesce(quote_literal(temp_rec.rolvaliduntil),
                                         'NULL');
    ELSE
        EXECUTE $e$ CREATE USER $e$ || quote_ident(temp_rec.username) ||
        $e$ WITH ENCRYPTED PASSWORD $e$ || quote_literal(temp_rec.rolpassword) ||
        $e$ VALID UNTIL $e$ || coalesce(quote_literal(temp_rec.rolvaliduntil),
                                         'NULL');
    END IF;
END LOOP;

PERFORM admin__add_user_to_role(u.username, r.rolname)
   FROM users u
   JOIN lsmb_role_grants r ON u.id = r.id
   JOIN pg_authid a ON r.rolname = a.rolname;

RETURN lsmb__clear_role_backup();

END;
$$;

COMMENT ON FUNCTION lsmb__restore_roles() IS
$$
This file restores the roles from lsmb__backup_roles() and then cleares the role
backup.  If the role backup/restore did not work properly one can always
restore the backup tables only from the backup again but this reduces security
disclosure.
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';



COMMIT;
