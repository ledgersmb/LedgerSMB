
-- workflow_entity_id column expressly left nullable, because
-- otherwise it becomes impossible to run workflows from
-- e.g. upgrade code: the database admin role generally isn't
-- a company user...
ALTER TABLE workflow_history
  ADD COLUMN workflow_entity_id int references entity (id);

CREATE OR REPLACE FUNCTION trigger_workflow_user() RETURNS TRIGGER
AS $$
BEGIN
  -- placeholder! please edit triggers.sql!
  RETURN NEW;
END;
$$ language plpgsql;


create trigger trigger_workflow_user before update or insert
  on workflow_history
  for each row execute function trigger_workflow_user();
