

create table workflow_context (
  workflow_id int not null references workflow(workflow_id),
  context     jsonb,
  primary key ( workflow_id )
);

