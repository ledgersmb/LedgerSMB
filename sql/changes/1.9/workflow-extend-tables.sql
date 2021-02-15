
ALTER TABLE transactions
   ADD COLUMN workflow_id int UNIQUE REFERENCES workflow (workflow_id);

ALTER TABLE oe
   ADD COLUMN workflow_id int REFERENCES workflow (workflow_id);

