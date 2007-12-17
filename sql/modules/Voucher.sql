
CREATE OR REPLACE FUNCTION voucher_get_batch (in_batch_id integer) 
RETURNS batch AS 
$$
DECLARE
	batch_out batch%ROWTYPE;
BEGIN
	SELECT * INTO batch_out FROM batch b WHERE b.id = in_batch_id;
	RETURN batch_out;
END;
$$ language plpgsql;


CREATE OR REPLACE FUNCTION batch_post (in_batch text, in_login varchar, in_entered date,
	in_batch_number text, in_description text, in_id integer) 
RETURNS integer AS
$$
BEGIN
	UPDATE batch
	SET batch_number = in_batch_number,
		description = in_description,
		entered = in_entered
	WHERE id = in_id;

	IF FOUND THEN 
		RETURN in_id;
	END IF;

	INSERT INTO batch (batch, employee_id, batch_number, description, 
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
        batch_class text
);

CREATE OR REPLACE FUNCTION voucher_list (in_batch_id integer)
RETURNS SETOF voucher_list AS
$$
declare voucher_item record;
BEGIN
    	FOR voucher_item IN
		SELECT v.id, a.invnumber, e.name, v.batch_id, v.trans_id, 
			a.amount - a.paid, a.transdate, 'Payable'
		FROM voucher v
		JOIN ap a ON (v.trans_id = a.id)
		JOIN entity e ON (a.entity_id = e.id)
		WHERE v.batch_id = in_batch_id 
			AND v.batch_class = (select id from batch_class 
					WHERE class = 'payable')
		UNION
		SELECT v.id, a.invnumber, e.name, v.batch_id, v.trans_id, 
			a.amount - a.paid, a.transdate, 'Receivable'
		FROM voucher v
		JOIN ar a ON (v.trans_id = a.id)
		JOIN entity e ON (a.entity_id = e.id)
		WHERE v.batch_id = in_batch_id 
			AND v.batch_class = (select id from batch_class 
					WHERE class = 'receivable')
		UNION
		SELECT v.id, a.source, a.memo, v.batch_id, v.trans_id, 
			a.amount, a.transdate, bc.class
		FROM voucher v
		JOIN acc_trans a ON (v.trans_id = a.trans_id)
                JOIN batch_class bc ON (bc.id = v.batch_class)
		WHERE v.batch_id = in_batch_id 
			AND a.voucher_id = v.id
			AND bc.class like 'payment%'
			OR bc.class like 'receipt%'
		UNION
		SELECT v.id, g.reference, g.description, v.batch_id, v.trans_id,
			sum(a.amount), g.transdate, 'gl'
		FROM voucher v
		JOIN gl g ON (g.id = v.trans_id)
		JOIN acc_trans a ON (v.trans_id = a.trans_id)
		WHERE a.amount > 0
			AND v.batch_id = in_batch_id
			AND v.batch_class IN (select id from batch_class 
					where class = 'gl')
		GROUP BY v.id, g.reference, g.description, v.batch_id, 
			v.trans_id, g.transdate
		ORDER BY 7, 1
	LOOP
		RETURN NEXT voucher_item;
	END LOOP;
END;
$$ language plpgsql;

CREATE TYPE batch_list_item AS (
    id integer,
    batch_class text,
    control_code text,
    description text,
    created_by text,
    created_on date,
    transaction_total numeric,
    payment_total numeric
);

CREATE OR REPLACE FUNCTION 
batch_search(in_class_id int, in_description text, in_created_by_eid int, 
	in_amount_gt numeric, 
	in_amount_lt numeric, in_approved bool) 
RETURNS SETOF batch_list_item AS
$$
DECLARE out_value batch_list_item;
BEGIN
	FOR out_value IN
		SELECT b.id, c.class, b.control_code, b.description, u.username,
			b.created_on,
			sum(
				CASE WHEN vc.id = 5 AND al.amount > 0 
				     THEN al.amount
				     WHEN vc.id NOT IN (3, 4, 6, 7) 
                                     THEN coalesce(ar.amount, ap.amount, 0)
				     ELSE 0
                                END) AS transaction_total,
			sum(
				CASE WHEN alc.link = 'AR' AND vc.id IN (3,4,6,7)
				     THEN al.amount
				     WHEN alc.link = 'AP' AND vc.id IN (3,4,6,7)
				     THEN al.amount * -1
				     ELSE 0
				END
			   ) AS payment_total
		FROM batch b
		JOIN batch_class c ON (b.batch_class_id = c.id)
		JOIN users u ON (u.entity_id = b.created_by)
		JOIN voucher v ON (v.batch_id = b.id)
		JOIN batch_class vc ON (v.batch_class = c.id)
		LEFT JOIN ar ON (vc.id = 2 AND v.trans_id = ar.id)
		LEFT JOIN ap ON (vc.id = 1 AND v.trans_id = ap.id)
		LEFT JOIN acc_trans al ON 
			((vc.id = 5 AND v.trans_id = al.trans_id) OR
				(vc.id IN (3, 4, 6, 7) AND al.voucher_id = v.id)
				AND al.amount > 0)
		LEFT JOIN chart alc ON (al.chart_id = alc.id)
		WHERE c.id = coalesce(in_class_id, c.id) AND 
			b.description LIKE 
				'%' || coalesce(in_description, '') || '%' AND
			coalesce(in_created_by_eid, b.created_by) 
				= b.created_by 
			AND ((coalesce(in_approved, false) = false AND
				approved_on IS NULL) OR
				(in_approved = true AND approved_on IS NOT NULL)
			)
		GROUP BY b.id, c.class, b.description, u.username, b.created_on,
			b.control_code
		HAVING  
			sum(coalesce(ar.amount - ar.paid, ap.amount - ap.paid, 
				al.amount)) 
			>= coalesce(in_amount_gt, 
				sum(coalesce(ar.amount - ar.paid, 
					ap.amount - ap.paid, 
					al.amount)))
			AND 
			sum(coalesce(ar.amount - ar.paid, ap.amount - ap.paid, 
				al.amount))
			<= coalesce(in_amount_lt, 
				sum(coalesce(ar.amount - ar.paid, 
					ap.amount - ap.paid, 
					al.amount)))
		
	LOOP
		RETURN NEXT out_value;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;



