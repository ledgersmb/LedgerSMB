
set client_min_messages = 'warning';


-- The reconciliation reports have the following state transition diagram:


-- +----------+    +--------+    +------------+    +------------+
-- | Initial  +--->+ Saved  +--->+ Submitted  +-+->+ Accepted   |
-- +----------+    +-+------+    +------+-----+ |  +------------+
--                   | ^                |       |
--                   | \---Rejecting----/       |  +------------+
--                   \--------------------------+->+ Deleted    |
--                                                 -------------+

-- lines from acc_trans are referenced in the report lines. The cr_report_lines
-- are marked 'cleared' as soon as they are marked reconciled (and saved) in
-- the reconciliation screen.

-- When a report is Rejected, it's returned to the saved state for correction.

-- Upon *approval*, the 'cleared' status is written to the 'acc_trans' table,
-- which means that rejected or deleted reports don't have any impact on
-- the reconciliation state of the actual transactions.



BEGIN;

CREATE OR REPLACE FUNCTION reconciliation__submit_set(
        in_report_id int, in_line_ids int[]) RETURNS bool AS
$$
BEGIN
        UPDATE cr_report set submitted = true where id = in_report_id;
        PERFORM reconciliation__save_set(in_report_id, in_line_ids);

        RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION reconciliation__submit_set(
        in_report_id int, in_line_ids int[]) IS
$$Submits a reconciliation report for approval.
in_line_ids is used to specify which report lines are cleared, finalizing the
report.$$;

CREATE OR REPLACE FUNCTION reconciliation__check(in_end_date date, in_chart_id int)
RETURNS SETOF defaults
LANGUAGE SQL AS
$$
WITH unapproved_tx as (
     SELECT 'unapproved_transactions'::text, count(*)::text
       FROM (SELECT          id::text FROM ar        WHERE approved IS FALSE AND transdate < $1
      UNION  SELECT          id::text FROM ap        WHERE approved IS FALSE AND transdate < $1
      UNION  SELECT          id::text FROM gl        WHERE approved IS FALSE AND transdate < $1
      UNION  SELECT DISTINCT source   FROM acc_trans WHERE approved IS FALSE AND transdate < $1 AND chart_id = $2
            ) tx
),
     unapproved_cr as (
     SELECT 'unapproved_reports'::text, count(*)::text
       FROM cr_report
      WHERE end_date < $1 AND approved IS NOT TRUE AND chart_id = $2
)
SELECT * FROM unapproved_tx
UNION SELECT * FROM unapproved_cr;
$$;

CREATE OR REPLACE FUNCTION reconciliation__reject_set(in_report_id int)
RETURNS bool language sql as $$
     UPDATE cr_report set submitted = false
      WHERE id = in_report_id
            AND approved is not true
     RETURNING true;
$$ SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION reconciliation__reject_set(in_report_id int) FROM public;

CREATE OR REPLACE FUNCTION reconciliation__save_set(
        in_report_id int, in_line_ids int[]) RETURNS bool AS
$$
        UPDATE cr_report_line SET cleared = false
        WHERE report_id = in_report_id;

        UPDATE cr_report_line SET cleared = true
        WHERE report_id = in_report_id AND id = ANY(in_line_ids)
        RETURNING TRUE;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION reconciliation__save_set(
        in_report_id int, in_line_ids int[]) IS
$$Sets which lines of the report are cleared.$$;

CREATE OR REPLACE FUNCTION reconciliation__delete_my_report(in_report_id int)
RETURNS BOOL AS
$$
    DELETE FROM cr_report_line
     WHERE report_id = in_report_id
           AND report_id IN (SELECT id FROM cr_report
                              WHERE entered_username = SESSION_USER
                                    AND submitted IS NOT TRUE
                                    and approved IS NOT TRUE);
    DELETE FROM cr_report
     WHERE id = in_report_id AND entered_username = SESSION_USER
           AND submitted IS NOT TRUE AND approved IS NOT TRUE
    RETURNING TRUE;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Granting execute permission to public because everyone has an ability to
-- delete their own reconciliation reports provided they have not been
-- submitted.  --CT
GRANT EXECUTE ON FUNCTION reconciliation__delete_my_report(in_report_id int)
TO PUBLIC;

COMMENT ON FUNCTION reconciliation__delete_my_report(in_report_id int) IS
$$This function allows a user to delete his or her own unsubmitted, unapproved
reconciliation reports only.  This is designed to allow a user to back out of
the reconciliation process without cluttering up the search results for others.
$$;

