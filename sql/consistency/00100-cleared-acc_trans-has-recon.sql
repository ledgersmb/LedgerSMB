--- yaml front matter
title: Cleared journal lines have an associated reconciliation account
---

select distinct chart_id
  from acc_trans a
 where not exists (select 1 from cr_coa_to_account ca where ca.chart_id = a.chart_id)
       and a.cleared
