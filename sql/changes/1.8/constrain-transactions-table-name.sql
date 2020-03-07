ALTER TABLE transactions
ALTER COLUMN table_name SET NOT NULL,
ADD CONSTRAINT transactions_table_name_check CHECK (
    table_name = ANY (ARRAY['gl', 'ar', 'ap'])
);
