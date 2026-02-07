
set client_min_messages = 'warning';


BEGIN;

CREATE OR REPLACE FUNCTION eoy__latest_checkpoint() RETURNS account_checkpoint
LANGUAGE SQL AS
$$
   SELECT * FROM account_checkpoint ORDER BY end_date DESC LIMIT 1;
$$;

COMMENT ON FUNCTION eoy__latest_checkpoint() IS $$
This returns a single checkpoint from the latest set.  Which account and info
is returned is non-determinative and so only the end date shoudl be relied on.
$$;

CREATE OR REPLACE FUNCTION eoy_create_checkpoint(in_end_date date)
RETURNS int AS
$$
DECLARE ret_val int;
        approval_check int;
        cp_date        date;
BEGIN
        IF in_end_date > now()::date THEN
                RAISE EXCEPTION 'Invalid date:  Must be earlier than present';
        END IF;

        SELECT count(*) into approval_check
        FROM acc_trans ac
        JOIN transactions txn
             ON txn.id = ac.trans_id
        WHERE (ac.approved IS NOT TRUE AND ac.transdate <= in_end_date)
                OR (txn.approved IS NOT TRUE AND txn.transdate <= in_end_date);

        if approval_check > 0 THEN
                RAISE EXCEPTION 'Unapproved transactions in closed period';
        END IF;

        SELECT coalesce(max(end_date),(select min(transdate)-1
                                         from acc_trans)) INTO cp_date
          FROM account_checkpoint
         WHERE end_date < in_end_date;

        INSERT INTO account_checkpoint (
              end_date, account_id, amount_bc,
              amount_tc, curr, debits, credits)
        SELECT in_end_date, account.id,
            COALESCE(a.amount_bc,0) + COALESCE(cp.amount_bc, 0),
            COALESCE(a.amount_tc,0) + COALESCE(cp.amount_tc, 0),
            COALESCE(a.curr, cp.curr, defaults_get_defaultcurrency()),
            COALESCE(a.debits, 0) + COALESCE(cp.debits, 0),
            COALESCE(a.credits, 0) + COALESCE(cp.credits, 0)
        FROM (SELECT
                chart_id, curr,
                SUM(amount_bc) as amount_bc,
                SUM(amount_tc) as amount_tc,
                SUM(CASE WHEN (amount_bc < 0) THEN amount_bc
                                           ELSE 0 END) as debits,
                SUM(CASE WHEN (amount_bc > 0) THEN amount_bc
                                           ELSE 0 END) as credits
                  FROM acc_trans
                 WHERE transdate <= in_end_date
                       AND transdate > cp_date
                 GROUP BY chart_id, curr) a
        FULL OUTER JOIN (
              SELECT account_id, curr,
                     end_date, amount_bc, amount_tc, debits, credits
                FROM account_checkpoint
                WHERE end_date = cp_date) cp
           ON (a.chart_id = cp.account_id) and (a.curr = cp.curr)
        RIGHT JOIN account
           ON account.id = a.chart_id
              OR account.id = cp.account_id;

        SELECT count(*) INTO ret_val FROM account_checkpoint
        where end_date = in_end_date;

        return ret_val;
END;
$$ language plpgsql;

COMMENT ON FUNCTION eoy_create_checkpoint(in_end_date date) IS
$$Creates checkpoints for each account at a specific date.  Books are considered
closed when they occur before the latest checkpoint timewise.  This means that
balances (and credit/debit amounts) can be calculated starting at a checkpoint
and moving forward (thus providing a mechanism for expunging old data while
keeping balances correct at some future point).$$;

CREATE OR REPLACE FUNCTION eoy_zero_accounts
(in_end_date date, in_reference text, in_description text,
in_retention_acc_id int)
RETURNS int AS
$$
DECLARE
   ret_val int;
   cp_date date;
