
-- Note that the aa-migration pre-checks made sure that any missing
-- 'curr' values have been filled out by the user, in so far the
-- transactions included lines marked as fx transactions

-- Remaining lines thus must be base/default currency transactions
--  If the amount is NULL, we can't set the currency, unless we set
--  the amount to 0 (zero) [it's treated that way anyway]

UPDATE ar
   SET curr = (select value from defaults where setting_key = 'curr'),
       amount = coalesce(amount, 0)
 WHERE curr IS NULL;

UPDATE ap
   SET curr = (select value from defaults where setting_key = 'curr'),
       amount = coalesce(amount, 0)
 WHERE curr IS NULL;


UPDATE ar
   SET amount_bc = amount,
       netamount_bc = netamount;

UPDATE ar
   SET amount_tc = amount_bc,
       netamount_tc = netamount_bc
 WHERE curr = (select value from defaults where setting_key = 'curr');

UPDATE ar
   SET amount_tc = amount_bc / (select buy from exchangerate e
                                 where e.transdate = ar.transdate
                                       and ar.curr = e.curr),
       netamount_tc = netamount_bc / (select buy from exchangerate e
                                 where e.transdate = ar.transdate
                                       and ar.curr = e.curr)
 WHERE NOT curr = (select value from defaults where setting_key = 'curr');


UPDATE ap
   SET amount_bc = amount,
       netamount_bc = netamount;

UPDATE ap
   SET amount_tc = amount_bc,
       netamount_tc = netamount_bc
 WHERE curr = (select value from defaults where setting_key = 'curr');

UPDATE ap
   SET amount_tc = amount_bc / (select sell from exchangerate e
                                 where e.transdate = ap.transdate
                                       and ap.curr = e.curr),
       netamount_tc = netamount_bc / (select sell from exchangerate e
                                 where e.transdate = ap.transdate
                                       and ap.curr = e.curr)
 WHERE NOT curr = (select value from defaults where setting_key = 'curr');
