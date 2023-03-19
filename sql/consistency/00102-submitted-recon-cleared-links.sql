--- yaml frontmatter
title: Submitted reconciliation report journal line link status
description: |
  Each journal line link of a submitted report must have a
  'cleared' status, if the report line has a 'cleared' status.
---

select *
  from cr_report_line_links crll
         join cr_report_line crl
             on crll.report_line_id = crl.id
         join cr_report cr
             on crl.report_id = cr.id
 where crll.cleared is distinct from (crl.cleared and cr.submitted)
