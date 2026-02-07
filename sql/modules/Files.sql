
set client_min_messages = 'warning';


BEGIN;

DROP FUNCTION IF EXISTS file__get_mime_type(int, text);

CREATE OR REPLACE FUNCTION file__get_mime_type
 (in_mime_type_id int, in_mime_type_text text)
RETURNS mime_type AS
$$
DECLARE
   r mime_type;
BEGIN
  select * into r from mime_type
   where ($1 IS NULL OR id = $1) AND ($2 IS NULL OR mime_type = $2);

  if not found and in_mime_type_id is null and in_mime_type_text is not null then
    insert into mime_type (mime_type_text) values (in_mime_type_text)
    returning * into r;
  end if;

  return r;
END;
$$ language plpgsql;

COMMENT ON FUNCTION file__get_mime_type(in_mime_type_id int, in_mime_type text) IS
$$Retrieves mime type reference data or creates it.

Note that the reference data isn''t created when in_mime_type_id is
not null or that in_mime_type_text is null.
$$;

CREATE OR REPLACE FUNCTION file__attach_to_tx
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Can't specify id and content in attachment$e$;--'
       END IF;
       INSERT INTO file_order_to_tx
              (file_id, source_class, ref_key, dest_class, attached_by,
              attached_at)
       VALUES (in_id, 2, in_ref_key, 1, person__get_my_entity_id(), now());

       SELECT * INTO retval FROM file_base where id = in_id;
       RETURN retval;
   ELSE
       INSERT INTO file_transaction
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description,
                   in_ref_key, in_file_class, person__get_my_entity_id(),
                   now());
        SELECT * INTO retval FROM file_base
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION file__attach_to_tx
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int) IS
$$ Attaches or links a file to a transaction.  in_content OR id can be set.
Setting both raises an exception.$$;


CREATE OR REPLACE FUNCTION file__attach_to_part
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Can't specify id and content in attachment$e$;--'
       END IF;
       RAISE EXCEPTION 'links not implemented';
       RETURN retval;
   ELSE
       INSERT INTO file_part
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description,
                   in_ref_key, in_file_class, person__get_my_entity_id(),
                   now());
        SELECT * INTO retval FROM file_base
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION file__attach_to_part
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int) IS
$$ Attaches or links a file to a good or service.  in_content OR id can be set.
Setting both raises an exception.

Note that currently links (setting id) is NOT supported because we dont have a
use case of linking files to parts$$;

CREATE OR REPLACE FUNCTION file__attach_to_email
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Can't specify id and content in attachment$e$;--'
       END IF;
       RAISE EXCEPTION 'links not implemented';
       RETURN retval;
   ELSE
       INSERT INTO file_email
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description,
                   in_ref_key, in_file_class, person__get_my_entity_id(),
                   now());
        SELECT * INTO retval FROM file_base
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION file__attach_to_email
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int) IS
$$ Attaches or links a file to an e-mail.  in_content OR id can be set.
Setting both raises an exception.

Note that currently links (setting id) is NOT supported because we dont have a
use case of linking files to e-mails$$;


CREATE OR REPLACE FUNCTION file__attach_to_entity
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Can't specify id and content in attachment$e$;--'
       END IF;
       RAISE EXCEPTION 'links not implemented';
       RETURN retval;
   ELSE
       INSERT INTO file_entity
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description,
                   in_ref_key, in_file_class, person__get_my_entity_id(),
                   now());
        SELECT * INTO retval FROM file_base
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION file__attach_to_entity
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int) IS
$$ Attaches or links a file to a contact or entity.  in_content OR id can be
set. Setting both raises an exception.

Note that currently links (setting id) is NOT supported because we dont have a
use case of linking files to entities$$;

CREATE OR REPLACE FUNCTION file__attach_to_eca
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Can't specify id and content in attachment$e$;--'
       END IF;
       RAISE EXCEPTION 'links not implemented';
       RETURN retval;
   ELSE
       INSERT INTO file_eca
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description,
                   in_ref_key, in_file_class, person__get_my_entity_id(),
                   now());
        SELECT * INTO retval FROM file_base
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION file__attach_to_eca
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int) IS
$$ Attaches or links a file to a good or service.  in_content OR id can be set.
Setting both raises an exception.

