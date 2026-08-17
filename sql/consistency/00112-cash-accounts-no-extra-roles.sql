--- yaml frontmatter
title: Cash accounts (AR/AP payment) must not have any other roles
description: |
  The application makes assumptions which are incompatible with
  cash accounts (AR/AP payment) having a 'summary account' or
  any 'include in drop-down menus' checkmarks set, other than
  'Receivables > Payment' and/or 'Payables > Payment'
---

select *
  from account a
  where a.id in (
    select account_id
      from account_link
     where description in ('AR_paid', 'AP_paid')
  )
  and (select count(*)
         from account_link al
        where al.account_id = a.id
          and al.description not in ('AR_paid', 'AP_paid')) > 0
