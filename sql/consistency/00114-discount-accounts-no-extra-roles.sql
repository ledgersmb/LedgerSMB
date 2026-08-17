--- yaml frontmatter
title: Discount accounts (AR/AP discount) must not have any other roles
description: |
  The application makes assumptions which are incompatible with
  discount accounts (AR/AP discount) having a summary role or
  'include in drop-down menus' checkmarks set other than
  'Receivables > Discount' and/or 'Payables > Discount'
---

select *
  from account a
  where a.id in (
    select account_id
      from account_link
     where description in ('AR_discount', 'AP_discount')
  )
  and (select count(*)
         from account_link al
        where al.account_id = a.id
          and al.description not in ('AR_discount', 'AP_discount')) > 0
