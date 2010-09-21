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
	JOIN (
		select id, approved, transdate FROM ar UNION
		SELECT id, approved, transdate FROM gl UNION
		SELECT id, approved, transdate FROM ap
	) gl ON (gl.id = ac.trans_id)
	WHERE (ac.approved IS NOT TRUE AND ac.transdate <= in_end_date) 
		OR (gl.approved IS NOT TRUE AND gl.transdate <= in_end_date);

	if approval_check > 0 THEN
		RAISE EXCEPTION 'Unapproved transactions in closed period';
	END IF;
	
	SELECT max(end_date) INTO cp_date FROM account_checkpoint WHERE
	end_date < in_end_date;

	INSERT INTO 
	account_checkpoint (end_date, account_id, amount, debits, credits)
    SELECT in_end_date, COALESCE(a.chart_id, cp.account_id),
	    COALESCE(SUM (a.amount),0) + coalesce(MAX (cp.amount), 0),
	    COALESCE(SUM (CASE WHEN (a.amount < 0) THEN a.amount ELSE 0 END), 0) +
	     COALESCE( MIN (cp.debits), 0),
	    COALESCE(SUM (CASE WHEN (a.amount > 0) THEN a.amount ELSE 0 END), 0) +
	     COALESCE( MAX (cp.credits), 0)
	FROM 
	(SELECT * FROM acc_trans WHERE transdate <= in_end_date AND
	 transdate > COALESCE(cp_date, '1900-01-01')) a
	FULL OUTER JOIN (
		select account_id, end_date, amount, debits, credits 
		from account_checkpoint
		WHERE end_date = cp_date
		) cp on (a.chart_id = cp.account_id)
	group by COALESCE(a.chart_id, cp.account_id);

	SELECT count(*) INTO ret_val FROM account_checkpoint 
	where end_date = in_end_date;

	return ret_val;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION eoy_zero_accounts
(in_end_date date, in_reference text, in_description text, 
in_retention_acc_id int)
RETURNS int AS
$$
DECLARE ret_val int;
BEGIN
	INSERT INTO gl (transdate, reference, description, approved)
	VALUES (in_end_date, in_reference, in_description, true);

	INSERT INTO yearend (trans_id, transdate) values (currval('id'), in_end_date);
	INSERT INTO acc_trans (transdate, chart_id, trans_id, amount)
	SELECT in_end_date, a.chart_id, currval('id'),
		(sum(a.amount) + coalesce(max(cp.amount), 0)) * -1
	FROM acc_trans a
	LEFT JOIN (
		select account_id, end_date, amount from account_checkpoint
		WHERE end_date = (select max(end_date) from account_checkpoint
				where end_date < in_end_date)
		) cp on (a.chart_id = cp.account_id)
	JOIN account acc ON (acc.id = a.chart_id)
	WHERE a.transdate <= in_end_date 
		AND a.transdate > coalesce(cp.end_date, a.transdate - 1)
		AND acc.category IN ('I', 'E')
	GROUP BY a.chart_id;

	INSERT INTO acc_trans (transdate, trans_id, chart_id, amount)
	SELECT in_end_date, currval('id'), in_retention_acc_id, 
		coalesce(sum(amount) * -1, 0)
	FROM acc_trans WHERE trans_id = currval('id');


	SELECT count(*) INTO ret_val from acc_trans 
	where trans_id = currval('id');

	RETURN ret_val;
end;
$$ language plpgsql;

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

CREATE OR REPLACE FUNCTION eoy_reopen_books(in_end_date date)
RETURNS bool AS
$$
BEGIN
	PERFORM count(*) FROM account_checkpoint WHERE end_date = in_end_date;

	IF NOT FOUND THEN
		RETURN FALSE;
	END IF;

	DELETE FROM account_checkpoint WHERE end_date = in_end_date;

	PERFORM count(*) FROM yearend 
	WHERE transdate = in_end_date and reversed is not true;

	IF FOUND THEN
		INSERT INTO gl (reference, description, approved)
		SELECT 'Reversing ' || reference, 'Reversing ' || description,
			true
		FROM gl WHERE id = (select trans_id from yearend 
			where transdate = in_end_date and reversed is not true);

		INSERT INTO acc_trans (chart_id, amount, transdate, trans_id,
			approved)
		SELECT chart_id, amount * -1, currval('id'), true
		FROM acc_trans where trans_id = (select trans_id from yearend
			where transdate = in_end_date and reversed is not true);

		UPDATE yearend SET reversed = true where transdate = in_end_date
			and reversed is not true;
	END IF;

	DELETE FROM account_checkpoint WHERE end_date = in_end_date;
	RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION account__obtain_balance
(in_transdate date, in_account_id int)
RETURNS numeric AS
$$
DECLARE balance numeric;
BEGIN
	SELECT coalesce(sum(ac.amount) + cp.amount, sum(ac.amount))
	INTO balance
	FROM acc_trans ac
	JOIN (select id, approved from ar union
		select id, approved from ap union
		select id, approved from gl) a ON (a.id = ac.trans_id)
	LEFT JOIN (select account_id, end_date, amount from account_checkpoint
		WHERE account_id = in_account_id AND end_date < in_transdate
		ORDER BY end_date desc limit 1
	) cp ON (cp.account_id = ac.chart_id)
	WHERE ac.chart_id = in_account_id 
		AND ac.transdate > coalesce(cp.end_date, ac.transdate - '1 day'::interval)
		and ac.approved and a.approved
		and ac.transdate <= in_transdate
	GROUP BY cp.amount, ac.chart_id;

	RETURN balance;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION eoy_earnings_accounts() RETURNS setof account AS 
$$
    SELECT * 
      FROM account
     WHERE category = 'Q'
     ORDER BY accno;
$$ language sql;
