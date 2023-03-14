--- yaml frontmatter
title: Records in 'transactions' have an associated ar/ap/gl record
---

select id
  from transactions t
 where not exists (select 1 from ar where ar.id = t.id)
   and not exists (select 1 from ap where ap.id = t.id)
   and not exists (select 1 from gl where gl.id = t.id)
