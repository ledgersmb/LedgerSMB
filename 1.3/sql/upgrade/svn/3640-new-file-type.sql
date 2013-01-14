insert into file_class values (3, 'part');

CREATE TABLE file_part (
       check (file_class=3),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references parts(id)
) inherits (file_base);

COMMENT ON TABLE file_part IS
$$ File attachments primarily attached to orders and quotations.$$;

