
-- Until the implementation of full multi-currency support,
-- there was no support for currencies in budgets. Therefore,
-- we can simply use the default currency for the 'curr' field
-- and copy the base currency amounts to the transaction currency
-- column.


UPDATE budget_line
   SET curr = (select value from defaults where setting_key = 'curr'),
       amount_tc = coalesce(amount, 0);

