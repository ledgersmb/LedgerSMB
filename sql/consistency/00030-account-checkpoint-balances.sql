--- yaml frontmatter
title: Account checkpoint balances match journal totals
description: |
  Account checkpoints summarize the impact of preceeding transactions
  on account level. The accumulated balance on an account should reconcile
  with the total stored in account checkpoints.
---


select *
  from (
    select *, (select sum(amount_bc)
                 from acc_trans
                where chart_id = account_id
                  and transdate <= end_date
                  and approved
                  and a.curr = curr) as journal_balance
      from (
        select account_id, end_date, curr, sum(amount_bc) as checkpoint_balance
          from account_checkpoint
         group by account_id, end_date, curr
      ) a
  ) b
 where checkpoint_balance <> journal_balance
 order by end_date, account_id

