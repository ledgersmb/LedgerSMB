

DO  language plpgsql $migrate$
BEGIN

  -- Migrate 'curr' into 'currency'
  INSERT INTO currency (curr, description)
  SELECT DISTINCT u.curr, u.curr
  FROM unnest(string_to_array((SELECT value FROM defaults
                                WHERE setting_key = 'curr'), ':')) AS u(curr);

  -- Change the 'curr' key in the defaults table to indicate the
  -- functional/base currency.
  UPDATE defaults
     SET value = substr(value, 1, 3)
   WHERE setting_key = 'curr';

  -- Make sure all currencies in the exchangerate table can
  -- be migrated: they all need a record in the 'currency' table
  -- in order for the foreign key to be satisfied
  INSERT INTO currency (curr, description)
  SELECT DISTINCT curr, curr
    FROM exchangerate e
   WHERE NOT EXISTS (SELECT 1 FROM currency c WHERE e.curr = c.curr)
         AND curr IS NOT NULL;

  -- Migrate 'exchangerate' content / BUY field
  PERFORM DISTINCT 1 FROM exchangerate WHERE buy IS NOT NULL;
  IF FOUND THEN
    DECLARE
      v_rate_type int;
    BEGIN
      INSERT INTO exchangerate_type (description, builtin)
      VALUES ('Migrated BUY rates', 'f')
      RETURNING id INTO v_rate_type;

      INSERT INTO exchangerate_default
           (rate_type, curr, valid_from, valid_to, rate)
      SELECT v_rate_type, curr, transdate, transdate + '23:59:59'::time, buy
        FROM exchangerate;
    END;
  END IF;

  -- Migrate 'exchangerate' content / SELL field
  PERFORM DISTINCT 1 FROM exchangerate WHERE sell IS NOT NULL;
  IF FOUND THEN
    DECLARE
      v_rate_type int;
    BEGIN
      INSERT INTO exchangerate_type (description, builtin)
      VALUES ('Migrated SELL rates', 'f')
      RETURNING id INTO v_rate_type;

      INSERT INTO exchangerate_default
           (rate_type, curr, valid_from, valid_to, rate)
      SELECT v_rate_type, curr, transdate, transdate + '23:59:59'::time, sell
        FROM exchangerate;
    END;
  END IF;
END;
$migrate$;

