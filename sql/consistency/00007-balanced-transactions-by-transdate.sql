--- yaml frontmatter
title: All transactions are balanced for each posting date
description: |
  Transactions must be balanced; a balance sheet must be balanced
  at all times and transactions being the building blocks of a
  balance sheet, they need to be balanced too. In LedgerSMB, transactions
  can span multiple posting dates. Each of these must be balanced.
---

select trans_id, transdate
  from acc_trans
 group by trans_id, transdate
  having abs(sum(amount_bc)) >= power(10, -1*coalesce((select value::numeric
                                                        from defaults
                                                       where setting_key = 'decimal_places'),
                                                       2))/2
