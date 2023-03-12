--- yaml frontmatter
 title: Cleared journal lines have reconciled accounts
 description: |
  ahh
---

select *
  from acc_trans gl
 where cleared
   and not exists (select 1
                     from cr_coa_to_account a
                    where a.chart_id = gl.chart_id)

