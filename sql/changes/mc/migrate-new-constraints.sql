
-- In the pricematrix code, NULL currency values get defaulted
-- to the company default currency. Since NULL is no longer
-- allowed as a currency value, set the default that was used
-- anyway.

UPDATE partsvendor
   SET curr = (select value from defaults where setting_key = 'curr')
 WHERE curr IS NULL;

UPDATE partscustomer
   SET curr = (select value from defaults where setting_key = 'curr')
 WHERE curr IS NULL;

INSERT INTO currency (curr, description)
SELECT curr, curr FROM entity_credit_account
 WHERE curr IS NOT NULL
       AND curr NOT IN (select curr from currency);

UPDATE entity_credit_account
   SET curr = (select value from defaults where setting_key = 'curr')
 WHERE curr IS NULL
       AND entity_class in (1, 2, 3); -- Vendor, Customer, Employee
