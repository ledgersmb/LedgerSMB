
alter table cr_report
  add column workflow_id bigint references workflow(workflow_id);

-- now fill the workflow_ids
create function pg_temp.new_workflow(approved boolean, submitted boolean,
                                     deleted boolean)
  returns int
  as $$

  insert into workflow (workflow_id, type, state, last_update)
  values (nextval('workflow_seq'),
          'reconciliation',
          case
          when deleted then 'DELETED'
          when approved then 'APPROVED'
          when submitted then 'SUBMITTED'
          else 'SAVED'
          end,
          NOW())
   returning workflow_id;
$$ language sql;

update cr_report
   set workflow_id = pg_temp.new_workflow(approved, submitted, deleted);

insert into
 workflow_history (
   workflow_hist_id, workflow_id, action, description, state,
   workflow_user, history_date)
select nextval('workflow_history_seq'), workflow_id, 'migrate',
       'Workflow created by migration', state,
       CURRENT_USER, NOW()
  from cr_report
         join workflow using (workflow_id);

alter table cr_report
  alter column workflow_id set not null;
