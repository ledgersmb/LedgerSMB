
ALTER TABLE transactions
   ADD COLUMN workflow_id int;

ALTER TABLE oe
   ADD COLUMN workflow_id int;

-- create transaction workflows

UPDATE transactions t
   SET workflow_id = nextval('workflow_seq')
 WHERE EXISTS (select 1 from ar where t.id = ar.id and ar.invoice)
       OR EXISTS (select 1 from ap where t.id = ap.id and ap.invoice);

WITH new_workflow AS (
   INSERT INTO workflow
   SELECT workflow_id, 'AR/AP' as type,
          CASE WHEN approved THEN 'POSTED' ELSE 'SAVED' END as state,
          now() as last_update
     FROM transactions
    WHERE workflow_id is not null
   RETURNING workflow_id, state, last_update
)
INSERT INTO workflow_history
SELECT nextval('workflow_history_seq') as workflow_hist_id,
       workflow_id,
       '<upgrade>' as action,
       'History item created for existing transaction during schema upgrade'
                as description,
       state,
       '<upgrade>' as workflow_user,
       last_update as history_date
  FROM new_workflow;

-- create order/quote workflows

UPDATE oe
   SET workflow_id = nextval('workflow_seq');

WITH new_workflow AS (
   INSERT INTO workflow
   SELECT workflow_id, 'Order/Quote' as type,
          'SAVED' as action, now() as last_update
     FROM oe
   RETURNING workflow_id, state, last_update
)
INSERT INTO workflow_history
            (workflow_hist_id, workflow_id, action, description,
             state, workflow_user, history_date)
SELECT nextval('workflow_history_seq') as workflow_hist_id,
       workflow_id,
       '<upgrade>' as action,
       'History item created for existing order/quote during schema upgrade'
                as description,
       state,
       '<upgrade>' as workflow_user,
       last_update as history_date
  FROM new_workflow;

ALTER TABLE transactions ADD CONSTRAINT transactions_workflow_id_fkey
        FOREIGN KEY (workflow_id) REFERENCES workflow (workflow_id);

ALTER TABLE oe ADD CONSTRAINT oe_workflow_id_fkey
        FOREIGN KEY (workflow_id) REFERENCES workflow (workflow_id);
