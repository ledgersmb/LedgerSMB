

create table workflow_context (
  workflow_id int not null,
  context     jsonb,
  primary key ( workflow_id )
);
