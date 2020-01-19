
set client_min_messages = 'warning';


CREATE TEMPORARY TABLE blacklisted_funcs (funcname text primary key);
\copy blacklisted_funcs FROM 'sql/modules/BLACKLIST';
DO $$
DECLARE f record;
BEGIN

    WITH function_list AS (
        SELECT n.nspname as "Schema",
            p.proname as "Name",
            pg_catalog.pg_get_function_result(p.oid) as "Result data type",
            pg_catalog.pg_get_function_arguments(p.oid) as "Argument data types"
        FROM pg_catalog.pg_proc p
        LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
        WHERE pg_catalog.pg_function_is_visible(p.oid)
              AND n.nspname <> 'pg_catalog'
              AND n.nspname <> 'information_schema'
              AND p.proname IN (
                  SELECT funcname from blacklisted_funcs
              )
        ORDER BY 1, 2, 4
    )
    SELECT * INTO f from function_list
    WHERE "Name" in (
        SELECT "Name" FROM function_list
        GROUP BY 1
        HAVING COUNT(*) > 1);

    IF f IS NULL THEN
        UPDATE defaults SET value ='yes' WHERE setting_key = 'module_load_ok';
    ELSE
        UPDATE defaults SET value ='no' WHERE setting_key = 'module_load_ok';
        RAISE EXCEPTION 'Duplicate functions found: %',f;
    END IF;
END$$;
