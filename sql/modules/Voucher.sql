
CREATE OR REPLACE FUNCTION voucher_get_batch (in_batch_id integer) 
RETURNS batches AS 
$$
DECLARE
	batch_out batches%ROWTYPE;
BEGIN
	SELECT * INTO batch_out FROM batches b WHERE b.id = in_batch_id;
	RETURN batch_out;
END;
$$ language plpgsql;


CREATE TYPE batch_list AS (
id integer,
batch_number text,
description text,
entered date,
approved date,
amount numeric,
employee text,
manager text);

CREATE FUNCTION batch_search
(in_batch text, in_description text, in_batch_number text, in_date_from date,
	in_date_to date, in_date_include date, in_approved boolean) 
RETURNS SETOF batch_list
AS $$
DECLARE
	batch_out batch_list;
BEGIN
	FOR batch_out IN
	SELECT b.id, b.batch, b.batch_number, b.description,
                 b.entered, b.approved, b.amount,
                 e.name AS employee, m.name AS manager
	FROM batches b
	LEFT JOIN employees e ON (b.employee_id = e.id)
	LEFT JOIN employees m ON (b.managerid = m.id)
	WHERE supplied_and_equal(in_batch, b.batch)
		AND supplied_and_like(in_description, description)
		AND supplied_and_like(in_batch_number, batch_number)
		AND supplied_and_later(in_date_from, entered)
		AND supplied_and_earlier(in_date_to, entered)
		AND (coalesce(in_approved, 'f') = (approved IS NULL))

	LOOP
		RETURN NEXT batch_out;
	END LOOP;
END;
$$ language PLPGSQL;

CREATE FUNCTION batch_post (in_batch text, in_login varchar, in_entered date,
	in_batch_number text, in_description text, in_id integer) 
RETURNS integer AS
$$
BEGIN
	UPDATE batches
	SET batch_number = in_batch_number,
		description = in_description,
		entered = in_entered
	WHERE id = in_id;

	IF FOUND THEN 
		RETURN in_id;
	END IF;

	INSERT INTO batches (batch, employee_id, batch_number, description, 
		entered)
	VALUES (in_batch, (SELECT id FROM employees WHERE login = in_login),
		in_batch_number, description);

	RETURN currval('id');
END;
$$ LANGUAGE PLPGSQL;

CREATE TYPE voucher_list AS (
	id int,
	reference text,
	description text,
	batch_id int,
	transaction_id integer,
	amount numeric,
	transaction_date date,
	voucher_number text
);

CREATE OR REPLACE FUNCTION voucher_list_ap (in_batch_id integer) 
RETURNS SETOF voucher_list AS 
$$
DECLARE
	voucher_out voucher_list%ROWTYPE;
BEGIN
	FOR voucher_out IN SELECT v.id, a.invnumber AS reference, 
		c.name ||' -- ' || c.vendornumber AS description,
		v.batch_id, a.id AS transaction_id,
                a.amount, v.voucher_number
	FROM vouchers v
	JOIN ap a ON (a.id = v.trans_id)
	JOIN vendor c ON (c.id = a.vendor_id)
	WHERE v.br_id = in_batch_id

	LOOP
		RETURN NEXT voucher_out;
	END LOOP;
		
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION voucher_list_payment (in_batch_id integer) 
RETURNS SETOF voucher_list AS 
$$
DECLARE
	voucher_out voucher_list%ROWTYPE;
BEGIN
	FOR voucher_out IN SELECT v.id, c.vendornumber AS reference, 
		c.name AS description, in_batch_id AS batch_id,
		v.transaction_id AS transaction_id, sum(ac.amount) AS amount,
		v.voucher_number
	FROM acc_trans ac
	JOIN vouchers v ON (v.id = ac.vr_id AND v.transaction_id = ac.trans_id)
	JOIN chart ch ON (ch.id = ac.chart_id)
	JOIN ap a ON (a.id = ac.trans_id)
	JOIN vendor c ON (c.id = a.vendor_id)
	WHERE v.br_id = in_batch_id
		AND ch.link LIKE '%AP_paid%'
	GROUP BY v.id, c.name, c.vendornumber, v.voucher_number,
                a.vendor_id, v.transaction_id


	LOOP
		RETURN NEXT voucher_out;
	END LOOP;
		
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION voucher_list_payment_reversal (in_batch_id integer) 
RETURNS SETOF voucher_list AS 
$$
DECLARE
	voucher_out voucher_list%ROWTYPE;