CREATE OR REPLACE FUNCTION reconciliation__delete_unapproved(in_report_id int)
RETURNS BOOL AS
$$
    DELETE FROM cr_report_line
     WHERE report_id = in_report_id
           AND report_id IN (SELECT id FROM cr_report
                              WHERE approved IS NOT TRUE);
    DELETE FROM cr_report
     WHERE id = in_report_id AND approved IS NOT TRUE
    RETURNING TRUE;
$$ LANGUAGE SQL SECURITY DEFINER;

-- This function is a bit more dangerous and so it is not granted public
-- permission.  Only those who have the permission to those with an ability to
-- approve reports should have access to this.
REVOKE EXECUTE ON FUNCTION reconciliation__delete_unapproved(in_report_id int)
FROM PUBLIC;

COMMENT ON FUNCTION reconciliation__delete_unapproved(in_report_id int) IS
$$This function deletes any specified unapproved transaction.$$;

CREATE OR REPLACE FUNCTION cr_report_block_changing_approved()
RETURNS TRIGGER AS
$$
BEGIN
   IF OLD.approved IS TRUE THEN
       RAISE EXCEPTION 'Report is approved.  Cannot change!';
   END IF;
   IF TG_OP = 'DELETE' THEN
       RETURN OLD;
   ELSE
      RETURN NEW;
   END IF;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS block_change_when_approved ON cr_report;

CREATE TRIGGER block_change_when_approved BEFORE UPDATE OR DELETE ON cr_report
FOR EACH ROW EXECUTE PROCEDURE cr_report_block_changing_approved();

COMMENT ON FUNCTION cr_report_block_changing_approved() IS
$$ This is a simple filter that prevents updating or deleting reconciliation
reports that have already been approved.  To purge old reconciliations you must
disable the block_change_when_approved trigger on cr_report.$$;

DROP FUNCTION IF EXISTS reconciliation__get_cleared_balance(int);
CREATE OR REPLACE FUNCTION reconciliation__get_cleared_balance(in_chart_id int,
   in_report_date date DEFAULT date_trunc('second', now()))
RETURNS numeric AS
$$
    SELECT sum(ac.amount) * CASE WHEN c.category in('A', 'E') THEN -1 ELSE 1 END
        FROM account c
        JOIN acc_trans ac ON (ac.chart_id = c.id)
    JOIN (      SELECT id FROM ar WHERE approved
          UNION SELECT id FROM ap WHERE approved
          UNION SELECT id FROM gl WHERE approved
          ) g ON g.id = ac.trans_id
    WHERE c.id = $1 AND cleared
      AND ac.approved IS true
      AND ac.transdate <= in_report_date
    GROUP BY c.id, c.category;
$$ LANGUAGE sql;

