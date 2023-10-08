--- yaml frontmatter
title: Approval consistent across transactions and AR/AP/GL
description: |
  ahhh
---

select trns.*
  from transactions trns
  join ar on trns.id = ar.id
 where trns.approved is distinct from ar.approved
 union all
select trns.*
  from transactions trns
  join ap on trns.id = ap.id
 where trns.approved is distinct from ap.approved
 union all
select trns.*
  from transactions trns
  join gl on trns.id = gl.id
 where trns.approved is distinct from gl.approved
