--- yaml frontmatter
title: Sum of journal balances equals report line balance
---

with ledger_balances as (
  select crll.report_line_id, sum(amount_bc) as ledger_amount
    from cr_report_line_links crll
           join acc_trans using (entry_id)
   group by crll.report_line_id
)
select *
  from cr_report_line crl
         join ledger_balances lb
             on crl.id = lb.report_line_id
 where lb.ledger_amount <> crl.our_balance
   and crl.cleared
