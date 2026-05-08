--- yaml frontmatter
title: Batch payments affect one cash account per transaction
category: upgrade
description: |
  Payments entered in the batch payment entry screen
  should affect only a single cash account per transaction.
---

select v.id, ac.trans_id
  from voucher v
       join acc_trans ac
        on v.id = ac.voucher_id
 where v.batch_class in (3, 4, 6, 7)
   and exists (select 1
                 from account_link al
                where ac.chart_id = al.account_id
                  and al.description in ('AR_paid', 'AP_paid'))
 group by v.id, ac.trans_id
having count(*) > 1

