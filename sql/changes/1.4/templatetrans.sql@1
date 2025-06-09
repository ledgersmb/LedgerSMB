ALTER TABLE journal_entry ALTER COLUMN effective_start drop not null;
ALTER TABLE journal_entry ALTER COLUMN effective_end drop not null;
ALTER TABLE journal_entry ALTER COLUMN post_date drop not null;
ALTER TABLE journal_entry ALTER COLUMN reference drop not null;
ALTER TABLE journal_entry ADD CHECK(is_template or reference is not null);
UPDATE menu_node SET position = position * -1 where parent = 0 and position > 16;
UPDATE menu_node SET position = 1 + (position * -1)
 where parent = 0 and position < 0;

INSERT INTO menu_node(id, parent, position, label) values (28, 0, 17, 'Transaction Templates');
INSERT INTO menu_attribute(id, node_id, attribute, value)
values (254, 28, 'module', 'transtemplate.pl'), (255, 28, 'action', 'list');

DROP INDEX "je_unique_source";
CREATE UNIQUE INDEX "je_unique_source" ON journal_entry(journal, reference) where journal in (1, 2) and not is_template;

