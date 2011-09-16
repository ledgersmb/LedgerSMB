ALTER TABLE assembly ADD foreign key (id) REFERENCES parts(id);
ALTER TABLE assembly ADD foreign key (parts_id) REFERENCES parts(id);
