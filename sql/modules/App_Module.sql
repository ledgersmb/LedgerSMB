BEGIN;

CREATE OR REPLACE FUNCTION lsmb_module__get(in_id int) RETURNS lsmb_module AS
$$ SELECT * FROM lsmb_module where id = $1; $$ LANGUAGE SQL;

COMMENT ON FUNCTION lsmb_module__get(in_id int) IS
$$ Retrieves a single module's info by id. $$; --'

CREATE OR REPLACE FUNCTION lsmb_module__list() RETURNS SETOF lsmb_module AS
$$ SELECT * FROM lsmb_module ORDER BY id $$ LANGUAGE SQL;

COMMENT ON FUNCTION lsmb_module__list() IS
$$ Returns a list of all defined modules, ordered by id. $$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
