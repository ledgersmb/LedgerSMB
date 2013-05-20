BEGIN;

CREATE TEMPORARY VIEW vc AS
  SELECT credit_id, taxincluded FROM lsmb12.customer
  UNION
  SELECT credit_id, taxincluded FROM lsmb12.vendor;

UPDATE entity_credit_account
   SET taxincluded = (select taxincluded from vc 
                       WHERE credit_id = entity_credit_account.id)
 WHERE id IN (select credit_id from vc);

COMMIT;
