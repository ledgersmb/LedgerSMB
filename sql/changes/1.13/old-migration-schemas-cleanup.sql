
create or replace function pg_temp.schedule_schema_deletion(in_schema text)
  returns void as $$
declare
  t_transdate date;
  t_cleanup_date date;
begin
  perform *
     from information_schema.schemata
    where schema_name = in_schema;

  if not found then
    return;
  end if;

  execute 'select max(transdate) into t_transdate from ' || quote_ident(in_schema) || '.acc_trans';
  t_cleanup_date := greatest(
    coalesce((t_transdate + '7 years'::interval), CURRENT_DATE),
    (CURRENT_DATE + '2 years'::interval)
  );
  insert into defaults (setting_key, "value")
  values ('post-upgrade-run:cleanup-migration-schema/' || in_schema,
          json_build_object('action', 'cleanup-migration-schema',
                            'description', 'Cleanup of migration schema "' || in_schema || '"',
                            'run-after', t_cleanup_date::text,
                            'args', json_build_object('schema', in_schema)::text));

  return;
end;
$$ language plpgsql;

DO $$
BEGIN
  perform pg_temp.schedule_schema_deletion('lsmb12');
  perform pg_temp.schedule_schema_deletion('lsmb13');
  perform pg_temp.schedule_schema_deletion('sl28');
  perform pg_temp.schedule_schema_deletion('sl30');
  perform pg_temp.schedule_schema_deletion('sl32');
END;
$$ LANGUAGE plpgsql;
