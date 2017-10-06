SET LOCAL client_min_messages=warning;
DROP INDEX IF EXISTS ac_transdate_year_idx;
RESET client_min_messages;

CREATE INDEX acc_trans_transdate_year_idx
    ON acc_trans (transdate, date_part('YEAR', transdate))
 WHERE transdate IS NOT NULL;

COMMENT ON INDEX acc_trans_transdate_year_idx IS
$$This index supports the function 'date_get_all_years' and
reduces that function to a series of index scans instead of table scans$$;
