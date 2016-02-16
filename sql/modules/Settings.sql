-- VERSION 1.3.0

-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

BEGIN;

DROP FUNCTION IF EXISTS defaults_get_defaultcurrency();

CREATE OR REPLACE FUNCTION defaults_get_defaultcurrency()
RETURNS char(3) AS
$$
           SELECT substr(value,1,3)
           FROM defaults
           WHERE setting_key = 'curr';
$$ language sql;

COMMENT ON FUNCTION defaults_get_defaultcurrency() IS
$$ This function return the default currency asigned by the program. $$;

DROP FUNCTION IF EXISTS setting__set(varchar, varchar);
CREATE OR REPLACE FUNCTION setting__set (in_setting_key varchar, in_value varchar)
RETURNS BOOL AS
$$
BEGIN
	UPDATE defaults SET value = in_value WHERE setting_key = in_setting_key;
        IF NOT FOUND THEN
             INSERT INTO defaults (setting_key, value)
                  VALUES (in_setting_key, in_value);
        END IF;
	RETURN TRUE;
END;
$$ language plpgsql;

COMMENT ON FUNCTION setting__set (in_setting_key varchar, in_value varchar) IS
$$ sets a value in the defaults thable and returns true if successful.$$;

CREATE OR REPLACE FUNCTION setting_get (in_key varchar) RETURNS defaults AS
$$
SELECT * FROM defaults WHERE setting_key = $1;
$$ LANGUAGE sql;

COMMENT ON FUNCTION setting_get (in_key varchar) IS
$$ Returns the value of the setting in the defaults table.$$;

CREATE OR REPLACE FUNCTION setting_get_default_accounts ()
RETURNS SETOF defaults AS
$$
		SELECT * FROM defaults
		WHERE setting_key like '%accno_id'
                ORDER BY setting_key
$$ LANGUAGE sql;

COMMENT ON FUNCTION setting_get_default_accounts () IS
$$ Returns a set of settings for default accounts.$$;

CREATE OR REPLACE FUNCTION setting__increment_base(in_raw_var text)
returns varchar language plpgsql as $$
declare raw_value VARCHAR;
       base_value VARCHAR;
       increment  INTEGER;
       inc_length INTEGER;
       new_value VARCHAR;
begin
    raw_value := in_raw_var;
    base_value := substring(raw_value from
                                '(' || E'\\' || 'd*)(' || E'\\' || 'D*|<'
                                    || E'\\' || '?lsmb [^<>] ' || E'\\'
                                    || '?>)*$');
    IF base_value like '0%' THEN
         increment := base_value::integer + 1;
         inc_length := char_length(increment::text);
         new_value := overlay(base_value placing increment::varchar
                              from (char_length(base_value)
                                    - inc_length + 1)
                              for inc_length);
    ELSE
         new_value := base_value::integer + 1;
    END IF;
    return regexp_replace(raw_value, base_value, new_value);
end;
$$;

CREATE OR REPLACE FUNCTION setting_increment (in_key varchar) returns varchar
AS
$$
	UPDATE defaults SET value = setting__increment_base(value) 
        WHERE setting_key = in_key
        RETURNING value;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION setting_increment (in_key varchar) IS
$$This function takes a value for a sequence in the defaults table and increments
it.  Leading zeroes and spaces are preserved as placeholders.  Currently <?lsmb
parsing is not supported in this routine though it may be added at a later date.
$$;

CREATE OR REPLACE FUNCTION setting__get_currencies() RETURNS text[]
AS
$$
SELECT string_to_array(value, ':') from defaults where setting_key = 'curr';
$$ LANGUAGE SQL;
-- Table schema defaults

COMMENT ON FUNCTION setting__get_currencies() is
$$ Returns an array of currencies from the defaults table.$$;

ALTER TABLE entity ALTER control_code SET default setting_increment('entity_control');


CREATE OR REPLACE FUNCTION lsmb__role_prefix() RETURNS text
LANGUAGE SQL AS
$$ select coalesce((setting_get('role_prefix')).value,
                   'lsmb_' || current_database() || '__'); $$;

COMMENT ON FUNCTION lsmb__role_prefix() IS
$$ Returns the prefix text to be used for roles. E.g.  'lsmb__mycompany_' $$;


CREATE OR REPLACE FUNCTION lsmb__role(global_role text) RETURNS text
LANGUAGE SQL AS
$$ select lsmb__role_prefix() || $1; $$;

COMMENT ON FUNCTION lsmb__role(global_role text) IS
$$ Prepends the role prefix to a role name.

E.g. 'contact_edit' is converted to 'lsmb_mycompany__contact_edit'
$$;

CREATE OR REPLACE FUNCTION sequence__list() RETURNS SETOF lsmb_sequence
LANGUAGE SQL AS
$$
SELECT * FROM lsmb_sequence order by label;
$$;

CREATE OR REPLACE FUNCTION sequence__get(in_label text) RETURNS LSMB_SEQUENCE
LANGUAGE SQL AS
$$
SELECT * FROM lsmb_sequence WHERE label = $1;
$$;

CREATE OR REPLACE FUNCTION sequence__list_by_key(in_setting_key text)
RETURNS SETOF lsmb_sequence LANGUAGE SQL AS
$$
SELECT * FROM lsmb_sequence where setting_key = $1 order by label;
$$;

CREATE OR REPLACE FUNCTION sequence__save
(in_label text, in_setting_key text, in_prefix text, in_suffix text,
 in_sequence text, in_accept_input bool)
RETURNS lsmb_sequence LANGUAGE plpgsql AS
$$
DECLARE retval lsmb_sequence;
BEGIN
UPDATE lsmb_sequence
   SET prefix = coalesce(in_prefix, ''),
       suffix = coalesce(in_suffix, ''),
       sequence = coalesce(in_sequence, '1'),
       setting_key = in_setting_key,
       accept_input = coalesce(in_accept_input, false)
 WHERE label = in_label;

IF FOUND THEN
   retval := sequence__get(in_label);
   RETURN retval;
END IF;

INSERT INTO lsmb_sequence(label, setting_key, prefix, suffix, sequence,
                          accept_input)
VALUES (in_label, in_setting_key,
        coalesce(in_prefix, ''),
        coalesce(in_suffix, ''),
        coalesce(in_sequence, '1'),
        coalesce(in_accept_input, false)
);

retval := sequence__get(in_label);
RETURN retval;

end;
$$;

CREATE OR REPLACE FUNCTION sequence__increment(in_label text)
RETURNS defaults LANGUAGE PLPGSQL AS
$$
DECLARE t_seq lsmb_sequence;
        new_value text;
        retval    defaults;
BEGIN

   SELECT * INTO t_seq FROM lsmb_sequence WHERE label = in_label
          FOR UPDATE;

   new_value := setting__increment_base(t_seq.sequence);

   UPDATE lsmb_sequence SET sequence = new_value WHERE label = in_label;

   retval := row(t_seq.setting_key, t_seq.prefix || new_value || t_seq.suffix);
   return retval;

END;
$$;

CREATE OR REPLACE FUNCTION sequence__delete(in_label text)
RETURNS lsmb_sequence LANGUAGE SQL AS
$$
DELETE FROM lsmb_sequence where label = $1;

SELECT NULL::lsmb_sequence;
$$;

CREATE OR REPLACE FUNCTION defaults__get_contra_accounts(in_category char(1))
RETURNS SETOF account LANGUAGE SQL AS
$$
SELECT * FROM account WHERE contra AND category = $1;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
