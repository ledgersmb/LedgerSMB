
UPDATE partsvendor
   SET curr = (select value from defaults where setting_key = 'curr')
 WHERE curr IS NULL;

UPDATE partscustomer
   SET curr = (select value from defaults where setting_key = 'curr')
 WHERE curr IS NULL;

