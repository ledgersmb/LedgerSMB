--- yaml frontmatter
title: Configured currency exists in the list of currencies
description: |
  The currency configured as the functional (base) currency should
  exist in the list of configured currencies
---

select 'Missing functional currency in currencies list' as error
  from defaults
 where not exists (select 1 from currency where defaults.value = currency.curr)
       and defaults.setting_key = 'curr'
