
UPDATE entity_credit_account
   SET curr = (select s from unnest(string_to_array((select value from defaults where setting_key = 'curr'), ':')) s limit 1)
 WHERE curr IS NULL;

update entity_credit_account set language_code = 'en' where language_code is null;
