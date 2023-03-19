--- yaml frontmatter
title: Journal lines marked 'cleared' are part of a reconciliation
description: |
  Journal lines can only be cleared by way of reconciliation. This means that
  all lines which are cleared, must be part of a reconciliation which is itself
  submitted and approved.
---

select *
  from acc_trans
 where cleared
   and not exists (select 1
                     from cr_report_line_links
                    where acc_trans.entry_id = cr_report_line_links.entry_id
                      and cleared)
