
-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General 
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

-- Probably want to move this to the Settings module -CT

CREATE OR REPLACE FUNCTION defaults_get_defaultcurrency() 
RETURNS SETOF char(3) AS
$$
DECLARE defaultcurrency defaults.value%TYPE;
      BEGIN   
           SELECT INTO defaultcurrency substr(value,1,3)
           FROM defaults
           WHERE setting_key = 'curr';
           RETURN NEXT defaultcurrency;
      END;
$$ language plpgsql;                                                                  
COMMENT ON FUNCTION defaults_get_defaultcurrency() IS
$$ This function return the default currency asigned by the program. $$;

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
       accept_input = coalesce(in_accept_input, true)
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

