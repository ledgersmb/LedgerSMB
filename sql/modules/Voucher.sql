
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


CREATE OR REPLACE FUNCTION batch_update (in_batch text, in_login varchar, in_entered date,
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
		SELECT v.id, a.invnumber, e.name, 
			v.batch_id, v.trans_id, 
			a.amount, a.transdate, 'Payable'
		FROM voucher v
		JOIN ap a ON (v.trans_id = a.id)
		JOIN entity_credit_account eca 
			ON (eca.id = a.entity_credit_account)
		JOIN entity e ON (eca.entity_id = e.id)
		WHERE v.batch_id = in_batch_id 
			AND v.batch_class = (select id from batch_class 
					WHERE class = 'ap')
		UNION
		SELECT v.id, a.invnumber, e.name, 
			v.batch_id, v.trans_id, 
			a.amount, a.transdate, 'Receivable'
		FROM voucher v
		JOIN ar a ON (v.trans_id = a.id)
		JOIN entity_credit_account eca 
			ON (eca.id = a.entity_credit_account)
		JOIN entity e ON (eca.entity_id = e.id)
		WHERE v.batch_id = in_batch_id 
			AND v.batch_class = (select id from batch_class 
					WHERE class = 'ar')
		UNION ALL
		-- TODO:  Add the class labels to the class table.
		SELECT v.id, a.source, 
			cr.meta_number || '--'  || co.legal_name , 
			v.batch_id, v.trans_id, 
			sum(CASE WHEN bc.class LIKE 'payment%' THEN a.amount * -1
			     ELSE a.amount  END), a.transdate, 
			CASE WHEN bc.class = 'payment' THEN 'Payment'
			     WHEN bc.class = 'payment_reversal' 
			     THEN 'Payment Reversal'
			END
		FROM voucher v
		JOIN acc_trans a ON (v.id = a.voucher_id)
                JOIN batch_class bc ON (bc.id = v.batch_class)
		JOIN chart c ON (a.chart_id = c.id)
		JOIN ap ON (ap.id = a.trans_id)
		JOIN entity_credit_account cr 
			ON (ap.entity_credit_account = cr.id)
		JOIN company co ON (cr.entity_id = co.entity_id)
		WHERE v.batch_id = in_batch_id 
			AND a.voucher_id = v.id
			AND (bc.class like 'payment%' AND c.link = 'AP')
		GROUP BY v.id, a.source, cr.meta_number, co.legal_name ,
                        v.batch_id, v.trans_id, a.transdate, bc.class

		UNION ALL
		SELECT v.id, a.source, a.memo, 
			v.batch_id, v.trans_id, 
			CASE WHEN bc.class LIKE 'receipt%' THEN a.amount * -1
			     ELSE a.amount  END, a.transdate, 
			CASE WHEN bc.class = 'receipt' THEN 'Receipt'
			     WHEN bc.class = 'receipt_reversal' 
			     THEN 'Receipt Reversal'
			END
		FROM voucher v
		JOIN acc_trans a ON (v.trans_id = a.trans_id)
                JOIN batch_class bc ON (bc.id = v.batch_class)
		JOIN chart c ON (a.chart_id = c.id)
		JOIN ar ON (ar.id = a.trans_id)
		JOIN entity_credit_account cr 
			ON (ar.entity_credit_account = cr.id)
		JOIN company co ON (cr.entity_id = co.entity_id)
		WHERE v.batch_id = in_batch_id 
			AND a.voucher_id = v.id
			AND (bc.class like 'receipt%' AND c.link = 'AR')
		UNION ALL
		SELECT v.id, g.reference, g.description, 
			v.batch_id, v.trans_id,
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
    default_date date,
    transaction_total numeric,
    payment_total numeric
);

CREATE OR REPLACE FUNCTION 
batch_search(in_class_id int, in_description text, in_created_by_eid int, 
	in_date_from date, in_date_to date,
	in_amount_gt numeric, 
	in_amount_lt numeric, in_approved bool) 
