
set client_min_messages = 'warning';

/*
The reconciliation reports have the following state transition diagram:


+----------+    +--------+    +------------+     +------------+
| Initial  +--->+ Saved  +--->+ Submitted  +-+-->+ Approved   |
+----------+    +-+------+    +------+-----+ |   +------------+
                  | ^                |       |
                  | \---Rejecting----/       |   +------------+
                  \-------------------------/ \->+ Deleted    |
                                                 +------------+

The state diagram is reflected in the various table columns as follows
(excluding the 'deleted' state, which has no rows in the database):

|------------------------------+---------+-------+-----------+----------|
| table column                 | initial | saved | submitted | approved |
|------------------------------+---------+-------+-----------+----------|
| cr_report.submitted          | false   | false | true      | true     |
| cr_report.approved           | false   | false | false     | true     |
| cr_report_line.cleared       | false   | t/f   | t/f       | t/f      |
| cr_report_line_links.cleared | false   | false | true (2)  | true (2) |
| acc_trans.cleared            | false   | false | false     | true (1) |
|------------------------------+---------+-------+-----------+----------|

(1): Only for those lines which have a corresponding cr_report_line_link
record which is also marked "cleared". Note that a reconciliation report
can have both cleared and uncleared lines in all states.

(2): For all rows where the cr_report_line.cleared column is marked "cleared".


The reasoning behind the difference in definition of the "cleared" column
between the cr_report_line, cr_report_line_link and acc_trans tables is as
follows:

 * cr_report_line.cleared indicates if the line on the report is considered
   to have cleared
 * cr_report_line_link.cleared indicates (the intention to mark) an acc_trans
   line as being cleared; the 'submitted' state comes with this intention
 * acc_trans.cleared indicates that the line actually has been cleared


|------------+-----------+--------------------------------------|
| From state | To state  | Function name                        |
|------------+-----------+--------------------------------------|
| <start>    | Initial   | reconciliation__new_report_id        |
| Initial    | Saved     | reconciliation__save_set             |
| Saved      | Submitted | reconciliation__submit_set           |
| Submitted  | Approved  | reconciliation__report_approve       |
| Submitted  | Saved     | reconciliation__reject_set           |
| Iniitial   | Deleted   | reconciliation__delete_unapproved    |
| Saved      | Deleted   | reconciliation__delete_unapproved    |
| Submitted  | Deleted   | reconciliation__delete_unapproved    |
| Initial    | Deleted   | reconciliation__delete_my_report     |
| Saved      | Deleted   | reconciliation__delete_my_report     |
| Initial    | Initial   | recenciliation__pending_transactions |
| Saved      | Saved     | recenciliation__pending_transactions |
| Initial    | Initial   | reconciliation__add_entry            |
| Saved      | Saved     | reconciliation__add_entry            |
|------------+-----------+--------------------------------------|





*/

BEGIN;

CREATE OR REPLACE FUNCTION cr_report_submitted_update()
RETURNS trigger
AS
$$
BEGIN
  UPDATE cr_report_line_links rll
     SET cleared = rl.cleared and NEW.submitted
    FROM cr_report_line rl
   WHERE rll.report_line_id = rl.id
         AND rl.report_id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION cr_report_line_cleared_update()
RETURNS trigger
AS
$$
BEGIN
  UPDATE cr_report_line_links rll
     SET cleared = NEW.cleared and r.submitted
    FROM cr_report r
   WHERE rll.report_line_id = NEW.id
         AND r.id = NEW.report_id;

  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION cr_report_line_link_insert()
RETURNS trigger
AS
$$
BEGIN
  NEW.cleared = (select r.submitted and rl.cleared
                   from cr_report_line rl
                   join cr_report r on rl.report_id = r.id
                  where rl.id = NEW.report_line_id);

  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- drop and create, because only Pg14+ support CREATE OR REPLACE
