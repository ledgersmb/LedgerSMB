BEGIN;

CREATE TABLE mime_type (
       id serial not null unique,
       mime_type text primary key
);

COMMENT ON TABLE mime_type IS
$$ This is a lookup table for storing MIME types.$$;

CREATE TABLE file_class (
       id serial not null unique,
       class text primary key
);

insert into file_class values (1, 'transaction');
insert into file_class values (2, 'order');

COMMENT ON TABLE file_class IS 
$$ File classes are collections of files attached against rows in specific 
tables in the database.  They can be used in the future to implement other form
of file attachment. $$;

CREATE TABLE file_base (
       content bytea NOT NULL,
       mime_type_id int not null references mime_type(id),
       file_name text not null,
       description text,
       uploaded_by int not null default person__get_my_entity_id()
                      references entity(id),
       uploaded_at timestamp not null default now(),
       id serial not null unique,
       ref_key int not null,
       file_class int not null references file_class(id),
       primary key (ref_key, file_name, file_class)
);     
       
COMMENT ON TABLE file_base IS
$$Abstract table, holds no records.  Inheriting table store actual file
attachment data. Can be queried however to retrieve lists of all files. $$;

COMMENT ON COLUMN file_base.ref_key IS
$$This column inheriting tables is used to reference the database row for the
attachment.  Inheriting tables MUST set the foreign key here appropriately.

This can also be used to create classifications of other documents, such as by
source of automatic import (where the file is not yet attached) or
even standard,
long-lived documents.$$;

CREATE TABLE file_transaction (
       check (file_class = 1),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) REFERENCES transactions(id)
) inherits (file_base);

COMMENT ON TABLE file_transaction IS
$$ File attachments primarily attached to AR/AP/GL.$$;

CREATE TABLE file_order (
       check (file_class=2),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references oe(id)
) inherits (file_base);

COMMENT ON TABLE file_transaction IS
$$ File attachments primarily attached to orders and quotatoins.$$;


CREATE TABLE file_secondary_attachment (
       file_id int not null,
       source_class int references file_class(id),
       ref_key int not null,
       dest_class int references file_class(id),
       attached_by int not null references entity(id),
       attached_at timestamp not null default now()
);

COMMENT ON TABLE file_secondary_attachment IS
$$Another abstract table.  This one will use rewrite rules to make inserts safe
because of the difficulty in managing inserts otherwise. Inheriting tables
provide secondary links between the file and other database objects.

Due to the nature of database inheritance and unique constraints
in PostgreSQL, this must be partitioned in a star format.$$;

CREATE TABLE file_tx_to_order (
       foreign key (file_id) references file_transaction(id),
       foreign key (ref_key) references oe(id),
       check (source_class = 1),
       check (dest_class = 2)
) INHERITS (file_secondary_attachment);

CREATE RULE file_sec_insert_tx_oe AS ON INSERT TO file_secondary_attachment
WHERE source_class = 1 and dest_class = 2
DO INSTEAD
INSERT INTO file_tx_to_order(file_id, source_class, ref_key, dest_class,
attached_by, attached_at)
VALUES (new.file_id, 1, new.ref_key, 2,
       coalesce(new.attached_by, person__get_my_entity_id()),
       coalesce(new.attached_at, now()));

COMMENT ON TABLE file_tx_to_order IS
$$ Secondary links from transactions to orders.$$;

CREATE TABLE file_order_to_order (
       foreign key (file_id) references file_order(id),
       foreign key (ref_key) references oe(id),
       check (source_class = 2),
       check (dest_class = 2)
) INHERITS (file_secondary_attachment);

COMMENT ON TABLE file_order_to_order IS
$$ Secondary links from one order to another, for example to support order
consolidation.$$;

CREATE RULE file_sec_insert_oe_oe AS ON INSERT TO file_secondary_attachment
WHERE source_class = 2 and dest_class = 2
DO INSTEAD
INSERT INTO file_order_to_order(file_id, source_class, ref_key, dest_class,
attached_by, attached_at) 
VALUES (new.file_id, 2, new.ref_key, 2, 
       coalesce(new.attached_by, person__get_my_entity_id()),
       coalesce(new.attached_at, now()));

CREATE TABLE file_order_to_tx (
       foreign key (file_id) references file_order(id),
       foreign key (ref_key) references transactions(id),
       check (source_class = 2),
       check (dest_class = 1)
) INHERITS (file_secondary_attachment);

COMMENT ON TABLE file_order_to_tx IS
$$ Secondary links from orders to transactions, for example to track files when
invoices are generated from orders.$$;

CREATE RULE file_sec_insert_oe_tx AS ON INSERT TO file_secondary_attachment
WHERE source_class = 2 and dest_class = 1
DO INSTEAD
INSERT INTO file_order_to_order(file_id, source_class, ref_key, dest_class,
attached_by, attached_at)
VALUES (new.file_id, 2, new.ref_key, 1,
       coalesce(new.attached_by, person__get_my_entity_id()),
       coalesce(new.attached_at, now()));

COMMIT;
