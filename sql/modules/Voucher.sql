
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
    description text,
    created_by text,
    created_on date,
    total numeric
);

CREATE FUNCTION batch_list RETURNS SETOF batch_list_item AS
$$
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION batch_post in_batch_id INTEGER)
returns int AS
$$;

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
