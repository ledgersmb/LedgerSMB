ALTER TABLE partscustomer ALTER COLUMN credit_id drop not null;

ALTER TABLE partscustomer 
ADD foreign key (pricegroup_id) references pricegroup(id);

CREATE TABLE parts_translation () INHERITS (translation);
ALTER TABLE parts_translation ADD foreign key (trans_id) REFERENCES parts(id);
    
CREATE TABLE project_translation () INHERITS (translation);
ALTER TABLE project_translation 
ADD foreign key (trans_id) REFERENCES project(id);
