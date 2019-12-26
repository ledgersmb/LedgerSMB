

DO  language plpgsql $migrate$
DECLARE
  v_first_fx date;
  r record;
BEGIN
  SELECT min(transdate) INTO v_first_fx
    FROM acc_trans WHERE curr <> (select value from defaults
                                   where setting_key = 'curr');

  -- take the quick and easy way out
  UPDATE account_checkpoint
     SET amount_bc = amount,
         amount_tc = amount,
         curr = (select value from defaults where setting_key = 'curr')
   WHERE v_first_fx IS NULL
         OR end_date < v_first_fx;

  IF NOT v_first_fx IS NULL THEN
    -- all checkpoints after the first fx transaction need to be recalculate,
    -- for those accounts involved in the fx transactions
    CREATE TEMPORARY TABLE cp_to_recalculate AS
    SELECT DISTINCT end_date as cp_date
      FROM account_checkpoint ac
     WHERE ac.end_date >= v_first_fx;

    DELETE FROM account_checkpoint ac
     WHERE end_date >= v_first_fx;


    FOR r IN
       SELECT *
         FROM cp_to_recalculate
        ORDER BY cp_date
    LOOP
      DECLARE
        cp_date date;
      BEGIN
        SELECT max(end_date) INTO cp_date
          FROM account_checkpoint
         WHERE end_date < r.cp_date;

        INSERT INTO
        account_checkpoint (end_date, account_id, amount_bc,
                            amount_tc, curr, debits, credits)
        SELECT r.cp_date, account.id,
            COALESCE(SUM (a.amount_bc),0) + coalesce(MAX (cp.amount_bc), 0),
            COALESCE(SUM (a.amount_tc),0) + coalesce(MAX (cp.amount_tc), 0),
            COALESCE(a.curr, cp.curr, (select value from defaults
                                        where setting_key = 'curr')),
            COALESCE(SUM (CASE WHEN (a.amount_bc < 0) THEN a.amount_bc
                               ELSE 0 END), 0)
            + COALESCE(MIN (cp.debits), 0),
            COALESCE(SUM (CASE WHEN (a.amount_bc > 0) THEN a.amount_bc
                               ELSE 0 END), 0)
            + COALESCE( MAX (cp.credits), 0)
        FROM
        (SELECT sum(amount_bc) as amount_bc,
                sum(amount_tc) as amount_tc,
                curr, chart_id
           FROM acc_trans
          WHERE transdate <= r.cp_date
                AND transdate > COALESCE(cp_date, '1200-01-01')
          GROUP BY curr, chart_id) a
        FULL OUTER JOIN (
                select account_id, end_date, amount_bc, curr, amount_tc,
                       debits, credits
                from account_checkpoint
                WHERE end_date = cp_date
                ) cp on (a.chart_id = cp.account_id) and (a.curr = cp.curr)
        RIGHT JOIN account ON account.id = a.chart_id
                              or account.id = cp.account_id
        group by COALESCE(a.curr, cp.curr, (select value from defaults
                                        where setting_key = 'curr')),
                 account.id;
      END;
    END LOOP;
  END IF;
END;
$migrate$;


