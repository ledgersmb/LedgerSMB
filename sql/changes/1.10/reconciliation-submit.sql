DROP FUNCTION IF exists reconciliation__submit_set(in_report_id integer, in_line_ids integer[]);

CREATE OR REPLACE FUNCTION reconciliation__submit_set(in_report_id int)
RETURNS bool AS
$$
BEGIN
        UPDATE cr_report set submitted = true where id = in_report_id;

        RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION reconciliation__submit_set(in_report_id int) IS
$$Submits a reconciliation report for approval.
in_line_ids is used to specify which report lines are cleared, finalizing the
report.$$;