RETURNS SETOF batch_list_item AS
$$
DECLARE out_value batch_list_item;
BEGIN
	FOR out_value IN
		SELECT b.id, c.class, b.control_code, b.description, u.username,
			b.created_on, b.default_date,
			sum(
				CASE WHEN vc.id = 5 AND al.amount < 0 -- GL
				     THEN al.amount 
				     WHEN vc.id  = 1
				     THEN ap.amount 
				     WHEN vc.id = 2
                                     THEN ap.amount
				     ELSE 0
                                END) AS transaction_total,
			sum(
				CASE WHEN alc.link = 'AR' AND vc.id IN (6, 7)
				     THEN al.amount
				     WHEN alc.link = 'AP' AND vc.id IN (3, 4)
				     THEN al.amount * -1
				     ELSE 0
				END
			   ) AS payment_total
		FROM batch b
		JOIN batch_class c ON (b.batch_class_id = c.id)
		LEFT JOIN users u ON (u.entity_id = b.created_by)
		JOIN voucher v ON (v.batch_id = b.id)
		JOIN batch_class vc ON (v.batch_class = vc.id)
		LEFT JOIN ar ON (vc.id = 2 AND v.trans_id = ar.id)
		LEFT JOIN ap ON (vc.id = 1 AND v.trans_id = ap.id)
		LEFT JOIN acc_trans al ON 
			((vc.id = 5 AND v.trans_id = al.trans_id) OR
				(vc.id IN (3, 4, 6, 7) 
					AND al.voucher_id = v.id))
		LEFT JOIN chart alc ON (al.chart_id = alc.id)
		WHERE (c.id = in_class_id OR in_class_id IS NULL) AND 
			(b.description LIKE 
				'%' || in_description || '%' OR
				in_description IS NULL) AND
			(in_created_by_eid = b.created_by OR
				in_created_by_eid IS NULL) AND
			((in_approved = false OR in_approved IS NULL AND
				approved_on IS NULL) OR
				(in_approved = true AND approved_on IS NOT NULL)
			) 
			and (in_date_from IS NULL 
				or b.default_date >= in_date_from)
			and (in_date_to IS NULL
				or b.default_date <= in_date_to)
		GROUP BY b.id, c.class, b.description, u.username, b.created_on,
			b.control_code, b.default_date
		HAVING  
			(in_amount_gt IS NULL OR
			sum(coalesce(ar.amount - ar.paid, ap.amount - ap.paid, 
				al.amount)) 
			>= in_amount_gt) 
			AND 
			(in_amount_lt IS NULL OR
			sum(coalesce(ar.amount - ar.paid, ap.amount - ap.paid, 
				al.amount))
			<= in_amount_lt)
		ORDER BY b.control_code, b.description
		
	LOOP
		RETURN NEXT out_value;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION batch_get_class_id (in_type text) returns int AS
$$
SELECT id FROM batch_class WHERE class = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION 
batch_search_mini
(in_class_id int, in_description text, in_created_by_eid int, in_approved bool) 
RETURNS SETOF batch_list_item AS
$$
DECLARE out_value batch_list_item;
BEGIN
	FOR out_value IN
		SELECT b.id, c.class, b.control_code, b.description, u.username,
			b.created_on, b.default_date, NULL
		FROM batch b
		JOIN batch_class c ON (b.batch_class_id = c.id)
		LEFT JOIN users u ON (u.entity_id = b.created_by)
		WHERE (c.id = in_class_id OR in_class_id IS NULL) AND 
			(b.description LIKE 
				'%' || in_description || '%' OR
				in_description IS NULL) AND
			(in_created_by_eid = b.created_by OR
				in_created_by_eid IS NULL) AND
			((in_approved = false OR in_approved IS NULL AND
				approved_on IS NULL) OR
				(in_approved = true AND approved_on IS NOT NULL)
			)
		GROUP BY b.id, c.class, b.description, u.username, b.created_on,
			b.control_code, b.default_date
	LOOP
		RETURN NEXT out_value;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION 
batch_search_empty(in_class_id int, in_description text, in_created_by_eid int, 
	in_amount_gt numeric, 
	in_amount_lt numeric, in_approved bool) 
