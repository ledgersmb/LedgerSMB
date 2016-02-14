BEGIN;

CREATE OR REPLACE FUNCTION business_type__list() RETURNS SETOF business AS
$$
	SELECT * FROM business ORDER BY description LOOP
$$ LANGUAGE SQL;

COMMENT ON function business_type__list() IS
$$Returns a list of all business types. Ordered by description by default.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
