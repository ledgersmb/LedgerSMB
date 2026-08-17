--- yaml frontmatter
title: Summary accounts must not have 'include in drop-down menus' checkmarks
description: |
  Summary accounts (AR/AP/IC) should not have any 'include in drop-down menu'
  checkmarks set
---

select *
  from account a
  where exists (select 1
                  from account_link al
                         join account_link_description ald
                             using(description)
                 where al.account_id = a.id
                   and ald.summary)
  and (select count(*)
         from account_link al
        where al.account_id = a.id) > 1
