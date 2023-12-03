--- yaml frontmatter
title: Approved batches contain only approved transactions
description: |
  All transactions in a batch must have the same approval state as
  the batch itself. This query verifies that all approved batches
  consist entirely of approved transactions.
---


select * from batch
 where approved_on is not null
   and exists (select 1 from transactions t
                               join voucher v on v.trans_id = t.id
                where batch.id = v.batch_id
                  and not t.approved)