DROP TRIGGER IF EXISTS cr_report_links_update ON cr_report;
CREATE TRIGGER cr_report_links_update AFTER UPDATE OF submitted
    ON cr_report
    FOR EACH ROW
    EXECUTE PROCEDURE cr_report_submitted_update();

-- drop and create, because only Pg14+ support CREATE OR REPLACE
DROP TRIGGER IF EXISTS cr_report_line_links_update ON cr_report_line;
CREATE TRIGGER cr_report_line_links_update AFTER UPDATE OF cleared
    ON cr_report_line
    FOR EACH ROW
    EXECUTE PROCEDURE cr_report_line_cleared_update();

-- drop and create, because only Pg14+ support CREATE OR REPLACE
DROP TRIGGER IF EXISTS cr_report_line_link_insert ON cr_report_line_links;
CREATE TRIGGER cr_report_line_link_insert BEFORE INSERT
    ON cr_report_line_links
    FOR EACH ROW
    EXECUTE PROCEDURE cr_report_line_link_insert();

-- drop and recreate because of the signature change.
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

CREATE OR REPLACE FUNCTION reconciliation__check(in_end_date date, in_chart_id int)
RETURNS SETOF defaults
LANGUAGE SQL AS
$$
WITH unapproved_tx as (
     SELECT 'unapproved_transactions'::text, sum(c)::text
       FROM (SELECT count(*) as c FROM transactions
              WHERE approved IS FALSE AND transdate <= $1
      UNION  SELECT count(DISTINCT source) FROM acc_trans
              WHERE approved IS FALSE AND transdate <= $1 AND chart_id = $2
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

COMMENT ON FUNCTION reconciliation__check(date, int) IS
$$Checks whether there are unapproved transactions on or before the end date
and unapproved reports before the end date provided.

Note that the check for unapproved transactions should include the end date,
because having unapproved transactions on the end date influences the outcome
of the balance to be verified by a report.

Also note that the unapproved reports check can't include the end date,
because that would mean that if a report were in progress while this function
is being called, that report would be included in the count.
$$; -- '

CREATE OR REPLACE FUNCTION reconciliation__reject_set(in_report_id int)
RETURNS bool language sql as $$
     UPDATE cr_report set submitted = false
      WHERE id = in_report_id
            AND approved is not true
     RETURNING true;
$$ SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION reconciliation__reject_set(in_report_id int) FROM public;

COMMENT ON FUNCTION reconciliation__reject_set(in_report_id int) IS
$$Sets the reconciliation report identified by in_report_id as not approved,
providing it is not already submitted. Used in the reconciliation workflow
to reject approval.$$;

CREATE OR REPLACE FUNCTION reconciliation__save_set(
        in_report_id int, in_line_ids int[]) RETURNS bool AS
$$
        UPDATE cr_report_line SET cleared = (id = ANY(in_line_ids))
         WHERE report_id = in_report_id;

        SELECT TRUE;
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
DROP FUNCTION IF EXISTS reconciliation__get_cleared_balance(int,date);
CREATE OR REPLACE FUNCTION reconciliation__get_cleared_balance(
  in_chart_id int,
  in_report_date date DEFAULT date_trunc('second', now()),
  in_fx_balance boolean DEFAULT false
)
RETURNS numeric AS
$$
  SELECT CASE WHEN in_fx_balance THEN sum(ac.amount_tc)
         ELSE sum(ac.amount_bc)
         END * CASE WHEN c.category in('A', 'E') THEN -1 ELSE 1 END
    FROM account c
           JOIN acc_trans ac ON ac.chart_id = c.id
           JOIN transactions g ON g.id = ac.trans_id
   WHERE g.approved
     AND c.id = in_chart_id
     AND ac.approved
     -- cleared using a report on or before in_report_date:
     AND EXISTS (select 1
                   from cr_report cr
                          join cr_report_line crl on cr.id = crl.report_id
                          join cr_report_line_links crll on crl.id = crll.report_line_id
                  where cr.approved
                    and cr.chart_id = in_chart_id
                    and cr.end_date <= in_report_date
                    and crl.cleared
                    and crll.entry_id = ac.entry_id)
    GROUP BY c.id, c.category;
$$ LANGUAGE sql;

COMMENT ON FUNCTION reconciliation__get_cleared_balance(in_chart_id int,
                                                        in_report_date date,
                                                        in_fx_balance boolean) IS
$$ Gets the cleared balance of the account specified by chart_id, as cleared by reports
on and before in_report_date. Returns the foreign currency balance when 'in_fx_balance'
is true.

Please note that the cleared balance amount as at a sperific date may differ from the value
returned by this function, if transactions prior to in_report_date are cleared using reports
on a date later than in_report_date.

The returned value is specified in normal format (i.e. positive numbers for debits for asset
and expense accounts, and positive numbers for credits in other accounts.

Note that currently contra accounts will show negative balances.$$;

CREATE OR REPLACE FUNCTION reconciliation__report_approve (in_report_id INT) returns INT as $$

    BEGIN
        UPDATE cr_report SET approved = 't',
                approved_by = person__get_my_entity_id(),
                approved_username = SESSION_USER
         WHERE id = in_report_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No report at %.', $1;
        END IF;

        UPDATE acc_trans ac
           SET cleared = TRUE
         WHERE exists (select 1
                         from cr_report_line_links rll
                         join cr_report_line rl on rll.report_line_id = rl.id
                        where rll.entry_id = ac.entry_id
                              and rl.cleared
                              and rl.report_id = in_report_id);
        return 1;
    END;

$$ language 'plpgsql' security definer;

COMMENT ON  FUNCTION reconciliation__report_approve (in_report_id INT) IS
$$Marks the report approved and marks all cleared transactions in it cleared.$$;


DROP FUNCTION IF EXISTS reconciliation__new_report(
    in_chart_id int,
    in_total numeric,
    in_end_date date,
    in_recon_fx bool
);

CREATE OR REPLACE FUNCTION reconciliation__new_report(
    in_chart_id int,
    in_total numeric,
    in_end_date date,
    in_recon_fx bool,
    in_workflow_id bigint
) returns bigint as $$
    INSERT INTO cr_report(chart_id, their_total, end_date, recon_fx, workflow_id)
    values (in_chart_id, in_total, in_end_date, in_recon_fx, in_workflow_id)
    returning id;
$$ language 'sql';

COMMENT ON FUNCTION reconciliation__new_report
(in_chart_id int, in_total numeric, in_end_date date, in_recon_fx bool, in_workflow_id bigint)  IS
$$ Creates a new report and returns the id.$$;

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
                        SELECT id INTO lid FROM cr_report_line
                        WHERE t_scn = scn AND report_id = in_report_id
                                AND their_balance = 0 AND post_date = in_date;
                        UPDATE cr_report_line
                        SET their_balance = t_amount, clear_time = in_date,
                                cleared = true
                        WHERE id = lid;
                ELSE
                        SELECT count(*) INTO in_count FROM cr_report_line
                        WHERE t_scn ilike scn AND report_id = in_report_id
                                AND our_balance = t_amount and their_balance = 0
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
                                        AND our_balance = t_amount
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
                                        AND our_balance = t_amount
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
                        SELECT id INTO lid FROM cr_report_line
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
    in_report_id integer,
    in_their_total numeric
)
RETURNS integer AS
$$

    DECLARE
        t_row            record;
        t_recon_fx       BOOL;
        t_chart_id       integer;
        t_end_date       date;
        t_report_line_id integer;
        t_uid int;
    BEGIN
        SELECT end_date, recon_fx, chart_id
         INTO t_end_date, t_recon_fx, t_chart_id
         FROM cr_report
        WHERE id = in_report_id;

        SELECT entity_id INTO t_uid
        FROM users
        WHERE username = CURRENT_USER;

        /*

        Approach in 4 steps:
         1. Identify lines to be added *somewhere*
            That is: all lines before the reconcilation date which
            are not yet part of any other reconciliation; lines come
            from two sources: payment transactions and others (the second
            are usually GL transactions)
         2. Identify lines part of a payment
            Lines in this category are grouped by payment and added as a
            single reconciliation line, irrespective of the number of lines
            identified, *unless* lines have explicitly different 'Source'
            values - which is weird and unexpected, but possible when the
            user sets a specific value on each payment line separately - in
            which case, the lines in the payment will be grouped by the value
            of the Source field
         3. Identify non-payment lines that adjust payments
            When a payment has been entered wrongly or the bank has withheld
            transaction fees, the payment of the invoice does not correspond
            to the actual amount on the bank statement - meaning adjustment
            is required; GL transactions can be used to enter adjustments by
            listing the same date and the same source as used for the payment
            transaction. The lines in this category will be added as an
            adjustment to the existing (coming from the payment) reconciliation
            line
         4. Remaining lines added as new lines, either by source (if they
            have one) or as individual ones.
            Note that the lines in this category - by logical reasoning - can
            **not** be payments lines, because those were handled in step 2.
            Also note that it's not an option to lump all lines without a source
            into a single line, because that way all lines without a Source
            would end up as a single reconciliation line, while unknowing users
            are expected to post GL lines without Source numbers; to help these
            users, we present lines from non-payment (GL) transactions as
            individual lines
         */

        -- step 1: identify lines to be added somehow
        create temporary table lines_to_be_added as
        select entry_id, null::int as report_line_id
         from acc_trans ac
         join transactions tr on ac.trans_id = tr.id
         where tr.approved
               and ac.approved
               and not ac.cleared
               and ac.chart_id = t_chart_id
               and ac.transdate <= t_end_date
               and not exists (select 1 from cr_report_line_links rll
                                        join cr_report_line rl
                                          on rl.id = rll.report_line_id
                                where ac.entry_id = rll.entry_id
                                      and rl.report_id = in_report_id);

        -- step 2: add lines part of a payment one line per payment
        for t_row in
           select payment_id, array_agg(ac.entry_id) as entries,
                  sum(case when t_recon_fx then amount_tc
                           else amount_bc end) as our_balance,
                  payment_date, source
             from payment_links pl
             join acc_trans ac on pl.entry_id = ac.entry_id
             join payment p on p.id = pl.payment_id
            where ac.chart_id = t_chart_id
                  and pl.entry_id in (select entry_id from lines_to_be_added)
           group by payment_id, payment_date, source
        loop
            insert into cr_report_line (report_id, scn, their_balance,
                                       our_balance, post_date, "user")
            values (in_report_id, t_row.source, 0, t_row.our_balance, t_row.payment_date, t_uid)
           returning id into t_report_line_id;

           update lines_to_be_added
              set report_line_id = t_report_line_id
            where entry_id = any(t_row.entries);
        end loop;

        -- step 3: add new ledger lines to existing recon lines
        with matched_entries as (
           update lines_to_be_added la
              set report_line_id =
                     (select id
                        from cr_report_line rl
                        join acc_trans ac on ac.source = rl.scn
                                             and ac.transdate = rl.post_date
                       where la.entry_id = ac.entry_id
                             and rl.report_id = in_report_id
                             -- exclude 'scn' values associated with more than one
                             -- report line: the gl line can't be unambiguously
                             -- combined with a payment; hence it can't serve as
                             -- a correction...
                             and not exists (select 1 from cr_report_line rli
                                              where rl.post_date = rli.post_date
                                                    and rl.report_id = rli.report_id
                                                    and rli.scn = rl.scn
                                                    and rl.id <> rli.id)
                             and not exists (select 1 from payment_links pl
                                              where pl.entry_id = ac.entry_id))
            where la.report_line_id is null
           returning report_line_id, entry_id
        )
        update cr_report_line rl
           set our_balance = (select sum(case when t_recon_fx then ac.amount_tc
                                              else ac.amount_bc end)
                                from (
                                     -- lines that were already there
                                     select report_line_id, entry_id
                                       from cr_report_line_links
                                     union all
                                     -- lines identified in step (2)
                                     -- (does not include 'matched_entries', because
                                     -- the default transaction isolation [read
                                     -- committed] freezes our view at query start,
                                     -- which means lines_to_be_added isn't updated
                                     -- by 'matched_entries', as we see it)
                                     select report_line_id, entry_id
                                       from lines_to_be_added
                                     union all
                                     -- lines identidief in this step
                                     select report_line_id, entry_id
                                       from matched_entries
                                ) rll
                                join acc_trans ac on rll.entry_id = ac.entry_id
                                where rl.id = rll.report_line_id)
         where rl.id in (select report_line_id from matched_entries);

        -- step 4: add new lines not part of payments
        for t_row in
           select source, array_agg(entry_id) as entries,
                  sum(case when t_recon_fx then amount_tc
                           else amount_bc end) as our_balance,
                  transdate
             from acc_trans ac
            where ac.chart_id = t_chart_id
                  and ac.entry_id in (select entry_id from lines_to_be_added
                                       where report_line_id is null)
           group by source, transdate,
                    case when source is null then entry_id else null end
        loop
           insert into cr_report_line (report_id, scn, their_balance,
                                      our_balance, post_date, "user")
            values (in_report_id, t_row.source, 0,
                      t_row.our_balance, t_row.transdate, t_uid)
           returning id into t_report_line_id;

           update lines_to_be_added
              set report_line_id = t_report_line_id
            where entry_id = any(t_row.entries);
        end loop;

        perform * from lines_to_be_added where report_line_id is null;
        if found then
          drop table lines_to_be_added;
          raise exception 'Unhandled entries %', (select array_agg(entry_id) from lines_to_be_added where report_line_id is null)::int[];
        end if;

        insert into cr_report_line_links (report_line_id, entry_id)
        select report_line_id, entry_id from lines_to_be_added;

        drop table lines_to_be_added;

        UPDATE cr_report
           set updated = date_trunc('second', now()),
               their_total = coalesce(in_their_total, their_total)
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
                        IN ('A', 'E') THEN sum(a.amount_bc) * -1
                ELSE sum(a.amount_bc) END
        FROM acc_trans a
        JOIN transactions txn on a.trans_id = txn.id
             WHERE txn.approved IS TRUE
                AND a.approved IS TRUE
                AND a.chart_id = in_account_id
                AND a.transdate <= in_date;

$$ language sql;

COMMENT ON FUNCTION reconciliation__get_current_balance
(in_account_id int, in_date date) IS
$$ Gets the current balance of all approved transactions against a specific
account.  For asset and expense accounts this is the debit balance, for others
this is the credit balance.$$;

CREATE OR REPLACE VIEW recon_payee AS
 SELECT DISTINCT ON (rr.id)
      n.name AS payee, rr.id, rr.report_id, rr.scn, rr.their_balance,
      rr.our_balance, rr."user", rr.clear_time, rr.insert_time, rr.trans_type,
      rr.post_date, rr.cleared
   FROM cr_report_line rr
   LEFT JOIN cr_report_line_links rll ON rr.id = rll.report_line_id
   LEFT JOIN acc_trans ac ON rll.entry_id = ac.entry_id
   LEFT JOIN gl ON ac.trans_id = gl.id -- this is a bug? why join on GL when the fields aren't used above?
   LEFT JOIN (
     SELECT *
       FROM (
         SELECT ap.id, e.name
           FROM ap
                  JOIN entity_credit_account eca ON ap.entity_credit_account = eca.id
                  JOIN entity e ON eca.entity_id = e.id
          UNION
         SELECT ar.id, e.name
           FROM ar
                  JOIN entity_credit_account eca ON ar.entity_credit_account = eca.id
                  JOIN entity e ON eca.entity_id = e.id
       ) aa
      UNION
     SELECT txn.id, txn.description
       FROM gl
            JOIN transactions txn
                ON gl.id = txn.id
   ) n ON n.id = ac.trans_id;

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
