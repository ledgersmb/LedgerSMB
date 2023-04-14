--- yaml frontmatter
title: |
  Summary accounts can't have other links
description: |
  Summary accounts must strictly have a single role, which means
  they can't have any other links than the single summary link
---

select accno
  from account a
  join account_link on a.id = account_link.account_id
  join account_link_description on account_link.description = account_link_description.description
  where account_link_description.summary
        and exists (
    select 1
      from account_link al
      join account_link_description using (description)
     where al.account_id = a.id
     group by account_id
     having count(*) <> 1
    )
