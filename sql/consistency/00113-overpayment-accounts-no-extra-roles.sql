--- yaml frontmatter
title: Overpayment accounts (AR/AP overpayment) must not have any other roles
description: |
  The application makes assumptions which are incompatible with
  overpayment accounts (AR/AP overpayment) having a summary account role or
  having 'include in drop-down menus' checkmarks set other than
  'Receivables / Overpayment' and/or 'Payables / Overpayment'
---

select *
  from account a
  where a.id in (
    select account_id
      from account_link
     where description in ('AR_overpayment', 'AP_overpayment')
  )
  and (select count(*)
         from account_link al
        where al.account_id = a.id
          and al.description not in ('AR_overpayment', 'AP_overpayment')) > 0
