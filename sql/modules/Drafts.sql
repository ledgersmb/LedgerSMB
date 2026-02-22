
set client_min_messages = 'warning';


BEGIN;

DROP TYPE IF EXISTS draft_search_result CASCADE;

CREATE TYPE draft_search_result AS (
        id int,
        transdate date,
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
    SELECT *
      FROM (
        SELECT txn.id, txn.transdate, txn.reference,
               (select name
                  from eca__get_entity(coalesce(ar.entity_credit_account,
                                                ap.entity_credit_account))) as eca_name,
               description, table_name as type,
               CASE WHEN txn.table_name = 'ar' THEN ar.amount_bc
                    WHEN txn.table_name = 'ap' THEN ap.amount_bc
                    ELSE (
                      SELECT SUM(line.amount_bc)
                        FROM acc_trans line
                       WHERE line.amount_bc > 0
                         and line.trans_id = txn.id
                    )
               END as amount
          FROM transactions txn
                 LEFT JOIN ar
                     ON ar.id = txn.id
                 LEFT JOIN ap
                     ON ap.id = txn.id
         WHERE NOT EXISTS (select 1
                             from voucher v
                            where v.trans_id = txn.id)
           AND NOT txn.approved
           AND (lower($1) = txn.table_name or $1 is null)
           AND ($3 IS NULL or txn.transdate >= $3)
           AND ($4 IS NULL or txn.transdate <= $4)
           AND ($2 IS NULL or txn.reference = $2)
      ) x
    WHERE ($6 IS NULL or amount >= $6)
           AND ($5 IS NULL or amount <= $5)
    ORDER BY reference
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
        ELSIF (t_table = 'ap') THEN
                PERFORM cogs__add_for_ap_line(id) FROM invoice
                  WHERE trans_id = in_id;
        END IF;

        UPDATE transactions
           SET approved = true,
               approved_by =
                        (select entity_id FROM users
                        WHERE username = SESSION_USER),
                approved_at = now()
        WHERE id = in_id;

        IF NOT FOUND THEN
                RETURN FALSE;
        END IF;

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

        -- this cleans out any referring resources as well, through their
        -- cascading deletion references
        DELETE FROM transactions WHERE id = in_id AND approved IS FALSE;
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