Note that currently links (setting id) is NOT supported because we dont have a
use case of linking files to entity credit accounts.$$;

CREATE OR REPLACE FUNCTION file__attach_to_order
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Conflicting options file_id and content$e$;
       END IF;
       IF in_file_class = 1 THEN
           INSERT INTO file_tx_to_order
                  (file_id, source_class, ref_key, dest_class, attached_by,
                  attached_at)
           VALUES (in_id, 1, in_ref_key, 2, person__get_my_entity_id(), now());
       ELSIF in_file_class = 2 THEN
           INSERT INTO file_order_to_order
                  (file_id, source_class, ref_key, dest_class, attached_by,
                  attached_at)
           VALUES (in_id, 2, in_ref_key, 2, person__get_my_entity_id(), now());
       ELSE
           RAISE EXCEPTION $E$Invalid file class$E$;
       END IF;
       SELECT * INTO retval FROM file_base where id = in_id;
       RETURN retval;
   ELSE
       INSERT INTO file_order
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description,
                   in_ref_key, in_file_class, person__get_my_entity_id(),
                   now());
        SELECT * INTO retval FROM file_base
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION file__save_incoming
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text)
RETURNS file_base LANGUAGE SQL AS
$$
INSERT INTO file_incoming(content, mime_type_id, file_name, description,
                          ref_key, file_class, uploaded_by)
SELECT $1, $2, $3, $4, 0, 7, entity_id
  FROM users where username = SESSION_USER
 RETURNING *;
$$;

COMMENT ON FUNCTION file__save_incoming
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text) IS
$$If the file_name is not unique, a unique constraint violation will be thrown.
$$;

CREATE OR REPLACE FUNCTION file__save_internal
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text)
RETURNS file_base LANGUAGE SQL AS
$$
WITH up AS (
    UPDATE file_internal
       SET content = $1, uploaded_at = now(),
           uploaded_by = (select entity_id from users
                           where username = session_user)
     WHERE file_name = $3
 RETURNING true as found_it
)
INSERT INTO file_internal (content, mime_type_id, file_name, description,
                          ref_key, file_class, uploaded_by)
SELECT $1, $2, $3, $4, 0, 6, entity_id
  FROM users
 where username = SESSION_USER
       AND NOT EXISTS (select 1 from up)
RETURNING *;
$$;

COMMENT ON FUNCTION file__save_internal
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text) IS
$$If the file_name is not unique, this will overwrite the previous stored file.
$$;

COMMENT ON FUNCTION file__attach_to_order
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int) IS
$$ Attaches or links a file to an order.  in_content OR id can be set.
Setting both raises an exception.$$;

CREATE OR REPLACE FUNCTION file__attach_to_reconciliation
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Can't specify id and content in attachment$e$;--'
       END IF;
       RAISE EXCEPTION 'links not implemented';
       RETURN retval;
   ELSE
       INSERT INTO file_reconciliation
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description,
                   in_ref_key, in_file_class, person__get_my_entity_id(),
                   now());
        SELECT * INTO retval FROM file_base
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION file__attach_to_reconciliation
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int) IS
$$ Attaches or links a file to an e-mail.  in_content OR id can be set.
Setting both raises an exception.

Note that currently links (setting id) is NOT supported because we dont have a
use case of linking files to e-mails$$;


DROP TYPE IF EXISTS file_list_item CASCADE;
CREATE TYPE file_list_item AS (
       mime_type text,
       file_name text,
       description text,
       uploaded_by_id int,
       uploaded_by_name text,
       uploaded_at timestamp,
       id int,
       ref_key int,
       file_class int,
       content bytea
);

CREATE OR REPLACE FUNCTION file__get_for_template
(in_ref_key int, in_file_class int)
RETURNS SETOF file_list_item AS
$$