BEGIN
        INSERT INTO transactions (id, transdate, reference, description, approved,
                        trans_type_code, table_name)
        VALUES (nextval('id'), in_end_date, in_reference, in_description, true, 'ye', 'yearend');

        INSERT INTO yearend (trans_id, transdate)
             VALUES (currval('id'), in_end_date);

        SELECT coalesce(max(end_date),
                        (SELECT min(transdate)-1 FROM acc_trans)) INTO cp_date
          FROM account_checkpoint;

        INSERT INTO acc_trans (transdate, chart_id, trans_id,
                               amount_bc, curr, amount_tc)
        SELECT in_end_date, a.chart_id, currval('id'),
               (coalesce(a.amount_bc, 0) + coalesce(cp.amount_bc, 0)) * -1,
               coalesce(a.curr,cp.curr),
               (coalesce(a.amount_tc, 0) + coalesce(cp.amount_tc, 0)) * -1
        FROM (SELECT chart_id, sum(amount_bc) as amount_bc, curr,
                     sum(amount_tc) as amount_tc
                FROM acc_trans a
        JOIN account acc ON (acc.id = a.chart_id)
               WHERE transdate <= in_end_date
                     AND transdate > cp_date
                AND (acc.category IN ('I', 'E')
                      OR acc.category = 'Q' AND acc.is_temp)
               GROUP BY chart_id, curr) a
        LEFT JOIN (
                SELECT account_id, end_date, amount_bc, curr, amount_tc
                  FROM account_checkpoint
                 WHERE end_date = (select max(end_date) from account_checkpoint
                                    where end_date < in_end_date)
                ) cp
           ON (a.chart_id = cp.account_id) AND a.curr = cp.curr;

        INSERT INTO acc_trans (transdate, trans_id, chart_id,
                               amount_bc, curr, amount_tc)
        SELECT in_end_date, currval('id'), in_retention_acc_id,
               coalesce(sum(amount_bc) * -1, 0),
               -- post only default currency in retained earnings
               defaults_get_defaultcurrency(),
               coalesce(sum(amount_tc) * -1, 0)
        FROM acc_trans WHERE trans_id = currval('id');


        SELECT count(*) INTO ret_val from acc_trans
        where trans_id = currval('id');

        RETURN ret_val;
end;
$$ language plpgsql;

COMMENT ON FUNCTION eoy_zero_accounts
(in_end_date date, in_reference text, in_description text,
in_retention_acc_id int) IS
$$ Posts a transaction which zeroes the income and expense accounts, moving the
net balance there into a retained earnings account identified by
in_retention_acc_id.$$;

CREATE OR REPLACE FUNCTION eoy_close_books
(in_end_date date, in_reference text, in_description text,
in_retention_acc_id int)
RETURNS bool AS
$$
BEGIN
        IF eoy_zero_accounts(in_end_date, in_reference, in_description, in_retention_acc_id) > 0 THEN
                PERFORM eoy_create_checkpoint(in_end_date);
                RETURN TRUE;
        ELSE
                RETURN FALSE;
        END IF;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eoy_close_books
(in_end_date date, in_reference text, in_description text,
in_retention_acc_id int) IS
$$ Zeroes accounts and then creates a checkpoint. in_end_date is the date when
the books are to be closed, in_reference and in_description become the
reference and description of the transaction, and in_retention_acc_id is
the retained earnings account id.$$;

CREATE OR REPLACE FUNCTION eoy_reopen_books(in_end_date date)
RETURNS bool AS
$$
BEGIN
  PERFORM count(*) FROM account_checkpoint WHERE end_date = in_end_date;
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  PERFORM * FROM account_checkpoint WHERE end_date > in_end_date;
  IF FOUND THEN
    RAISE EXCEPTION 'Only last closed period can be reopened';
  END IF;

  DELETE FROM account_checkpoint WHERE end_date = in_end_date;

  PERFORM count(*) FROM yearend
    WHERE transdate = in_end_date and reversed is not true;

  IF FOUND THEN
    DECLARE
      t_new_trans_id int;
    BEGIN
      INSERT INTO transactions (transdate, reference, description, approved, trans_type_code)
      SELECT in_end_date, 'Reversing ' || reference, 'Reversing ' || description, true, 'ye'
        FROM transactions
       WHERE id = (select trans_id from yearend
                    where transdate = in_end_date
                      and reversed is not true)
             RETURNING id INTO t_new_trans_id;

      UPDATE transactions
         SET reversing = (select trans_id
                            from yearend
                           where transdate = in_end_date
                             and reversed is not true)
       WHERE id = t_new_trans_id;

      INSERT INTO acc_trans (chart_id, amount_bc, curr, amount_tc,
                             transdate, trans_id, approved)
      SELECT chart_id, amount_bc * -1, curr, amount_tc * -1,
             in_end_date, t_new_trans_id, true
        FROM acc_trans where trans_id = (select trans_id
                                           from yearend
                                          where transdate = in_end_date
                                            and reversed is not true);

      UPDATE yearend
         SET reversed = true
       where transdate = in_end_date
                        and reversed is not true;
    END;
  END IF;

  DELETE FROM account_checkpoint WHERE end_date = in_end_date;
  RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION eoy_reopen_books(in_end_date date) IS
