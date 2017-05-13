

-- Note that the two statements below can fail in case
-- inventory adjustments and/or regular invoices have been
-- (accidentally) attached to the inventory entity. In that case,
-- We can't delete in that case.
-- This file is therefore set to allow failure in LOADORDER

DELETE FROM entity_credit_account
       WHERE entity_id = 0 and meta_number = '00000';

DELETE FROM entity
       WHERE id = 0;
