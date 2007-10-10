CREATE OR REPLACE FUNCTION date_get_all_years() returns setof INT AS
$$
DECLARE
    date_out record;
    BEGIN
        FOR date_out IN
           SELECT EXTRACT('YEAR' from transdate) AS year
           FROM acc_trans
           GROUP BY EXTRACT('YEAR' from transdate)
           ORDER BY year
        LOOP
             return next date_out.year;
        END LOOP;
    END;
$$ language plpgsql;                                                                  
COMMENT ON FUNCTION date_get_all_years() IS
$$ This function return each year inside transdate in transactions. $$;
