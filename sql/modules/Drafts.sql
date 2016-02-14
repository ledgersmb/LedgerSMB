BEGIN;

DROP TYPE IF EXISTS draft_search_result CASCADE;

CREATE TYPE draft_search_result AS (
	id int,
	transdate date,
        invoice bool,
	reference text,
	description text,
	type text,
	amount numeric
);

CREATE OR REPLACE FUNCTION draft__search(in_type text, in_with_accno text,
in_from_date date, in_to_date date, in_amount_le numeric, in_amount_ge numeric)
returns setof draft_search_result AS
$$
	SELECT id, transdate, invoice, reference, description,
	       type, amount FROM (
	    SELECT id, transdate, reference,
		   description, false as invoice,
                   (SELECT SUM(line.amount)
                      FROM acc_trans line
                     WHERE line.amount > 0
                           and line.trans_id = gl.id) as amount,
                   'gl' as type
	      from gl
	     WHERE (lower(in_type) = 'gl' or in_type is null)
		  AND NOT approved
		  AND NOT EXISTS (SELECT 1
                                    FROM voucher v
                                   WHERE v.trans_id = gl.id)
            UNION
            SELECT id, transdate, invnumber as reference,
		(SELECT name FROM eca__get_entity(entity_credit_account)),
		invoice, amount, 'ap' as type
	      FROM ap
	     WHERE (lower(in_type) = 'ap' or in_type is null)
                   AND NOT approved
	 	   AND NOT EXISTS (SELECT 1
                                     FROM voucher v
                                    WHERE v.trans_id = ap.id)
	    UNION
	    SELECT id, transdate, invnumber as reference,
		description, invoice, amount, 'ar' as type
              FROM ar
	     WHERE (lower(in_type) = 'ar' or in_type is null)
                   AND NOT approved
		   AND NOT EXISTS (SELECT 1
                                     FROM voucher v
                                    WHERE v.trans_id = ar.id)) trans
	WHERE (in_from_date IS NULL or trans.transdate >= in_from_date)
	  AND (in_to_date IS NULL or trans.transdate <= in_to_date)
          AND (in_with_accno IS NULL
               OR id IN (SELECT line.trans_id
                           FROM acc_trans line
                           JOIN account acc ON (line.chart_id = acc.id)
                          WHERE acc.accno = in_with_accno
			    AND NOT approved
                            AND (in_from_date IS NULL
                                 OR line.transdate >= in_from_date)
		            AND (in_to_date IS NULL
			    	 OR line.transdate <= in_to_date)))
	ORDER BY trans.reference;
$$ language sql;

COMMENT ON FUNCTION draft__search(in_type text, in_with_accno text,
in_from_date date, in_to_date date, in_amount_le numeric, in_amount_ge numeric)
IS $$ Searches for drafts.  in_type may be any of 'ar', 'ap', or 'gl'.$$;

CREATE OR REPLACE FUNCTION draft_approve(in_id int) returns bool as
$$
declare
	t_table text;
begin
	SELECT table_name into t_table FROM transactions where id = in_id;

        IF (t_table = 'ar') THEN
                PERFORM cogs__add_for_ar_line(id) FROM invoice
                  WHERE trans_id = in_id;
		UPDATE ar set approved = true where id = in_id;
	ELSIF (t_table = 'ap') THEN
                PERFORM cogs__add_for_ap_line(id) FROM invoice
                  WHERE trans_id = in_id;
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

COMMENT ON FUNCTION draft_approve(in_id int) IS
$$ Posts draft to the books.  in_id is the id from the ar, ap, or gl table.$$;

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

COMMENT ON FUNCTION draft_delete(in_id int) is
$$ Deletes the draft from the book.  Only will delete unapproved transactions.
Otherwise an exception is raised and the transaction terminated.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
