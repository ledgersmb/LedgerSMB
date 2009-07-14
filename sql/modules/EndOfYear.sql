CREATE OR REPLACE FUNCTION eoy_create_checkpoint(in_end_date date)
RETURNS int AS
$$
DECLARE ret_val int;
	approval_check int;
BEGIN
	IF end_date > now()::date THEN
		RAISE EXCEPTION 'Invalid date:  Must be earlier than present';
	END IF;

	SELECT count(*) into approval_check
	FROM acc_trans ac
	JOIN (
		select id, approved FROM ar UNION
		SELECT id, approved FROM gl UNION
		SELECT id, approved FROM ap) gl ON (gl.id = ac.trans_id)
	WHERE (ac.approved IS NOT TRUE AND ac.transdate <= in_end_date) 
		OR (gl.approved IS NOT TRUE AND gl.transdate <= in_end_date);

	if approval_check > 0 THEN
		RAISE EXCEPTION 'Unapproved transactions in closed period';
	END IF;

	INSERT INTO account_checkpoint (end_date, account_id, amount)
	SELECT in_end_date, a.chart_id, sum(a.amount) + coalesce(cp.amount, 0)
	FROM acc_trans a
	LEFT JOIN (
		select account_id, end_date, amount from account_checkpoint
		WHERE end_date = (select max(end_date) from account_checkpoint
				where end_date < in_end_date)
		) cp on (a.chrt_id = cp.account_id)
	WHERE a.transdate <= in_end_date 
		AND a.transdate > coalesce(cp.end_date, a.transdate);

	SELECT count(*) INTO ret_val FROM account_checkpoint 
	where end_date = in_end_date;

	return ret_val;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION eoy_zero_accounts
(in_end_date date, in_reference text, in_description text)
RETURNS int AS
$$
DECLARE ret_val int;
BEGIN
	INSERT INTO gl (transdate, reference, description, approved)
	VALUES (in_end_date, in_reference, in_description, true);

	INSERT INTO yearend (id, transdate) values (currval('id'), in_end_date);
	INSERT INTO acc_trans (trans_date, chart_id, amount)
	SELECT in_end_date, a.chart_id, 
		(sum(a.amount) + coalesce(cp.amount, 0)) * -1
	FROM acc_trans a
	LEFT JOIN (
		select account_id, end_date, amount from account_checkpoint
		WHERE end_date = (select max(end_date) from account_checkpoint
				where end_date < in_end_date)
		) cp on (a.chrt_id = cp.account_id)
	JOIN account acc ON (acc.id = a.chart_id)
	WHERE a.transdate <= in_end_date 
		AND a.transdate > coalesce(cp.end_date, a.transdate)
		AND acc.category IN ('I', 'E');


	SELECT count(*) INTO ret_val from acc_trans 
	where trans_id = currval('id');

	RETURN ret_val;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION eoy_close_books
(in_end_date date, in_reference text, in_description text)
RETURNS bool AS
$$
BEGIN
	IF eoy_zero_accounts(in_end_date, in_reference, in_description) > 0 THEN
		select eoy_create_checkpoints(in_end_date);
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
	PROCESS * FROM account_checkpoint WHERE end_date = in_end_date;

	IF NOT FOUND THEN
		RETURN FALSE;
	END IF;

	DELETE FROM account_checkpoint WHERE end_date = in_end_date;

	PROCESS * FROM yearend 
	WHERE transdate = in_end_date and reversed is not true

	IF FOUND THEN
		INSERT INTO gl (reference, description, approved)
		SELECT 'Reversing ' || reverence, 'Reversing ' || description,
			true
		FROM gl WHERE id = (select id from yearend 
			where transdate = in_end_date and reversed is not true);

		INSERT INTO acc_trans (chart_id, amount, transdate, trans_id,
			approved)
		SELECT chart_id, amount * -1, currval('id'), true
		FROM acc_trans where trans_id = (select id from yearend
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
DECLARE balance numeric
BEGIN
	SELECT amount INTO balance FROM account_checkpoint 
	WHERE account_id = in_account_id AND end_date < in_trans_date
	ORDER BY end_date desc LIMIT 1;

	SELECT sum(ac.amount) + coalesce(cp.balance, 0)
	INTO balance
	FROM acc_trans ac
	JOIN (select id, approved from ar union
		select id, approved from ap union
		select id, approved from gl) a ON (a.id = ac.trans_id)
	LEFT JOIN (select account_id, end_date, amount from account_checkpoint
		WHERE account_id = in_account_id AND end_date < in_transdate
		ORDER BY end_date desc limit 1
	) cp ON (cp.account_id = ac.chart_id)
	WHERE ac.chart_id = in_account_id AND acc_trans > cp.end_date
		and ac.approved and a.approved;

	RETURN balance
END;
$$ LANGUAGE PLPGSQL;
