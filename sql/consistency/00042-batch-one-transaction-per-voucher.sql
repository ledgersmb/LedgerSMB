--- yaml frontmatter
title: Each voucher is linked to journal lines of exactly one transaction
description: |
  Vouchers are the link between journal lines (of a transaction) and
  batches. Each batch can have many vouchers. Each voucher can have
  many journal lines. But each voucher is strictly linked to one transaction.
---

select v.id as voucher_id, count(distinct a.trans_id) as transaction_count
  from voucher v
         join acc_trans a
             on v.id = a.voucher_id
 group by v.id
  having count(distinct a.trans_id) > 1
  order by v.id
