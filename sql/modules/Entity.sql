
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


DROP TYPE IF EXISTS entity_credit_retrieve CASCADE;

CREATE TYPE entity_credit_retrieve AS (
        id int,
        entity_id int,
        entity_class int,
        discount numeric,
        discount_terms int,
        taxincluded bool,
        creditlimit numeric,
        terms int2,
        meta_number text,
        description text,
        business_id int,
        language_code text,
        pricegroup_id int,
        curr text,
        startdate date,
        enddate date,
        ar_ap_account_id int,
        cash_account_id int,
        discount_account_id int,
        threshold numeric,
        control_code text,
        credit_id int,
        pay_to_name text,
        taxform_id int,
        is_used boolean
);

CREATE OR REPLACE FUNCTION entity__list_credit
(in_entity_id int, in_entity_class int)
RETURNS SETOF entity_credit_retrieve AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT  ec.id, e.id, ec.entity_class, ec.discount,
                        ec.discount_terms,
                        ec.taxincluded, ec.creditlimit, ec.terms,
                        ec.meta_number::text, ec.description, ec.business_id,
                        ec.language_code::text,
                        ec.pricegroup_id, ec.curr::text, ec.startdate,
                        ec.enddate, ec.ar_ap_account_id, ec.cash_account_id,
                        ec.discount_account_id,
                        ec.threshold, e.control_code, ec.id, ec.pay_to_name,
                        ec.taxform_id, eca__is_used(ec.id)
                FROM entity e
                JOIN entity_credit_account ec ON (e.id = ec.entity_id)
                WHERE e.id = $1
                       AND (ec.entity_class = $2
                            or $2 is null)
$sql$
USING in_entity_id, in_entity_class;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION entity__list_credit (in_entity_id int, in_entity_class int)
IS $$ Returns a list of entity credit account entries for the entity and of the
entity class.$$;

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

CREATE OR REPLACE FUNCTION eca__delete(in_id int)
  RETURNS boolean
  security definer
AS $$
BEGIN
  delete from entity_credit_account where id = in_id;
  return found;
END;
$$ language plpgsql;

REVOKE EXECUTE ON FUNCTION eca__delete(in_id int) FROM PUBLIC;

COMMENT ON FUNCTION eca__delete(in_id int) IS
  $$Removes an entity credit account and its master data.

  Removal will fail if the function 'eca__is_used()' returns 'true'.
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