COMMENT ON FUNCTION reconciliation__get_cleared_balance(in_chart_id int,in_report_date date) IS
$$ Gets the cleared balance of the account specified by chart_id, as of in_report_date.
This is specified in normal format (i.e. positive numbers for debits for asset
and espense accounts, and positive numbers for credits in other accounts

Note that currently contra accounts will show negative balances.$$;

CREATE OR REPLACE FUNCTION reconciliation__report_approve (in_report_id INT) returns INT as $$

    -- Does some basic checks before allowing the approval to go through;
    -- moves the approval to "cr_report_line", I guess, or some other "final" table.
    --
    -- Pending may just be a single flag in the database to mark that it is
    -- not finalized. Will need to discuss with Chris.

    DECLARE
        current_row RECORD;
        completed cr_report_line;
        total_errors INT;
        in_user TEXT;
        ac_entries int[];
    BEGIN
        in_user := current_user;

        -- so far, so good. Different user, and no errors remain. Therefore,
        -- we can move it to completed reports.
        --
        -- User may not be necessary - I would think it better to use the
        -- in_user, to note who approved the report, than the user who
        -- filed it. This may require clunkier syntax..

        --
        ac_entries := '{}';
        UPDATE cr_report SET approved = 't',
                approved_by = person__get_my_entity_id(),
                approved_username = SESSION_USER
        WHERE id = in_report_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No report at %.', $1;
        END IF;

        FOR current_row IN
                SELECT compound_array(entries) AS entries FROM (
                        select as_array(ac.entry_id) as entries
                FROM acc_trans ac
                JOIN transactions t on (ac.trans_id = t.id)
                JOIN (select id, entity_credit_account::text as ref, 'ar' as table FROM ar
                UNION select id, entity_credit_account::text,        'ap' as table FROM ap
                UNION select id, reference, 'gl' as table FROM gl) gl
                        ON (gl.table = t.table_name AND gl.id = t.id)
                LEFT JOIN cr_report_line rl ON (rl.report_id = in_report_id
                        AND ((rl.ledger_id = ac.entry_id
                                AND ac.voucher_id IS NULL)
                                OR (rl.voucher_id = ac.voucher_id)) and rl.cleared is true)
                WHERE ac.cleared IS FALSE
                        AND ac.chart_id = (select chart_id from cr_report where id = in_report_id)
                GROUP BY gl.ref, ac.source, ac.transdate,
                        ac.memo, ac.voucher_id, gl.table
                HAVING count(rl.report_id) > 0) a
        LOOP
                ac_entries := ac_entries || current_row.entries;
        END LOOP;

        UPDATE acc_trans SET cleared = TRUE
        WHERE entry_id = any(ac_entries);

        return 1;
    END;

$$ language 'plpgsql' security definer;

COMMENT ON  FUNCTION reconciliation__report_approve (in_report_id INT) IS
$$Marks the report approved and marks all cleared transactions in it cleared.$$;


-- XXX Badly named, rename for 1.4.  --CT
CREATE OR REPLACE FUNCTION reconciliation__new_report_id
(in_chart_id int, in_total numeric, in_end_date date, in_recon_fx bool) returns INT as $$

    INSERT INTO cr_report(chart_id, their_total, end_date, recon_fx)
    values ($1, $2, $3, $4);
    SELECT currval('cr_report_id_seq')::int;

$$ language 'sql';

COMMENT ON FUNCTION reconciliation__new_report_id
(in_chart_id int, in_total numeric, in_end_date date, in_recon_fx bool)  IS
$$ Inserts creates a new report and returns the id.$$;

CREATE OR REPLACE FUNCTION reconciliation__add_entry(
    in_report_id INT,
    in_scn TEXT,
    in_type TEXT,
    in_date TIMESTAMP,
    in_amount numeric
) RETURNS INT AS $$

    DECLARE
        in_account int;
        la RECORD;
        t_errorcode INT;
        our_value NUMERIC;
        lid INT;
        in_count int;
        t_scn TEXT;
        t_uid int;
        t_prefix text;
        t_amount numeric;
    BEGIN
        SELECT CASE WHEN a.category in ('A', 'E') THEN in_amount * -1
                                                  ELSE in_amount
               END into t_amount
          FROM cr_report r JOIN account a ON r.chart_id = a.id
         WHERE r.id = in_report_id;

        SELECT value into t_prefix FROM defaults WHERE setting_key = 'check_prefix';

        t_uid := person__get_my_entity_id();
        IF t_uid IS NULL THEN
                t_uid = robot__get_my_entity_id();
        END IF;
        IF in_scn = '' THEN
                t_scn := NULL;
        ELSIF in_scn !~ '^[0-9]+$' THEN
                t_scn := in_scn;
        ELSE
                t_scn := t_prefix || in_scn;
        END IF;
        IF t_scn IS NOT NULL THEN
                -- could this be changed to update, if not found insert?
                SELECT count(*) INTO in_count FROM cr_report_line
                WHERE scn ilike t_scn AND report_id = in_report_id
                        AND their_balance = 0 AND post_date = in_date;

                IF in_count = 0 THEN
                        -- YLA - Where does our_balance comes from?
                        INSERT INTO cr_report_line
                        (report_id, scn, their_balance, our_balance, clear_time,
                                "user", trans_type)
                        VALUES
                        (in_report_id, t_scn, t_amount, 0, in_date, t_uid,
                                in_type)
                        RETURNING id INTO lid;
                ELSIF in_count = 1 THEN
                        SELECT id INTO lid
                        WHERE t_scn = scn AND report_id = in_report_id
                                AND their_balance = 0 AND post_date = in_date;
                        UPDATE cr_report_line
                        SET their_balance = t_amount, clear_time = in_date,
                                cleared = true
                        WHERE id = lid;
                ELSE
                        SELECT count(*) INTO in_count FROM cr_report_line
                        WHERE t_scn ilike scn AND report_id = in_report_id
                                AND our_value = t_amount and their_balance = 0
                                AND post_date = in_date;

                        IF in_count = 0 THEN -- no match among many of values
                                SELECT id INTO lid FROM cr_report_line
                                WHERE t_scn ilike scn
                                      AND report_id = in_report_id
                                      AND post_date = in_date
                                ORDER BY our_balance ASC limit 1;

                                UPDATE cr_report_line
                                SET their_balance = t_amount,
                                        clear_time = in_date,
                                        trans_type = in_type,
                                        cleared = true
                                WHERE id = lid;

                        ELSIF in_count = 1 THEN -- EXECT MATCH
                                SELECT id INTO lid FROM cr_report_line
                                WHERE t_scn = scn AND report_id = in_report_id
                                        AND our_value = t_amount
                                        AND their_balance = 0
                                        AND post_date = in_date;
                                UPDATE cr_report_line
                                SET their_balance = t_amount,
                                        trans_type = in_type,
                                        clear_time = in_date,
                                        cleared = true
                                WHERE id = lid;
                        ELSE -- More than one match
                                SELECT id INTO lid FROM cr_report_line
                                WHERE t_scn ilike scn AND report_id = in_report_id
                                        AND our_value = t_amount
                                        AND post_date = in_date
                                ORDER BY id ASC limit 1;

                                UPDATE cr_report_line
                                SET their_balance = t_amount,
                                        trans_type = in_type,
                                        cleared = true,
                                        clear_time = in_date
                                WHERE id = lid;

                        END IF;
                END IF;
        ELSE -- scn IS NULL, check on amount instead
                SELECT count(*) INTO in_count FROM cr_report_line
                WHERE report_id = in_report_id AND our_balance = t_amount
                        AND their_balance = 0 AND post_date = in_date
                        and scn NOT LIKE t_prefix || '%';

                IF in_count = 0 THEN -- no match
                        INSERT INTO cr_report_line
                        (report_id, scn, their_balance, our_balance, clear_time,
                        "user", trans_type)
                        VALUES
                        (in_report_id, t_scn, t_amount, 0, in_date, t_uid,
                        in_type)
                        RETURNING id INTO lid;
                ELSIF in_count = 1 THEN -- perfect match
                        SELECT id INTO lid
                        WHERE report_id = in_report_id
                                AND our_balance = t_amount
                                AND their_balance = 0
                                AND post_date = in_date
                                AND in_scn NOT LIKE t_prefix || '%';
                        UPDATE cr_report_line SET their_balance = t_amount,
                                        trans_type = in_type,
                                        clear_time = in_date,
                                        cleared = true
                        WHERE id = lid;
                ELSE -- more than one match
                        SELECT min(id) INTO lid FROM cr_report_line
                        WHERE report_id = in_report_id AND our_balance = t_amount
                                AND their_balance = 0 AND post_date = in_date
                                AND scn NOT LIKE t_prefix || '%'
                        LIMIT 1;

                        UPDATE cr_report_line SET their_balance = t_amount,
                                        trans_type = in_type,
                                        clear_time = in_date,
                                        cleared = true
                        WHERE id = lid;

                END IF;
        END IF;
        return lid;

    END;
$$ language 'plpgsql';

comment on function reconciliation__add_entry(
    in_report_id INT,
    in_scn TEXT,
    in_type TEXT,
    in_date TIMESTAMP,
    in_amount numeric
)  IS
$$
This function is used for automatically matching entries from an external source
like a bank-produced csv file.

This function is very sensitive to ordering of inputs.  NULL or empty in_scn values MUST be submitted after meaningful scns.  It is also highly recommended
that within each category, one submits in order of amount.  We should therefore
wrap it in another function which can operate on a set, perhaps in 1.4....
It returns the ID of the inserted/updated entry$$;


DROP FUNCTION IF EXISTS
  reconciliation__pending_transactions(in_end_date date,
                                       in_chart_id integer,
                                       in_report_id integer,
                                       in_their_total numeric);
CREATE OR REPLACE FUNCTION reconciliation__pending_transactions(
                      in_report_id integer, in_their_total numeric)
  RETURNS integer AS
$$

    DECLARE
        gl_row RECORD;
        t_recon_fx BOOL;
        t_chart_id integer;
        t_end_date date;
    BEGIN
       SELECT end_date, recon_fx, chart_id
         INTO t_end_date, t_recon_fx, t_chart_id
         FROM cr_report
        WHERE id = in_report_id;

        INSERT INTO cr_report_line (report_id, scn, their_balance,
                our_balance, "user", voucher_id, ledger_id, post_date)
        SELECT in_report_id,
               CASE WHEN ac.source IS NULL OR ac.source = ''
                    THEN gl.ref
                    ELSE ac.source END,
               0,
               sum(amount / CASE WHEN t_recon_fx IS NOT TRUE OR gl.table = 'gl'
                                 THEN 1
                                 WHEN t_recon_fx and gl.table = 'ap'
                                 THEN ex.sell
                                 WHEN t_recon_fx and gl.table = 'ar'
                                 THEN ex.buy
                            END) AS amount,
                        (select entity_id from users
                        where username = CURRENT_USER),
                ac.voucher_id, min(ac.entry_id), ac.transdate
        FROM acc_trans ac
        JOIN transactions t on (ac.trans_id = t.id)
        JOIN (select id, entity_credit_account::text as ref, curr,
                     transdate, 'ar' as table
                FROM ar where approved
                UNION
              select id, entity_credit_account::text, curr,
                     transdate, 'ap' as table
                FROM ap WHERE approved
                UNION
              select id, reference, '',
                     transdate, 'gl' as table
                FROM gl WHERE approved) gl
                ON (gl.table = t.table_name AND gl.id = t.id)
        LEFT JOIN cr_report_line rl ON (rl.report_id = in_report_id
                AND ((rl.ledger_id = ac.entry_id
                        AND ac.voucher_id IS NULL)
                        OR (rl.voucher_id = ac.voucher_id)))
        LEFT JOIN cr_report r ON r.id = in_report_id
        LEFT JOIN exchangerate ex ON gl.transdate = ex.transdate
        WHERE ac.cleared IS FALSE
                AND ac.approved IS TRUE
                AND ac.chart_id = t_chart_id
                AND ac.transdate <= t_end_date
                AND (t_recon_fx is not true
                     OR (t_recon_fx is true
                         AND (gl.table <> 'gl'
                              OR ac.fx_transaction IS TRUE)))
                AND (ac.entry_id > coalesce(r.max_ac_id, 0))
        GROUP BY gl.ref, ac.source, ac.transdate,
                ac.memo, ac.voucher_id, gl.table,
                case when gl.table = 'gl' then gl.id else 1 end
        HAVING count(rl.id) = 0;

        UPDATE cr_report set updated = date_trunc('second', now()),
                their_total = coalesce(in_their_total, their_total),
                max_ac_id = (select max(entry_id) from acc_trans)
        where id = in_report_id;

    RETURN in_report_id;
    END;
$$
  LANGUAGE plpgsql;

COMMENT ON function reconciliation__pending_transactions
  (in_report_id int, in_their_total numeric) IS
$$Ensures that the list of pending transactions in the report is up to date. $$;

CREATE OR REPLACE FUNCTION reconciliation__report_details (in_report_id INT) RETURNS setof cr_report_line as $$

                select * from cr_report_line where report_id = in_report_id
                order by scn, post_date
$$ language 'sql';

COMMENT ON FUNCTION reconciliation__report_details (in_report_id INT) IS
$$ Returns the details of the report. $$;

CREATE OR REPLACE FUNCTION reconciliation__report_summary (in_report_id INT) RETURNS cr_report as $$
        select * from cr_report where id = in_report_id;
$$ language 'sql';

CREATE OR REPLACE FUNCTION reconciliation__search
(in_date_from date, in_date_to date,
        in_balance_from numeric, in_balance_to numeric,
        in_account_id int, in_submitted bool, in_approved bool)
returns setof cr_report AS
$$
                SELECT r.* FROM cr_report r
                JOIN account c ON (r.chart_id = c.id)
                WHERE
                        (in_date_from IS NULL OR in_date_from <= end_date) and
                        (in_date_to IS NULL OR in_date_to >= end_date) AND
                        (in_balance_from IS NULL
                                or in_balance_from <= their_total ) AND
                        (in_balance_to IS NULL
                                OR in_balance_to >= their_total) AND
                        (in_account_id IS NULL OR in_account_id = chart_id) AND
                        (in_submitted IS NULL or in_submitted = submitted) AND
                        (in_approved IS NULL OR in_approved = approved) AND
                        (r.deleted IS FALSE)
                ORDER BY c.accno, end_date, their_total
$$ language sql;

COMMENT ON FUNCTION reconciliation__search
(in_date_from date, in_date_to date,
        in_balance_from numeric, in_balance_to numeric,
        in_chart_id int, in_submitted bool, in_approved bool) IS
$$ Searches for reconciliation reports.
NULLs match all values.
in_date_to and in_date_from give a range of reports.  All other inputs are
exact matches.
$$;

CREATE OR REPLACE FUNCTION reconciliation__previous_report_date
(in_chart_id int, in_end_date DATE)
returns setof cr_report AS
$$
                SELECT r.* FROM cr_report r
                  JOIN account c ON r.chart_id = c.id
                 WHERE in_end_date > end_date
                   AND in_chart_id = chart_id
                   AND submitted
                   AND NOT r.deleted
                 ORDER BY end_date DESC
                 LIMIT 1
$$ language sql;

COMMENT ON FUNCTION reconciliation__previous_report_date
(in_chart_id int, in_end_date DATE) IS
$$ Returns the submitted reconciliation report before in_end_date
for the in_chart_id account
$$;

DROP TYPE IF EXISTS recon_accounts CASCADE;

create type recon_accounts as (
    name text,
    accno text,
    id int
);

create or replace function reconciliation__account_list () returns setof recon_accounts as $$
    SELECT DISTINCT
        coa.accno || ' ' || coa.description as name,
        coa.accno, coa.id as id
    FROM account coa
         JOIN cr_coa_to_account cta ON cta.chart_id = coa.id
    ORDER BY coa.accno;
$$ language sql;

COMMENT ON function reconciliation__account_list () IS
$$ returns set of accounts set up for reconciliation.  Currently we pull the
account number and description from the account table.$$;

CREATE OR REPLACE FUNCTION reconciliation__get_current_balance
(in_account_id int, in_date date) returns numeric as
$$
        SELECT CASE WHEN (select category FROM account WHERE id = in_account_id)
                        IN ('A', 'E') THEN sum(a.amount) * -1
                ELSE sum(a.amount) END
        FROM acc_trans a
        JOIN (
                SELECT id FROM ar
                WHERE approved is true
                UNION
                SELECT id FROM ap
                WHERE approved is true
                UNION
                SELECT id FROM gl
                WHERE approved is true
        ) gl ON a.trans_id = gl.id
        WHERE a.approved IS TRUE
                AND a.chart_id = in_account_id
                AND a.transdate <= in_date;

$$ language sql;

COMMENT ON FUNCTION reconciliation__get_current_balance
(in_account_id int, in_date date) IS
$$ Gets the current balance of all approved transactions against a specific
account.  For asset and expense accounts this is the debit balance, for others
this is the credit balance.$$;

CREATE OR REPLACE VIEW recon_payee AS
 SELECT n.name AS payee, rr.id, rr.report_id, rr.scn, rr.their_balance, rr.our_balance, rr.errorcode, rr."user", rr.clear_time, rr.insert_time, rr.trans_type, rr.post_date, rr.ledger_id, ac.voucher_id, rr.overlook, rr.cleared
   FROM cr_report_line rr
   LEFT JOIN acc_trans ac ON rr.ledger_id = ac.entry_id
   LEFT JOIN gl ON ac.trans_id = gl.id
   LEFT JOIN (( SELECT ap.id, e.name
   FROM ap
   JOIN entity_credit_account eca ON ap.entity_credit_account = eca.id
   JOIN entity e ON eca.entity_id = e.id
UNION
 SELECT ar.id, e.name
   FROM ar
   JOIN entity_credit_account eca ON ar.entity_credit_account = eca.id
   JOIN entity e ON eca.entity_id = e.id)
UNION
 SELECT gl.id, gl.description
   FROM gl) n ON n.id = ac.trans_id;

CREATE OR REPLACE FUNCTION reconciliation__report_details_payee (in_report_id INT) RETURNS setof recon_payee as $$
                select * from recon_payee where report_id = in_report_id
                order by scn, post_date
$$ language 'sql';

DROP TYPE IF EXISTS recon_payee_days CASCADE;
CREATE TYPE recon_payee_days AS (
        id BIGINT,
        days INT
);
CREATE OR REPLACE FUNCTION reconciliation__report_details_payee_with_days (
        in_report_id INT, in_end_date DATE DEFAULT NULL)
RETURNS setof recon_payee_days AS $$
BEGIN
            RETURN QUERY
                SELECT rp.id,
                        CASE WHEN in_end_date IS NULL THEN NULL
                        ELSE      in_end_date - clear_time
                        END AS d
                FROM recon_payee rp
                WHERE rp.report_id = in_report_id;

RETURN;
END;$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION reconciliation__report_details_payee_with_days (in_report_id INT,in_end_date DATE) IS
$$ Pulls the payee information for the reconciliation report.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
