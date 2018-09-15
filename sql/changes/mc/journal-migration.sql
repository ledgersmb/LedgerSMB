
UPDATE journal_line jl
   SET curr = (select currency from journal_entry je
                where je.id = jl.journal_id);


-- sale/receipt
UPDATE journal_line jl
   SET amount_tc = amount / (select buy from exchangerate e
                               join journal_entry je
                                    on e.transdate = je.post_date
                                       and e.curr = je.currency
                               where je.id = jl.journal_id)
 WHERE EXISTS (select 1 from journal_entry je
                where je.id = jl.journal_id
                      and je.journal in (2, 4));

-- purchase/payment
UPDATE journal_line jl
   SET amount_tc = amount / (select sell from exchangerate e
                               join journal_entry je
                                    on e.transdate = je.post_date
                                       and e.curr = je.currency
                               where je.id = jl.journal_id)
 WHERE EXISTS (select 1 from journal_entry je
                where je.id = jl.journal_id
                      and je.journal in (3, 5));


-- Journals of 'category 1' (General) don't have a natural
-- association with either buy or sell rates

-- And since there's only 1 amount flag in the
-- journal_line table and no 'fx_transaction'
-- flag, we'll have to assume it's currently
-- impossible to enter fx transactions in that
-- category. If that's true, there's no need
-- to implement a migration.

-- If there are any, a pre-change-check to
-- ask the user for rates is all we can offer.
