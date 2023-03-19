--- yaml frontmatter
title: Cleared journal lines have an associated reconciliation account
description: |
  The 'cleared' indicator on journal lines indicates they have been successfully
  reconciled. In order for lines to have been reconciled, they must be associated
  with an account for which reconciliation is applicable.
---

select distinct chart_id
  from acc_trans a
 where not exists (select 1
                     from cr_coa_to_account ca
                    where ca.chart_id = a.chart_id)
   and a.cleared
