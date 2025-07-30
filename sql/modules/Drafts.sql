
set client_min_messages = 'warning';


BEGIN;

DROP TYPE IF EXISTS draft_search_result CASCADE;

CREATE TYPE draft_search_result AS (
        id int,
        transdate date,
        invoice bool,
        reference text,
        eca_name text,
        description text,
        type text,
        amount numeric
);

DROP FUNCTION IF EXISTS draft__search(in_type text, in_with_accno text,
in_from_date date, in_to_date date, in_amount_lt numeric, in_amount_gt numeric);

CREATE OR REPLACE FUNCTION draft__search(in_type text, in_reference text,
in_from_date date, in_to_date date, in_amount_lt numeric, in_amount_gt numeric)
returns setof draft_search_result AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
        SELECT id, transdate, invoice, reference, eca_name, description,
               type, amount FROM (
            SELECT id, transdate, reference, null::text as eca_name,
                   description, false as invoice,
                   (SELECT SUM(line.amount_bc)
                      FROM acc_trans line
                     WHERE line.amount_bc > 0
                           and line.trans_id = gl.id) as amount,
                   'gl' as type
              from gl
             WHERE (lower($1) = 'gl' or $1 is null)
                  AND NOT approved
                  AND NOT EXISTS (SELECT 1
                                    FROM voucher v
                                   WHERE v.trans_id = gl.id)
            UNION
            SELECT id, transdate, invnumber as reference,
                (SELECT name FROM eca__get_entity(entity_credit_account)) as eca_name,
                description, invoice, amount_bc as amount, 'ap' as type
              FROM ap
             WHERE (lower($1) = 'ap' or $1 is null)
                   AND NOT approved
                   AND NOT EXISTS (SELECT 1
                                     FROM voucher v
                                    WHERE v.trans_id = ap.id)
            UNION
            SELECT id, transdate, invnumber as reference,
                (SELECT name FROM eca__get_entity(entity_credit_account)) as eca_name,
                description, invoice, amount_bc as amount, 'ar' as type
              FROM ar
             WHERE (lower($1) = 'ar' or $1 is null)
                   AND NOT approved
                   AND NOT EXISTS (SELECT 1
                                     FROM voucher v
                                    WHERE v.trans_id = ar.id)) trans
        WHERE ($3 IS NULL or trans.transdate >= $3)
          AND ($4 IS NULL or trans.transdate <= $4)
          AND ($6 IS NULL or amount >= $6)
          AND ($5 IS NULL or amount <= $5)
          AND ($2 IS NULL or trans.reference = $2)
        ORDER BY trans.reference
$sql$
USING in_type, in_reference, in_from_date, in_to_date, in_amount_lt, in_amount_gt;
END
$$ LANGUAGE PLPGSQL;

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
          PERFORM cogs__add_for_ar_line(id)
             FROM invoice
            WHERE trans_id = in_id;
          UPDATE ar
             set invnumber = setting_increment('sinumber')
           WHERE id = in_id AND invnumber is null;
          UPDATE ar set approved = true WHERE id = in_id;
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

        UPDATE acc_trans
        SET approved = 't'::boolean
        WHERE trans_id = in_id;

        RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

COMMENT ON FUNCTION draft_approve(in_id int) IS
$$ Posts draft to the books.  in_id is the id from the ar, ap, or gl table.$$;

CREATE OR REPLACE FUNCTION draft__delete_lines(in_id int) returns bool as
  $$
  begin
        DELETE FROM ac_tax_form atf
         WHERE EXISTS (SELECT 1 FROM acc_trans
                        WHERE entry_id = atf.entry_id
                              AND trans_id = in_id);

        DELETE FROM payment_links pl
         WHERE EXISTS (SELECT 1 FROM acc_trans
                        WHERE entry_id = pl.entry_id
                              AND trans_id = in_id)
               AND (SELECT count(distinct ac.trans_id)
                      FROM payment p
                      JOIN payment_links pli ON p.id = pli.payment_id
                      JOIN acc_trans ac ON pli.entry_id = ac.entry_id
                     WHERE pl.payment_id = p.id) <= 1;

        DELETE FROM acc_trans WHERE trans_id = in_id;

        DELETE FROM invoice_tax_form itf
           WHERE EXISTS (select 1 from invoice i
                          where i.trans_id = in_id and itf.invoice_id = i.id);

        UPDATE parts p
           SET onhand = p.onhand + i.qty
               FROM invoice i
         WHERE i.trans_id = in_id
           AND p.id = i.parts_id
           AND p.inventory_accno_id IS NOT NULL;

        DELETE FROM invoice WHERE trans_id = in_id;

    RETURN true;
  end;
  $$ language plpgsql security definer;

REVOKE ALL ON FUNCTION draft__delete_lines(int) FROM PUBLIC;

COMMENT ON FUNCTION draft__delete_lines(in_id int) is
$$ Deletes the lines from the draft to prepare it for a re-save action.$$;


CREATE OR REPLACE FUNCTION draft_delete(in_id int) returns bool as
$$
declare
        t_table text;
begin
        DELETE FROM ac_tax_form atf
         WHERE EXISTS (SELECT 1 FROM acc_trans
                        WHERE entry_id = atf.entry_id
                              AND trans_id = in_id);

        DELETE FROM payment_links pl
         WHERE EXISTS (SELECT 1 FROM acc_trans
                        WHERE entry_id = pl.entry_id
                              AND trans_id = in_id)
               AND (SELECT count(distinct ac.trans_id)
                      FROM payment p
                      JOIN payment_links pli ON p.id = pli.payment_id
                      JOIN acc_trans ac ON pli.entry_id = ac.entry_id
                     WHERE pl.payment_id = p.id) <= 1;

        DELETE FROM acc_trans WHERE trans_id = in_id;
        DELETE FROM invoice_tax_form itf
           WHERE EXISTS (select 1 from invoice i
                          where i.trans_id = in_id and itf.invoice_id = i.id);
        DELETE FROM invoice WHERE trans_id = in_id;
        SELECT lower(table_name) into t_table
          FROM transactions where id = in_id;

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

REVOKE ALL ON FUNCTION draft_delete(int) FROM PUBLIC;


COMMENT ON FUNCTION draft_delete(in_id int) is
$$ Deletes the draft from the book.  Only will delete unapproved transactions.
Otherwise an exception is raised and the transaction terminated.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
