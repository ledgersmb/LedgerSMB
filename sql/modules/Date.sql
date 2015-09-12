BEGIN;
-- Copyright (C) 2011 LedgerSMB Core Team.  Licensed under the GNU General
-- Public License v 2 or at your option any later version.

-- Docstrings already added to this file.

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
$$ This function return each year inside transdate in transactions.
Currently it uses a sparse index scan because the number of rows returned is
very small and the table can be very large.$$;

CREATE OR REPLACE FUNCTION is_leapyear(in_date date) returns bool as
$$
    select extract('day' FROM (
                           (extract('year' FROM $1)::text
                           || '-02-28')::date + '1 day'::interval)::date)
           = 29;
$$ language sql;

COMMENT ON FUNCTION is_leapyear(in_date date) IS
$$ Returns true if date is in a leapyear.  False if not.  Uses the built-in
PostgreSQL date handling, and no direct detection is done in our code.$$;

CREATE OR REPLACE FUNCTION leap_days(in_year_from int, in_year_to int)
RETURNS int AS
$$
   SELECT count(*)::int
   FROM generate_series($1, $2)
   WHERE is_leapyear((generate_series::text || '-01-01')::date);
$$ LANGUAGE SQL;

COMMENT ON FUNCTION leap_days(in_year_from int, in_year_to int) IS
$$Returns the number of leap years between the two year inputs, inclusive.$$;

CREATE OR REPLACE FUNCTION next_leap_year_calc(in_date date, is_end bool)
returns int as
$$
SELECT
          (CASE WHEN extract('doy' FROM $1) < 59
          THEN extract('year' FROM $1)
          ELSE extract('year' FROM $1) + 1
          END)::int
          -
          CASE WHEN $2 THEN 1 ELSE 0 END;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION next_leap_year_calc(in_date date, is_end bool) IS
$$Next relevant leap year calculation for a daily depreciation calculation$$;

CREATE OR REPLACE FUNCTION get_fractional_year
(in_date_from date, in_date_to date)
RETURNS numeric AS
$$
   select ($2 - $1
            - leap_days(next_leap_year_calc($1, false),
                       next_leap_year_calc($2, true)))
            /365::numeric;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION get_fractional_year (in_date_from date, in_date_to date) IS
$$ Returns the decimal representation of the fractional year.$$;

CREATE OR REPLACE FUNCTION days_in_month(in_date date)
returns int AS
$$
SELECT (extract(DOM FROM date_trunc('month', $1)
                         + '1 month - 1 second'::interval)
      )::int;

$$ language sql;

COMMENT ON FUNCTION days_in_month(in_date date) IS
$$ Returns the number of days in the month that includes in_date.$$;

CREATE OR REPLACE FUNCTION is_same_year (in_date1 date, in_date2 date)
returns bool as
$$
SELECT  extract ('YEAR' from $1) = extract ('YEAR' from $2);
$$ language sql;

COMMENT ON FUNCTION is_same_year (in_date1 date, in_date2 date) IS
$$ Returns true if the two dates are in the same year, false otherwise.$$;

CREATE OR REPLACE FUNCTION is_same_month (in_date1 date, in_date2 date)
returns bool as
$$
SELECT is_same_year($1, $2)
       and extract ('MONTH' from $1) = extract ('MONTH' from $2);
$$ language sql;

COMMENT ON  FUNCTION is_same_month (in_date1 date, in_date2 date) IS
$$ Returns true if the two dates are in the same month and year. False
otherwise.$$;

CREATE OR REPLACE FUNCTION get_fractional_month
(in_date_first date, in_date_second date)
RETURNS NUMERIC AS
$$
SELECT CASE WHEN is_same_month($1, $2)
            THEN ($2 - $1)::numeric
                 / days_in_month($1)
            ELSE (get_fractional_month(
                   $1, (date_trunc('MONTH', $1)
                       + '1 month - 1 second'::interval)::date)
                 + get_fractional_month(date_trunc('MONTH', $2)::date, $2)
                 + (extract ('YEAR' from $2) - extract ('YEAR' from $1) * 12)
                 + extract ('MONTH' from $1) - extract ('MONTH' from $2)
                 - 1)::numeric
            END;
$$ language sql;

COMMENT ON  FUNCTION get_fractional_month
(in_date_first date, in_date_second date) IS
$$ Returns the number of months between two dates in numeric form.$$;

CREATE OR REPLACE FUNCTION periods_get()
RETURNS SETOF periods
AS
$$
SELECT * FROM periods ORDER BY id
$$ language sql;

COMMENT ON FUNCTION periods_get() IS
$$ Returns dates for year to date, and last year.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
