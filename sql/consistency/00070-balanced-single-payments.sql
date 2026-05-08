--- yaml frontmatter
title: Single payments are balanced
category: upgrade
description: |
  Payments entered through the single payment entry screen
  have links to journal lines. This validates that the
  collection of journal lines linked to, balances.
---

select pl.payment_id, ac.trans_id
  from payment_links pl
       join acc_trans ac
         on pl.entry_id = ac.entry_id
 group by pl.payment_id, ac.trans_id
having abs(sum(amount_bc)) > 0.005

