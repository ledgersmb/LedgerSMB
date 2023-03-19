--- yaml frontmatter
title: Sum of journal balances equals report line balance
description: |
  Reconciliation lines refer to one or more journal lines. The total of the
  journal lines underlying a reconciliation line must equal the amount on
  the reconciliation line for the reconciliation to valid.
---

with ledger_balances as (
  select crll.report_line_id,
         case when cr.recon_fx then sum(amount_tc)
         else sum(amount_bc) end as ledger_amount
    from cr_report_line_links crll
           join acc_trans using (entry_id)
           join cr_report_line crl on crll.report_line_id = crl.id
           join cr_report cr on crl.report_id = cr.id
   group by cr.recon_fx, crll.report_line_id
)
select *
  from cr_report_line crl
         join ledger_balances lb
             on crl.id = lb.report_line_id
 where lb.ledger_amount <> crl.our_balance
   and crl.cleared
