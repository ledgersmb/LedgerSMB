

set client_min_messages = 'warning';


BEGIN;

CREATE OR REPLACE FUNCTION track_global_sequence() RETURNS TRIGGER AS
$$
BEGIN
        IF tg_op = 'INSERT' THEN
                INSERT INTO transactions (id, table_name, approved)
                VALUES (new.id, TG_TABLE_NAME, new.approved);
        ELSEIF tg_op = 'UPDATE' THEN
                IF new.id = old.id AND new.approved = old.approved THEN
                        return new;
                ELSE
                        UPDATE transactions SET id = new.id,
                                                approved = new.approved
                         WHERE id = old.id;
                END IF;
        ELSE
                DELETE FROM transactions WHERE id = old.id;
        END IF;
        RETURN new;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION track_global_sequence() is
$$ This trigger is used to track the id sequence entries across the
transactions table, and with the ar, ap, and gl tables.  This is necessary
because these have not been properly refactored yet.
$$;

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

IF TG_TABLE_NAME IN ('ar', 'ap') THEN
    t_reference := t_row.invnumber;
ELSE
    t_reference := t_row.reference;
END IF;

INSERT INTO audittrail (trans_id,tablename,reference, action, person_id)
values (t_row.id,TG_TABLE_NAME,t_reference, TG_OP, person__get_my_entity_id());

return null; -- AFTER TRIGGER ONLY, SAFE
END;
$$ language plpgsql security definer;


COMMENT ON FUNCTION gl_audit_trail_append() IS
$$ This provides centralized support for insertions into audittrail.
$$;


CREATE OR REPLACE FUNCTION prevent_closed_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE t_end_date date;
BEGIN
SELECT max(end_date) into t_end_date FROM account_checkpoint;
IF new.transdate <= t_end_date THEN
    RAISE EXCEPTION 'Transaction entered into closed period.  Transdate: %',
                   new.transdate;
END IF;
RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION trigger_parts_short() RETURNS TRIGGER
AS
'
BEGIN
  IF NEW.onhand >= NEW.rop THEN
    NOTIFY parts_short;
  END IF;
  RETURN NEW;
END;
' LANGUAGE PLPGSQL;



update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
