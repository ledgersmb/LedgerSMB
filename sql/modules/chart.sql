CREATE OR REPLACE FUNCTION chart_list_cash(in_account_class int)
RETURNS SETOF chart AS
$$
DECLARE resultrow record;
        link_string text;
BEGIN
        IF in_account_class = 1 THEN
           link_string := '%AR_paid%';
        ELSE 
           link_string := '%AP_paid%';
        END IF;

        FOR resultrow IN
          SELECT *  FROM chart
          WHERE link LIKE link_string
          ORDER BY accno
          LOOP
          return next resultrow;
        END LOOP;
END;
$$ language plpgsql;
COMMENT ON FUNCTION chart_list_cash(in_account_class int) IS
$$ This function returns the cash account acording with in_account_class which must be 1 or 2 $$;
