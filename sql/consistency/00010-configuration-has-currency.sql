--- yaml frontmatter
title: Configuration has currency set
description: |
  In the configuration, a functional (default) currency must be set.
---

select 'Missing "curr" configuration key' as error
  from defaults
 where not exists (select 1 from defaults where setting_key = 'curr')