$$ Removes checkpoints and reverses yearend transactions on in_end_date$$;

CREATE OR REPLACE FUNCTION eoy__reopen_books_at(in_reopen_date date)
RETURNS BOOL
LANGUAGE SQL AS
$$

  WITH eoy_dates AS (
      SELECT end_date
              FROM account_checkpoint
             WHERE end_date >= $1
             GROUP BY end_date
    ORDER BY end_date DESC
    )
    SELECT eoy_reopen_books(end_date)
      FROM eoy_dates;

SELECT CASE WHEN (SELECT count(*) > 0 from account_checkpoint
                   where end_date = $1 - 1)
            THEN true
            ELSE eoy_create_checkpoint($1 - 1) > 0
       END;

$$;

DROP TYPE IF EXISTS account__balance_by_currency CASCADE;
CREATE TYPE account__balance_by_currency AS (
  curr char(3),
  amount_bc numeric,
  amount_tc numeric
);

CREATE OR REPLACE FUNCTION account__obtain_balance_by_currency(
  in_transdate date,
  in_account_id int
) RETURNS setof account__balance_by_currency AS
$$
WITH cp AS (
  SELECT amount_bc, amount_tc, curr
    FROM account_checkpoint
   WHERE account_id = in_account_id
     AND end_date = (select max(end_date)
                       from account_checkpoint
                      where end_date <= in_transdate)
),
ac AS (
  SELECT sum(acc.amount_bc), sum(acc.amount_tc), curr
    FROM acc_trans acc
    JOIN (select id from transactions where approved) txn
        ON acc.trans_id = txn.id
   WHERE transdate <= in_transdate
     AND transdate > coalesce((select max(end_date)
                                 from account_checkpoint),
                              (select min(transdate) - '1 day'::interval
                                 from acc_trans))
     AND acc.chart_id = in_account_id
   GROUP BY curr
)
  SELECT curr,
         sum(amount_bc) as amount_bc,
         sum(amount_tc) as amount_tc
    FROM (
      SELECT * FROM cp
       UNION ALL
      SELECT * FROM ac
    ) x
  GROUP BY curr;
$$ language sql;

CREATE OR REPLACE FUNCTION account__obtain_balance
(in_transdate date, in_account_id int)
RETURNS numeric AS
$$
WITH cp AS (
  SELECT sum(amount_bc) as amount_bc, end_date, account_id
    FROM account_checkpoint
   WHERE account_id = in_account_id
     AND end_date = (select max(end_date)
                       from account_checkpoint
                      where end_date <= in_transdate)
   GROUP BY end_date, account_id
),
ac AS (
  SELECT acc_trans.amount_bc
    FROM acc_trans
    JOIN (select id from transactions where approved) a
          on acc_trans.trans_id = a.id
  LEFT JOIN cp ON acc_trans.chart_id = cp.account_id
   WHERE (cp.end_date IS NULL OR transdate > cp.end_date)
     AND transdate <= in_transdate
     AND chart_id = in_account_id)

 SELECT coalesce((select sum(amount)
                    from (select sum(amount_bc) as amount from cp
                          union all
                          select sum(amount_bc) from ac) as a),
                 0);
$$ LANGUAGE SQL;

COMMENT ON FUNCTION account__obtain_balance
(in_transdate date, in_account_id int) is
$$Returns the account balance at a given point in time, calculating forward
from most recent check point.  This function is inclusive of in_transdate.  For
an exclusive function see account__obtain_starting_balance below.$$;

CREATE OR REPLACE FUNCTION account__obtain_starting_balance
(in_transdate date, in_account_id int)
RETURNS numeric LANGUAGE SQL AS
$$
SELECT account__obtain_balance($1 - 1, $2);
$$;

CREATE OR REPLACE FUNCTION eoy_earnings_accounts() RETURNS setof account AS
$$
    SELECT *
      FROM account
     WHERE category = 'Q'
     ORDER BY accno;
$$ language sql;

COMMENT ON FUNCTION eoy_earnings_accounts() IS
$$ Lists equity accounts for the retained earnings dropdown.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
