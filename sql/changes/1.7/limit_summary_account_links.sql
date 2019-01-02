-- Chart of Account accounts can be tagged as a 'Summary Account' if linked to
-- a summary descriptor via the account_link table. An account can only be linked
-- with a single summary descriptor. This change introduces a trigger constraint
-- to enforce that.

-- This is implemented as a change file, rather than as a module under sql/modules
-- because it represents a change to the schema rather than application logic.

CREATE OR REPLACE FUNCTION limit_summary_account_links()
RETURNS TRIGGER AS
$$
BEGIN
    -- Is the account_link we're assigning a Summary descriptor?
    PERFORM 1
    FROM account_link_description
    WHERE description = NEW.description
    AND summary IS TRUE;

    -- There can only be one Summary descriptor assigned to an account.
    IF FOUND THEN
        IF (
            SELECT COUNT(*) > 1
            FROM account_link
            JOIN account_link_description ON (
                account_link.description = account_link_description.description
            )
            WHERE account_id = NEW.account_id
            AND account_link_description.summary IS TRUE
         )
         THEN
            RAISE EXCEPTION 'Account already has a summary account_link - cannot add another';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION limit_summary_account_links() IS
$$Called as a constraint trigger function on the account_link table. Raises an
exception if the operation would create more than one Summary account_link
descriptors for the relevant account.$$;

DROP TRIGGER IF EXISTS prohibit_multiple_summary_account_links ON account_link;

CREATE CONSTRAINT TRIGGER prohibit_multiple_summary_account_links
AFTER UPDATE OR INSERT ON account_link
FOR EACH ROW EXECUTE PROCEDURE limit_summary_account_links();

COMMENT ON TRIGGER prohibit_multiple_summary_account_links ON account_link IS
$$Accounts can be linked with only one Summary account_link descriptor. This trigger
enforces that constraint.$$;
