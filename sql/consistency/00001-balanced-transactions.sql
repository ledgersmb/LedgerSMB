--- yaml frontmatter
title: All transactions are balanced
---

select trans_id
  from acc_trans
 group by trans_id
having abs(sum(amount_bc)) > 0.005
