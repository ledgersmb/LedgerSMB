
ALTER TABLE BATCH DROP CONSTRAINT "batch_locked_by_fkey";

ALTER TABLE BATCH ADD FOREIGN KEY (locked_by) references session (session_id)
ON DELETE SET NULL;

