ALTER TABLE tax_extended DROP COLUMN account_id;
ALTER TABLE tax_extended DROP COLUMN tx_id;
ALTER TABLE tax_extended DROP COLUMN reference;
ALTER TABLE tax_extended DROP COLUMN tax_amount;
ALTER TABLE tax_extended ADD entry_id int primary key;
ALTER TABLE tax_extended 
ADD FOREIGN KEY(entry_id) references acc_trans(entry_id);
