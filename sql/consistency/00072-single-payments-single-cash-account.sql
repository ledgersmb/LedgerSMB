--- yaml frontmatter
title: Single payments affect one cash account per transaction
category: upgrade
description: |
  Payments entered in the single payment entry screen
  should affect only a single cash account per transaction.
---

select pl.payment_id, ac.trans_id
  from payment_links pl
       join acc_trans ac
        on pl.entry_id = ac.entry_id
 where exists (select 1
                 from account_link al
                where ac.chart_id = al.account_id
                  and al.description in ('AR_paid', 'AP_paid'))
 group by pl.payment_id, ac.trans_id
having count(*) > 1

