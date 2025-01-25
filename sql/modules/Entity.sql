
set client_min_messages = 'warning';


--

-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

BEGIN;


CREATE OR REPLACE FUNCTION entity__is_used(in_id int)
  RETURNS boolean AS
  $$
BEGIN
  BEGIN
    delete from entity where id = in_id;
    raise sqlstate 'P0004';
  EXCEPTION
    WHEN foreign_key_violation THEN
      return true;
    WHEN assert_failure THEN
      return false;
  END;
END;
$$ language plpgsql;

COMMENT ON FUNCTION entity__is_used(in_id int) IS
  $$Checks whether the entity is used or not.

In case the entity isn't used, it should be possible to delete it.
$$; --'


CREATE OR REPLACE FUNCTION entity_save(
    in_entity_id int, in_name text, in_entity_class INT
) RETURNS INT AS $$

    DECLARE
        e entity;
        e_id int;

    BEGIN

        select * into e from entity where id = in_entity_id;

        update
            entity
        SET
            name = in_name,
            entity_class = in_entity_class
        WHERE
            id = in_entity_id;
        IF NOT FOUND THEN
            -- do the insert magic.
            e_id = nextval('entity_id_seq');
            insert into entity (id, name, entity_class) values
                (e_id,
                in_name,
                in_entity_class
                );
            return e_id;
        END IF;
        return in_entity_id;

    END;

$$ language 'plpgsql';

COMMENT ON FUNCTION entity_save(
    in_entity_id int, in_name text, in_entity_class INT
)  IS
$$ Currently unused.  Left in because it is believed it may be helpful.

This saves an entity, with the control code being the next available via the
defaults table.$$;

CREATE OR REPLACE FUNCTION entity__list_classes ()
RETURNS SETOF entity_class AS $$
DECLARE out_row entity_class;
BEGIN
        FOR out_row IN
                SELECT * FROM entity_class
                WHERE active and pg_has_role(SESSION_USER,
                                   lsmb__role_prefix()
                                   || 'contact_class_'
                                   || lower(regexp_replace(class, '( |\-)', '_')),
                                   'USAGE')
                ORDER BY id
        LOOP
                RETURN NEXT out_row;
        END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION entity__list_classes () IS
$$ Returns a list of entity classes, ordered by assigned ids$$;

CREATE OR REPLACE FUNCTION entity__get (
    in_entity_id int
) RETURNS setof entity AS $$
    SELECT * FROM entity WHERE id = in_entity_id;
$$ language sql;

COMMENT ON FUNCTION entity__get (
    in_entity_id int
) IS
$$ Returns a set of (only one) entity record with the entity id.$$;


CREATE OR REPLACE FUNCTION entity__delete(in_id int)
  RETURNS boolean
  security definer
AS $$
BEGIN
  delete from entity where id = in_id;
  return found;
END;
$$ language plpgsql;

REVOKE EXECUTE ON FUNCTION entity__delete(in_id int) FROM public;


COMMENT ON FUNCTION entity__delete(in_id int) IS
  $$Removes an entity and its master data.

  Removal will fail if the function 'entity__is_used()' returns 'true'.
  $$;

CREATE OR REPLACE FUNCTION eca__get_entity (
    in_credit_id int
) RETURNS setof entity AS $$

    SELECT entity.*
      FROM entity_credit_account
      JOIN entity ON entity_credit_account.entity_id = entity.id
     WHERE entity_credit_account.id = in_credit_id;

$$ language sql;

COMMENT ON FUNCTION eca__get_entity (
    in_credit_id int
)  IS
$$ Returns a set of (only one) entity to which the entity credit account is
attached.$$;

CREATE OR REPLACE FUNCTION entity__get_bank_account(in_id int)
RETURNS entity_bank_account
LANGUAGE SQL AS $$
SELECT * FROM  entity_bank_account WHERE id = $1;
$$;

CREATE OR REPLACE FUNCTION entity__delete_bank_account
(in_entity_id int, in_id int)
RETURNS bool AS
$$
BEGIN

UPDATE entity_credit_account SET bank_account = NULL
 WHERE entity_id = in_entity_id AND bank_account = in_id;

DELETE FROM entity_bank_account
 WHERE id = in_id AND entity_id = in_entity_id;

RETURN FOUND;

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION entity__delete_bank_account(in_entity_id int, in_id int) IS
$$ Deletes the bank account identitied by in_id if it is attached to the entity
identified by entity_id.  Returns true if a record is deleted, false if not.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
