

WITH aa_transactions AS (
  UPDATE transactions trx
     SET workflow_id = nextval('workflow_seq')
   WHERE workflow_id IS NULL
     AND (EXISTS (select 1 from ar where trx.id = ar.id and not ar.invoice)
          OR EXISTS (select 1 from ap where trx.id = ap.id and not ap.invoice))
         RETURNING *
),
new_workflow AS (
  INSERT INTO workflow
  SELECT workflow_id, 'AR/AP' as type,
         CASE WHEN approved THEN 'POSTED' ELSE 'SAVED' END as state,
         now() as last_update
    FROM aa_transactions
  RETURNING workflow_id, state, last_update
),
new_context AS (
  INSERT INTO workflow_context
  SELECT workflow_id, jsonb_build_object( 'is_transaction', 1,
                                         'transdate', transdate,
                                         'table_name', table_name)
    FROM new_workflow
           JOIN aa_transactions USING (workflow_id)
  RETURNING workflow_id
)
    INSERT INTO workflow_history
SELECT nextval('workflow_History_seq') as workflow_hist_id,
       workflow_id,
       '<upgrade>' as action,
       'History item created for existing transaction during schema upgrade' as description,
       state,
       '<upgrade>' as workflow_user,
       last_update as history_date
  FROM new_context JOIN new_workflow USING (workflow_id);
