--- yaml frontmatter
title: Journal lines marked 'cleared' are part of a reconciliation
---

select *
  from acc_trans
 where cleared
   and chart_id in (select chart_id from cr_coa_to_account)
   and not exists (select 1
                     from cr_report_line_links
                    where acc_trans.entry_id = cr_report_line_links.entry_id
                      and cleared)