CREATE OR REPLACE FUNCTION batch_post(in_batch_id INTEGER)
returns date AS
$$
BEGIN
	UPDATE ar SET approved = true 
	WHERE id IN (select trans_id FROM voucher 
		WHERE batch_id = in_batch_id
		AND batch_class = 2);
	
	UPDATE ap SET approved = true 
	WHERE id IN (select trans_id FROM voucher 
		WHERE batch_id = in_batch_id
		AND batch_class = 1);

	UPDATE gl SET approved = true 
	WHERE id IN (select trans_id FROM voucher 
		WHERE batch_id = in_batch_id
		AND batch_class = 5);

	UPDATE acc_trans SET approved = true 
	WHERE id IN (select trans_id FROM voucher 
		WHERE batch_id = in_batch_id
		AND batch_class IN (3, 4, 7, 8));

	UPDATE batch 
	SET approved_on = now(),
		approved_by = (select entity_id FROM users 
			WHERE login = SESSION_USER)
	WHERE batch_id = in_batch_id;

	RETURN now()::date;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION batch_list_classes() RETURNS SETOF batch_class AS
$$
DECLARE out_val record;
BEGIN
	FOR out_val IN select * from batch_class
 	LOOP
		return next out_val;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION batch_get_users() RETURNS SETOF users AS
$$
DECLARE out_record users%ROWTYPE;
BEGIN
	FOR out_record IN
		SELECT * from users WHERE entity_id IN (select created_by from batch)
	LOOP
		RETURN NEXT out_record;
	END LOOP;
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
			(select entity_id FROM users WHERE username = session_user));

	return currval('batch_id_seq');
END;	
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION batch_delete(in_batch_id int) RETURNS int AS
$$
DECLARE 
	t_transaction_ids int[];
BEGIN
	-- Adjust AR/AP tables for payment and payment reversal vouchers
	-- voucher_id is only set in acc_trans on payment/receipt vouchers and
	-- their reversals. -CT
	update ar set paid = amount - 
		(select sum(amount) * -1 from acc_trans 
		join chart ON (acc_trans.chart_id = chart.id)
		where link = 'AR' AND trans_id = ar.id
			AND voucher_id NOT IN 
				(select id from voucher 
				WHERE batch_id = in_batch_id)) 
	where id in (select trans_id from acc_trans where voucher_id IN 
		(select id from voucher where batch_id = in_batch_id));

	update ap set paid = amount - (select sum(amount) from acc_trans 
		join chart ON (acc_trans.chart_id = chart.id)
		where link = 'AP' AND trans_id = ap.id
			AND voucher_id NOT IN 
				(select id from voucher 
				WHERE batch_id = in_batch_id)) 
	where id in (select trans_id from acc_trans where voucher_id IN 
		(select id from voucher where batch_id = in_batch_id));

	DELETE FROM acc_trans WHERE voucher_id IN 
		(select id FROM voucher where batch_id = in_batch_id);

	-- The rest of this function involves the deletion of actual
	-- transactions, vouchers, and batches, and jobs which are in progress.
	-- -CT
	SELECT as_array(trans_id) INTO t_transaction_ids
	FROM voucher WHERE batch_id = in_batch_id AND batch_class IN (1, 2, 5);

	DELETE FROM acc_trans WHERE trans_id = ANY(t_transaction_ids);
	DELETE FROM ap WHERE id = ANY(t_transaction_ids);
	DELETE FROM gl WHERE id = ANY(t_transaction_ids);
	DELETE FROM voucher WHERE batch_id = in_batch_id;
	DELETE FROM payments_queue WHERE batch_id = in_batch_id;
	DELETE FROM pending_job WHERE batch_id = in_batch_id;
	DELETE FROM batch WHERE id = in_batch_id;
	DELETE FROM transactions WHERE id = ANY(t_transaction_ids);

	RETURN 1;
END;
$$ language plpgsql;
