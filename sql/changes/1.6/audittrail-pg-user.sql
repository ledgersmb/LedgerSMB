
-- Migrations may need to change table content. Currently upgrades/migrations
-- are being run as database admins through setup.pl, for which there's likely
-- no LedgerSMB user.

-- This script removes the requirement for an existing mapping to a LedgerSMB
-- user. Additionally, the change adds logging of the postgresql role
-- responsible for the data modifications.

ALTER TABLE audittrail
      ADD COLUMN rolname text NOT NULL DEFAULT SESSION_USER;

ALTER TABLE audittrail
      ALTER COLUMN person_id DROP NOT NULL;

CREATE OR REPLACE FUNCTION gl_audit_trail_append()
RETURNS TRIGGER AS
$$
DECLARE
   t_reference text;
   t_row RECORD;
BEGIN

IF TG_OP = 'INSERT' then
   t_row := NEW;
ELSE
   t_row := OLD;
END IF;

IF TG_RELNAME IN ('ar', 'ap') THEN
    t_reference := t_row.invnumber;
ELSE
    t_reference := t_row.reference;
END IF;

INSERT INTO audittrail (trans_id,tablename,reference, action, person_id,
                        rolname)
values (t_row.id,TG_RELNAME,t_reference, TG_OP, person__get_my_entity_id(),
        SESSION_USER);

return null; -- AFTER TRIGGER ONLY, SAFE
END;
$$ language plpgsql security definer;


COMMENT ON FUNCTION gl_audit_trail_append() IS
$$ This provides centralized support for insertions into audittrail.
$$;
