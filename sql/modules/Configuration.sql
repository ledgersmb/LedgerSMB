

set client_min_messages = 'warning';

BEGIN;

CREATE OR REPLACE FUNCTION config_sic__delete(in_code varchar(6))
RETURNS boolean LANGUAGE sql AS $$
   DELETE FROM sic WHERE code = in_code
   RETURNING true;
$$;

COMMENT ON FUNCTION config_sic__delete(varchar(6)) IS
$$ $$;


CREATE OR REPLACE FUNCTION config_sic__save(
       in_code varchar(6), in_sictype char(1), in_description text)
RETURNS sic LANGUAGE sql AS $$
   INSERT INTO sic (code,    sictype,    description)
            VALUES (in_code, in_sictype, in_description)
   ON CONFLICT (code) DO UPDATE
        SET sictype = in_sictype,
            description = in_description
   RETURNING *;
$$;

COMMENT ON FUNCTION config_sic__save(varchar(6), char(1), text) IS
$$ TODO $$;



CREATE OR REPLACE FUNCTION config_gifi__delete(in_code text)
RETURNS boolean LANGUAGE sql AS $$
   DELETE FROM gifi WHERE accno = in_code
   RETURNING true;
$$;

COMMENT ON FUNCTION config_gifi__delete(text) IS
$$ $$;


CREATE OR REPLACE FUNCTION config_gifi__save(
       in_code text, in_description text)
RETURNS gifi LANGUAGE sql AS $$
   INSERT INTO gifi (accno, description)
            VALUES (in_code, in_description)
   ON CONFLICT (accno) DO UPDATE
        SET description = in_description
   RETURNING *;
$$;

COMMENT ON FUNCTION config_gifi__save(text, text) IS
$$ TODO $$;


CREATE OR REPLACE FUNCTION config_currency__delete(in_code text)
RETURNS boolean LANGUAGE sql AS $$
   DELETE FROM currency WHERE curr = in_code
   RETURNING true;
$$;

COMMENT ON FUNCTION config_currency__delete(text) IS
$$ $$;


CREATE OR REPLACE FUNCTION config_currency__save(
       in_code text, in_description text)
RETURNS currency LANGUAGE sql AS $$
   INSERT INTO currency (curr, description)
        VALUES (in_code, in_description)
   ON CONFLICT (curr) DO UPDATE
      SET description = in_description
   RETURNING *;
$$;

COMMENT ON FUNCTION config_currency__save(text, text) IS
$$ TODO $$;



update defaults set value = 'yes' where setting_key = 'module_load_ok';

END;
