BEGIN;

CREATE OR REPLACE FUNCTION template__get(
in_template_name text, in_language_code varchar(6)
) RETURNS template language sql as
$$
SELECT * FROM template 
 WHERE template_name = $1 AND language_code IS NOT DISTINCT FROM $2;
$$;

CREATE OR REPLACE FUNCTION template__get_by_id(in_id int)
RETURNS template language sql as
$$
SELECT * FROM template WHERE id = $1;
$$;

CREATE OR REPLACE FUNCTION template__save(
in_template_name text, in_language_code varchar(6), in_template text
) 
RETURNS template LANGUAGE PLPGSQL AS
$$
BEGIN
   UPDATE template SET template = in_template
    WHERE template_name = in_template_name AND
          language_code IS NOT DISTINCT FROM in_language_code;
          
   IF FOUND THEN
      RETURN template_get(in_template_name, in_language_code);
   END;
   INSERT INTO template (template_name, language_code, template)
   VALUES (in_template_name, language_code, template);

   RETURN template_get(in_template_name, in_language_code);
END;
$$;

COMMIT;
