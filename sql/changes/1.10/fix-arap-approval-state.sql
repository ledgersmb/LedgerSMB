
update workflow u
   set state = "POSTED"
       from workflow w
       join transactions t on t.workflow_id = w.workflow_id
 where w.workflow_id = u.workflow_id
   and w.state in ('SAVED', 'INITIAL')
   and t.approved;

