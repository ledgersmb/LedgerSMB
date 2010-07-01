CREATE OR REPLACE FUNCTION date_get_all_years() returns setof INT AS
$$
DECLARE next_record int;
BEGIN

SELECT MIN(EXTRACT ('YEAR' FROM transdate))::INT
INTO next_record
FROM acc_trans;

LOOP

  EXIT WHEN next_record IS NULL;
  RETURN NEXT next_record;
  SELECT MIN(EXTRACT ('YEAR' FROM transdate))::INT AS YEAR
  INTO next_record
  FROM acc_trans
  WHERE EXTRACT ('YEAR' FROM transdate) > next_record;


END LOOP;

END;
$$ language plpgsql;                                                                  
COMMENT ON FUNCTION date_get_all_years() IS
$$ This function return each year inside transdate in transactions. $$;
