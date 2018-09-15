
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

