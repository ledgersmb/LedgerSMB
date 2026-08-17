--- yaml frontmatter
title: AR/AP tax accounts must not have any other roles
description: |
  The application makes assumptions which are incompatible with
  AR/AP tax accounts having any 'include in drop-down menu' checkmarks
  other than 'Receivables/Payables/Tracking items/Non-tracking items > Tax'
---

select *
  from account a
  where a.id in (
    select account_id
      from account_link
     where description in ('AR_tax', 'AP_tax', 'IC_tax', 'IC_taxpart', 'IC_taxservice')
  )
  and (select count(*)
         from account_link al
        where al.account_id = a.id
          and al.description not in ('AR_tax', 'AP_tax', 'IC_tax', 'IC_taxpart', 'IC_taxservice')) > 0
