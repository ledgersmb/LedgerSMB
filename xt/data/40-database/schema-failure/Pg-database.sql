

BEGIN;

CREATE TABLE defaults (
   setting_key text primary key,
   value text
);

--note, the spelling error below is intentional

COMMENT ON TABLE defal IS $$Comment on a non-existing table to make sure
the transaction fails$$;

END;
