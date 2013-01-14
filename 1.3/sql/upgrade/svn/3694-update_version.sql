UPDATE defaults SET value = '1.3.0' where setting_key = 'version';

CREATE TABLE partsgroup_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE partsgroup_translation 
ADD foreign key (trans_id) REFERENCES partsgroup(id);

COMMENT ON TABLE partsgroup_translation IS
$$ Translation information for partsgroups.$$;
