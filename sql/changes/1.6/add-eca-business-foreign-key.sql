-- entity_credit_account.business_id should have a foreign key constraint
ALTER TABLE entity_credit_account
ADD FOREIGN KEY (business_id) REFERENCES business(id);
