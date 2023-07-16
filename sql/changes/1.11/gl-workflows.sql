
create temporary table workflow_transactions as
  select gl.id as gl,
         nextval('workflow_seq') as wf,
         CASE WHEN approved THEN 'POSTED'
         ELSE 'SAVED' END as state
  from gl
  where not exists (select from yearend y where y.trans_id = gl.id)
  and not exists (select from payment p where p.gl_id = gl.id)
  and not exists (select from inventory_report r where r.trans_id = gl.id)
  and not exists (select from asset_report a where a.gl_id = gl.id);

insert into workflow (workflow_id, type, state, last_update)
select wf, 'GL', state, now()
  from workflow_transactions;

update transactions trn
   set workflow_id = wf
  from workflow_transactions wt
 where trn.id = wt.gl;

insert into workflow_history
            (workflow_hist_id, workflow_id, action,
            description, state, workflow_user, history_date)
select nextval('workflow_history_seq'), wf, 'MIGRATE',
       'Workflow created during migration', state,
       CURRENT_USER, now()
  from workflow_transactions;
