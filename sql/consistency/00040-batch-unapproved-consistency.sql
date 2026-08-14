--- yaml frontmatter
title: Unapproved batch contains only unapproved transactions
description: |
  All transactions in a batch must have the same approval state as
  the batch itself. This query verifies that all unapproved batches
  consist entirely of unapproved transactions.
---


select * from batch
 where approved_on is null
   and exists (select 1 from transactions t
                where batch.id = t.batch_id
                  and t.approved)

