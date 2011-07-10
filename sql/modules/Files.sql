create or replace function file__attach_to_tx,
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, in_ref_key int, in_file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Can't specify id and content in attachment$$;--'
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
            VALUES (in_content, in_mime_type_id, in_file_name, in_description.
                   in_ref_key, in_file_class, person__get_my_entity_id(), 
                   now());
        SELECT * INTO retval FROM file_base 
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

create or replace function file__attach_to_order
(in_content bytea, in_mime_type_id int, in_file_name text,
in_description text, in_id int, ref_key int, file_class int)
RETURNS file_base
AS
$$
DECLARE retval file_base;
BEGIN
   IF in_id IS NOT NULL THEN
       IF in_content THEN
          RAISE EXCEPTION $e$Conflicting options file_id and content$e$;
       END IF;
       IF file_class = 1 THEN
           INSERT INTO file_tx_to_order        
                  (file_id, source_class, ref_key, dest_class, attached_by,
                  attached_at)
           VALUES (in_id, 1, in_ref_key, 2, person__get_my_entity_id(), now());
       ELSIF file_class = 2 THEN
           INSERT INTO file_order_to_order
                  (file_id, source_class, ref_key, dest_class, attached_by,
                  attached_at)
           VALUES (in_id, 2, in_ref_key, 2, person__get_my_entity_id(), now());
       ELSE 
           RAISE EXCEPTION $E$Invalid file class$e$;
       END IF;
       SELECT * INTO retval FROM file_base where id = in_id;
       RETURN retval;
   ELSE
       INSERT INTO file_transaction 
                   (content, mime_type_id, file_name, description, ref_key,
                   file_class, uploaded_by, uploaded_at)
            VALUES (in_content, in_mime_type_id, in_file_name, in_description.
                   in_ref_key, in_file_class, person__get_my_entity_id(), 
                   now());
        SELECT * INTO retval FROM file_base 
         where id = currval('file_base_id_seq');

        RETURN retval;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE file_list_item AS
       mime_type text,
       file_name text,
       description text,
       uploaded_by_id int,
       uploaded_by_name text,
       uploaded_at timestamp,
       id int,
       ref_key int,
       file_class int
);
create or replace function file__list_by(in_ref_key int, in_file_class int)
RETURNS SETOF file_base AS
$$

SELECT m.mime_type, f.file_name, f.description, f.uploaded_by, e.name, 
       f.uploaded_at, f.id, f.ref_key, f.file_class
  FROM mime_type m
  JOIN file_base f ON f.mime_type_id = m.id
  JOIN entity e ON f.uploaded_by = e.id
 WHERE f.ref_key = $1 and f.file_class = $2;

$$ language sql;

create or replace function file__get(in_id int, in_file_class int)
RETURNS file_base AS
$$
SELECT * FROM file_base where id = $1 and file_class = $2;
$$ language sql;


DROP VIEW IF EXISTS file_links;
DROP VIEW IF EXISTS file_tx_links;
DROP VIEW IF EXISTS file_order_links;
DELETE FROM file_view_catalog WHERE file_class in (1, 2);

CREATE OR REPLACE view file_tx_links
-- view of links FROM transactions

CREATE OR REPLACE view file_order_links
-- view of links FROM orders

CREATE OR REPLACE VIEW file_links
AS
select * from  file_tx_links
UNION
select * from file_order_links;
