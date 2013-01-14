CREATE TABLE file_view_catalog (
       file_class int references file_class(id) primary key,
       view_name text not null unique
);