BEGIN
	FOR voucher_out IN 
	SELECT v.id, ac.source AS reference, 
		c.vendornumber || ' -- ' || c.name AS description,
                sum(ac.amount) * -1 AS amount, in_batch_id AS batch_id,
		v.transaction_id AS transaction_id, v.voucher_number
	FROM acc_trans ac
	JOIN vr v ON (v.id = ac.vr_id AND v.trans_id = ac.trans_id)
	JOIN chart ch ON (ch.id = ac.chart_id)
	JOIN ap a ON (a.id = ac.trans_id)
	JOIN vendor c ON (c.id = a.vendor_id)
	WHERE vr.br_id = in_batch_id
	AND c.link LIKE '%AP_paid%'
	GROUP BY v.id, c.name, c.vendornumber, v.voucher_number,
	a.vendor_id, ac.source

	LOOP
		RETURN NEXT voucher_out;
	END LOOP;
		
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION voucher_list_ap (in_batch_id integer) 
RETURNS SETOF voucher_list AS 
$$
DECLARE
	voucher_out voucher_list%ROWTYPE;
BEGIN
	FOR voucher_out IN 
	SELECT v.id, g.reference, g.description, in_batch_id AS batch_id,
                SUM(ac.amount) AS amount, g.id AS transaction_id, 
		v.vouchernumber
	FROM acc_trans ac
	JOIN gl g ON (g.id = ac.trans_id)
	JOIN vouchers v ON (v.trans_id = g.id)
	WHERE v.batch_id = in_batch_id
		AND ac.amount >= 0
	GROUP BY g.id, g.reference, g.description, v.id,
		v.voucher_number

	LOOP
		RETURN NEXT voucher_out;
	END LOOP;
		
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION batch_post (in_batch_id integer[], in_batch text, 
	in_control_amount NUMERIC)
RETURNS BOOL AS
$$
DECLARE
	control_amount NUMERIC;
	voucher voucher%ROWTYPE; 
	incriment NUMERIC;
BEGIN
--  CHECK CONTROL NUMBERS
	IF in_batch = 'gl' THEN
		SELECT sum(amount) INTO control_amount 
		FROM acc_trans
		WHERE trans_id IN (
				SELECT id FROM gl 
				WHERE coalesce(approved, false) != true)
			AND trans_id IN (
				SELECT transaction_id FROM voucher 
				WHERE batch_id = ANY (in_batch_id))
			AND coalesce(approved, false) != true
			AND amount > 0
		FOR UPDATE;

	ELSE IF in_batch like '%payment%' THEN

		SELECT sum(ac.amount) INTO control_amount 
		FROM acc_trans ac
		JOIN voucher v ON (v.transaction_id = ac.trans_id)
		WHERE v.batch_id = ANY (in_batch_id)
			AND ac.vr_id = v.id
			AND coalesce(approved, false) = false
		FOR UPDATE;

	ELSE
		SELECT sum(amount) INTO control_amount
		FROM acc_trans 
		WHERE trans_id IN
				(SELECT transaction_id FROM voucher 
				WHERE batch_id = ANY (in_batch_id))
			AND trans_id IN
				(SELECT trans_id FROM ap 
				WHERE coalesce(approved, false) = false)
			AND amount > 0
		FOR UPDATE;

	END IF;

	IF control_amount != in_control_amount THEN
		RETURN FALSE;
	END IF;

--  TODO: POST TRANSACTIONALLY

	IF in_batch like '%payment%' THEN
	ELSE
		UPDATE acc_trans 
		SET approved = true 
		WHERE trans_id IN 
			(SELECT transaction_id FROM voucher
			WHERE batch_id = ANY (in_batch_id));

		IF in_batch = 'gl' THEN

			UPDATE gl SET approved = true
			WHERE trans_id IN
				(SELECT transaction_id FROM voucher
				WHERE batch_id = ANY (in_batch_id));

		ELSE 
			UPDATE ap SET approved = true
			WHERE trans_id IN
				(SELECT transaction_id FROM voucher
				WHERE batch_id = ANY (in_batch_id));
		END IF;
	END IF;

	RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION batch_create(
in_batch_number text, in_description text, in_batch_class text) RETURNS int AS
$$
BEGIN
	INSERT INTO 
		batch (batch_class_id, description, control_code, created_by)
	VALUES ((SELECT id FROM batch_class WHERE class = in_batch_class),
		in_description, in_batch_number, 
			(select id FROM users WHERE username = session_user));

	return currval('batch_id_seq');
END;	
$$ LANGUAGE PLPGSQL;
