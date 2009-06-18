CREATE TYPE draft_search_result AS (
	id int,
	transdate date,
	reference text,
	description text,
	amount numeric
);

CREATE OR REPLACE FUNCTION draft__search(in_type text, in_with_accno text, 
in_from_date date, in_to_date date, in_amount_le numeric, in_amount_ge numeric)
returns setof draft_search_result AS
$$
DECLARE out_row RECORD;
BEGIN
	FOR out_row IN
		SELECT trans.id, trans.transdate, trans.reference, 
			trans.description, 
			sum(case when lower(in_type) = 'ap' AND chart.link = 'AP'
				 THEN line.amount
				 WHEN lower(in_type) = 'ar' AND chart.link = 'AR'
				 THEN line.amount * -1
				 WHEN lower(in_type) = 'gl' AND line.amount > 0
				 THEN line.amount
			 	 ELSE 0
			    END) as amount
		FROM (
			SELECT id, transdate, reference, description, 
				approved from gl
			WHERE lower(in_type) = 'gl'
			UNION
			SELECT id, transdate, invnumber as reference, 
				description::text,
				approved from ap
			WHERE lower(in_type) = 'ap'
			UNION
			SELECT id, transdate, invnumber as reference,
				description, 
				approved from ar
			WHERE lower(in_type) = 'ar'
			) trans
		JOIN acc_trans line ON (trans.id = line.trans_id)
		JOIN chart ON (line.chart_id = chart.id)
		WHERE (in_from_date IS NULL or trans.transdate >= in_from_date)
			AND (in_to_date IS NULL 
				or trans.transdate <= in_to_date)
			AND trans.approved IS FALSE
			AND trans.id NOT IN (select trans_id from voucher)
		GROUP BY trans.id, trans.transdate, trans.description, trans.reference
		HAVING (in_with_accno IS NULL or in_with_accno = 
			ANY(as_array(chart.accno)))
		ORDER BY trans.reference
	LOOP
		RETURN NEXT out_row;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION draft_approve(in_id int) returns bool as
$$
declare 
	t_table text;
begin
	SELECT table_name into t_table FROM transactions where id = in_id;

        IF (t_table = 'ar') THEN
		UPDATE ar set approved = true where id = in_id;
	ELSIF (t_table = 'ap') THEN
		UPDATE ap set approved = true where id = in_id;
	ELSIF (t_table = 'gl') THEN
		UPDATE gl set approved = true where id = in_id;
	ELSE
		raise exception 'Invalid table % in draft_approve for transaction %', t_table, in_id;
	END IF;

	IF NOT FOUND THEN
		RETURN FALSE;
	END IF;

	UPDATE transactions 
	SET approved_by = 
			(select entity_id FROM users 
			WHERE username = SESSION_USER), 
		approved_at = now() 
	WHERE id = in_id;

	RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION draft_delete(in_id int) returns bool as
$$
declare 
	t_table text;
begin
	DELETE FROM ac_tax_form 
	WHERE entry_id IN 
		(SELECT entry_id FROM acc_trans WHERE trans_id = in_id);

        DELETE FROM acc_trans WHERE trans_id = in_id;
	SELECT lower(table_name) into t_table FROM transactions where id = in_id;

        IF t_table = 'ar' THEN
		DELETE FROM ar WHERE id = in_id AND approved IS FALSE;
	ELSIF t_table = 'ap' THEN
		DELETE FROM ap WHERE id = in_id AND approved IS FALSE;
	ELSIF t_table = 'gl' THEN
		DELETE FROM gl WHERE id = in_id AND approved IS FALSE;
	ELSE
		raise exception 'Invalid table % in draft_delete for transaction %', t_table, in_id;
	END IF;
	IF NOT FOUND THEN
		RAISE EXCEPTION 'Invalid transaction id %', in_id;
	END IF;
	RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