SELECT m.mime_type, CASE WHEN f.file_class = 3 THEN ref_key ||'-'|| f.file_name
                         ELSE f.file_name END,
       f.description, f.uploaded_by, e.name,
       f.uploaded_at, f.id, f.ref_key, f.file_class,  f.content
  FROM mime_type m
  JOIN file_base f ON f.mime_type_id = m.id
  JOIN entity e ON f.uploaded_by = e.id
 WHERE f.ref_key = $1 and f.file_class = $2
       AND m.invoice_include
       OR f.id IN (SELECT max(fb.id)
                   FROM file_base fb
                   JOIN mime_type m ON fb.mime_type_id = m.id
                        AND m.mime_type ilike 'image%'
                   JOIN invoice i ON i.trans_id = $1
                        AND i.parts_id = fb.ref_key
                  WHERE fb.file_class = 3
               GROUP BY ref_key)
$$ language sql;


CREATE OR REPLACE FUNCTION file__list_by(in_ref_key int, in_file_class int)
RETURNS SETOF file_list_item AS
$$

SELECT m.mime_type, f.file_name, f.description, f.uploaded_by, e.name,
       f.uploaded_at, f.id, f.ref_key, f.file_class,
       case when m.mime_type = 'text/x-uri' THEN f.content ELSE NULL END
  FROM mime_type m
  JOIN file_base f ON f.mime_type_id = m.id
  JOIN entity e ON f.uploaded_by = e.id
 WHERE f.ref_key = $1 and f.file_class = $2;

$$ language sql;

COMMENT ON FUNCTION file__list_by(in_ref_key int, in_file_class int) IS
$$ Returns a list of files attached to a database object.  No content is
retrieved.$$;


CREATE OR REPLACE FUNCTION file__delete(in_id int, in_file_class int)
RETURNS void AS
$$
DELETE FROM file_base where id = in_id and file_class = in_file_class;
$$ language sql;

COMMENT ON FUNCTION file__delete(in_id int, in_file_class int) IS
$$ Deletes the file identified by in_id and in_file_class.$$;

CREATE OR REPLACE FUNCTION file__get(in_id int, in_file_class int)
RETURNS file_base AS
$$
SELECT * FROM file_base where id = $1 and file_class = $2;
$$ language sql;

COMMENT ON FUNCTION file__get(in_id int, in_file_class int) IS
$$ Retrieves the file information specified including content.$$;

CREATE OR REPLACE FUNCTION file__get_by_name(in_file_name text, in_ref_key int,
in_file_class int)
RETURNS file_base AS
$$
SELECT * FROM file_base where file_name = in_file_name
                              and ref_key = in_ref_key
                              and file_class = in_file_class;
$$ language sql;

COMMENT ON FUNCTION file__get_by_name(in_file_name text, in_ref_key int, in_file_class int) IS
$$ Retrieves the file information specified including content.$$;


DELETE FROM file_view_catalog WHERE file_class in (1, 2);

CREATE OR REPLACE view file_order_links AS
SELECT file_id, ref_key, oe.ordnumber as reference, oc.oe_class, dest_class,
       source_class, sl.ref_key as dest_ref
  FROM file_secondary_attachment sl
  JOIN oe ON sl.ref_key = oe.id
  JOIN oe_class oc ON oe.oe_class_id = oc.id
 WHERE sl.source_class = 2;


-- view of links FROM orders

INSERT INTO file_view_catalog (file_class, view_name)
     VALUES (2, 'file_order_links');


CREATE OR REPLACE FUNCTION file_links_vrebuild()
RETURNS bool AS
$$
DECLARE
   viewline file_view_catalog%rowtype;
   stmt text;
BEGIN
   stmt := '';
   FOR viewline IN
       select * from file_view_catalog
   LOOP
       IF stmt = '' THEN
           stmt := 'SELECT * FROM ' || quote_ident(viewline.view_name) || '
';
       ELSE
           stmt := stmt || ' UNION
SELECT * FROM '|| quote_ident(viewline.view_name) || '
';
       END IF;
   END LOOP;
   EXECUTE 'CREATE OR REPLACE VIEW file_links AS
' || stmt;
   RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;

select * from file_links_vrebuild();


CREATE OR REPLACE FUNCTION file__list_links(in_ref_key int, in_file_class int)
RETURNS setof file_links AS
$$ select * from file_links where ref_key = $1 and dest_class = $2;
$$ language sql;

COMMENT ON FUNCTION file__list_links(in_ref_key int, in_file_class int) IS
$$ This function retrieves a list of file attachments on a specified object.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
