
ALTER TABLE transactions
   ADD COLUMN workflow_id int REFERENCES workflow (workflow_id);


