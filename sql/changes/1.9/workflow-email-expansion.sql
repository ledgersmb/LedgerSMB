

alter table email
   add column if not exists expansions jsonb;

update email set expansions = '{}'::jsonb;