RETURNS SETOF batch_list_item AS
$$
DECLARE out_value batch_list_item;
BEGIN
	FOR out_value IN
		SELECT b.id, c.class, b.control_code, b.description, u.username,
			b.created_on, b.default_date,
			sum(
				CASE WHEN vc.id = 5 AND al.amount < 0 -- GL
				     THEN al.amount 
				     WHEN vc.id  = 1
				     THEN ap.amount 
				     WHEN vc.id = 2
                                     THEN ap.amount
				     ELSE 0
                                END) AS transaction_total,
			sum(
				CASE WHEN alc.link = 'AR' AND vc.id IN (6, 7)
				     THEN al.amount
				     WHEN alc.link = 'AP' AND vc.id IN (3, 4)
				     THEN al.amount * -1
				     ELSE 0
				END
			   ) AS payment_total
		FROM batch b
		JOIN batch_class c ON (b.batch_class_id = c.id)
		LEFT JOIN users u ON (u.entity_id = b.created_by)
		LEFT JOIN voucher v ON (v.batch_id = b.id)
		LEFT JOIN batch_class vc ON (v.batch_class = vc.id)
		LEFT JOIN ar ON (vc.id = 2 AND v.trans_id = ar.id)
		LEFT JOIN ap ON (vc.id = 1 AND v.trans_id = ap.id)
		LEFT JOIN acc_trans al ON 
			((vc.id = 5 AND v.trans_id = al.trans_id) OR
				(vc.id IN (3, 4, 6, 7) 
					AND al.voucher_id = v.id))
		LEFT JOIN chart alc ON (al.chart_id = alc.id)
		WHERE (c.id = in_class_id OR in_class_id IS NULL) AND 
			(b.description LIKE 
				'%' || in_description || '%' OR
				in_description IS NULL) AND
			(in_created_by_eid = b.created_by OR
				in_created_by_eid IS NULL) AND
			((in_approved = false OR in_approved IS NULL AND
				approved_on IS NULL) OR
				(in_approved = true AND approved_on IS NOT NULL)
			)
		GROUP BY b.id, c.class, b.description, u.username, b.created_on,
			b.control_code, b.default_date
		HAVING  
			(in_amount_gt IS NULL OR
			sum(coalesce(ar.amount - ar.paid, ap.amount - ap.paid, 
				al.amount)) 
			>= in_amount_gt) 
			AND 
			(in_amount_lt IS NULL OR
			sum(coalesce(ar.amount - ar.paid, ap.amount - ap.paid, 
				al.amount))
			<= in_amount_lt)
			AND count(v.*) = 0
		ORDER BY b.control_code, b.description
		
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
	WHERE voucher_id IN (select id FROM voucher 
		WHERE batch_id = in_batch_id
		AND batch_class IN (3, 4, 7, 8));

	UPDATE batch 
	SET approved_on = now(),
		approved_by = (select entity_id FROM users 
			WHERE username = SESSION_USER)
	WHERE id = in_batch_id;

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
in_batch_number text, in_description text, in_batch_class text, 
in_batch_date date) 
RETURNS int AS
$$
BEGIN
	INSERT INTO 
		batch (batch_class_id, default_date, description, control_code,
			created_by)
	VALUES ((SELECT id FROM batch_class WHERE class = in_batch_class),
		in_batch_date, in_description, in_batch_number, 
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
	update ar set paid = amount + 
		(select sum(amount) from acc_trans 
		join chart ON (acc_trans.chart_id = chart.id)
		where link = 'AR' AND trans_id = ar.id
			AND (voucher_id IS NULL OR voucher_id NOT IN 
				(select id from voucher 
				WHERE batch_id = in_batch_id))) 
	where id in (select trans_id from acc_trans where voucher_id IN 
		(select id from voucher where batch_id = in_batch_id));

	update ap set paid = amount - (select sum(amount) from acc_trans 
		join chart ON (acc_trans.chart_id = chart.id)
		where link = 'AP' AND trans_id = ap.id
			AND (voucher_id IS NULL OR voucher_id NOT IN 
				(select id from voucher 
				WHERE batch_id = in_batch_id))) 
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
$$ language plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION batch_delete(int) FROM PUBLIC;

CREATE OR REPLACE FUNCTION voucher__delete(in_voucher_id int)
RETURNS int AS
$$
DECLARE 
	voucher_row RECORD;
BEGIN
	SELECT * INTO voucher_row FROM voucher WHERE id = in_voucher_id;
	IF voucher_row.batch_class IN (1, 2, 5) THEN
		DELETE from acc_trans WHERE trans_id = voucher_row.trans_id;
		DELETE FROM ar WHERE id = voucher_row.trans_id;
		DELETE FROM ap WHERE id = voucher_row.trans_id;
		DELETE FROM gl WHERE id = voucher_row.trans_id;
		DELETE FROM voucher WHERE id = voucher_row.id;
		-- DELETE FROM transactions WHERE id = voucher_row.trans_id;
	ELSE 
		update ar set paid = amount + 
			(select sum(amount) from acc_trans 
			join chart ON (acc_trans.chart_id = chart.id)
			where link = 'AR' AND trans_id = ar.id
				AND (voucher_id IS NULL 
				OR voucher_id <> voucher_row.id))
		where id in (select trans_id from acc_trans 
				where voucher_id = voucher_row.id);

		update ap set paid = amount - (select sum(amount) from acc_trans 
			join chart ON (acc_trans.chart_id = chart.id)
			where link = 'AP' AND trans_id = ap.id
				AND (voucher_id IS NULL 
				OR voucher_id <> voucher_row.id))
		where id in (select trans_id from acc_trans 
				where voucher_id = voucher_row.id);

		DELETE FROM acc_trans where voucher_id = voucher_row.id;
	END IF;
	RETURN 1;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

REVOKE ALL ON FUNCTION voucher__delete(int) FROM public;
