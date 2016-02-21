ALTER TABLE journal_entry ALTER COLUMN effective_start drop not null;
ALTER TABLE journal_entry ALTER COLUMN effective_end drop not null;
ALTER TABLE journal_entry ALTER COLUMN post_date drop not null;
ALTER TABLE journal_entry ALTER COLUMN reference drop not null;
ALTER TABLE journal_entry ADD CHECK(is_template or reference is not null);

