--- yaml frontmatter
title: Batch payments are balanced
category: upgrade
description: |
  Payments entered through the batch payment entry screen
  have links to journal lines. This validates that the
  collection of journal lines linked to, balances.
---

select v.id, ac.trans_id
  from voucher v
       join acc_trans ac
         on v.id = ac.voucher_id
 where batch_class in (3, 4, 6, 7)
 group by v.id, ac.trans_id
having abs(sum(amount_bc)) > 0.005

