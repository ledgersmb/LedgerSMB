--- yaml frontmatter
title: Records in 'transactions' have an associated ar/ap/gl record
description: |
  The 'transactions' table exists to prevent records with the same ID from being
  inserted into the 'ar', 'ap' and 'gl' tables by maintaining which table the record
  belongs to. This leaves open the possibility that a record exists in the 'transactions'
  table where no associated record exists in any of the three tables. This situation
  should not exist.
---

select id
  from transactions t
 where not exists (select 1 from ar where ar.id = t.id)
   and not exists (select 1 from ap where ap.id = t.id)
   and not exists (select 1 from gl where gl.id = t.id)
