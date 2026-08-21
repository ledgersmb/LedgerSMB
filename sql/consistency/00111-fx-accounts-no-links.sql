--- yaml frontmatter
title: FX gain/loss accounts must not have any other roles
description: |
  Foreign exchange gain/loss accounts (set in System > Defaults)
  should not have any 'include in drop-down menus' checkmarks or summary roles set
---

select *
  from account a
  where a.id in (
    select value::int
      from defaults
     where setting_key in ('fxgain_accno_id', 'fxloss_accno_id')
  )
  and (select count(*)
         from account_link al
        where al.account_id = a.id) > 0
