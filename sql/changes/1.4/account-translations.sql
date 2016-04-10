
CREATE TABLE account_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE account_translation
ADD foreign key (trans_id) REFERENCES account(id);

COMMENT ON TABLE account_translation IS
$$Translations for account descriptions.$$;

CREATE TABLE account_heading_translation
(PRIMARY KEY (trans_id, language_code)) INHERITS (translation);
ALTER TABLE account_heading_translation
ADD foreign key (trans_id) REFERENCES account_heading(id);

COMMENT ON TABLE account_heading_translation IS
$$Translations for account heading descriptions.$$;

