BEGIN;

CREATE OR REPLACE FUNCTION template__get(
in_template_name text, in_language_code varchar(6), in_format text
) RETURNS template language sql as
$$
SELECT * FROM template
 WHERE template_name = $1 AND format = $3 AND
       language_code IS NOT DISTINCT FROM $2;
$$;

CREATE OR REPLACE FUNCTION template__get_by_id(in_id int)
RETURNS template language sql as
$$
SELECT * FROM template WHERE id = $1;
$$;

CREATE OR REPLACE FUNCTION template__list(in_language_code varchar(6))
RETURNS SETOF template language sql as $$

SELECT * FROM template WHERE language_code IS NOT DISTINCT FROM $1
ORDER BY template_name, format;

$$;

CREATE OR REPLACE FUNCTION template__save(
in_template_name text, in_language_code varchar(6), in_template text,
in_format text
)
RETURNS template LANGUAGE PLPGSQL AS
$$
DECLARE retval template;
BEGIN
   UPDATE template SET template = in_template
    WHERE template_name = in_template_name AND format = in_format AND
          language_code IS NOT DISTINCT FROM in_language_code;

   IF FOUND THEN
      retval := template__get(in_template_name, in_language_code, in_format);
      RETURN retval;
   END IF;
   INSERT INTO template (template_name, language_code, template, format)
   VALUES (in_template_name, in_language_code, in_template, in_format);

   retval := template__get(in_template_name, in_language_code, in_format);
   RETURN retval;
END;
$$;

update defaults set value='yes' where setting_key='module_load_ok';

COMMIT;
