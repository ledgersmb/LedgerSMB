--- yaml frontmatter
title: State of workflows linked to approved transactions
description: |
  Workflows linked to approved transactions must be in a state other
  than INITIAL, SAVED or DELETED (implying the transaction has not
  been posted).
---


select *
  from transactions trns
  join workflow wf on trns.workflow_id = wf.workflow_id
 where trns.approved
   and wf.state in ('INITIAL', 'SAVED', 'DELETED')
