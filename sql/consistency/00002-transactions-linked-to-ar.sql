--- yaml frontmatter
title: "'ar' Records in 'transactions' are linked to the 'ar' table"
description: |
  The 'transactions' table exists to prevent records with the same ID from being
  inserted into the 'ar', 'ap' and 'gl' tables by maintaining which table the record
  belongs to. This leaves open the possibility that a record exists in the 'transactions'
  table which ends up being linked to one of the other tables (either additionally or
  exclusively).
---

select *
  from transactions
         join ar
             on transactions.id = ar.trans_id
 where transactions.trans_type_code is distinct from 'ar'
