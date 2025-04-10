
set client_min_messages = 'warning';


BEGIN;

CREATE OR REPLACE FUNCTION batch__lock_for_update (in_batch_id integer)
RETURNS batch LANGUAGE SQL
SECURITY DEFINER AS
$$
SELECT * FROM batch WHERE id = $1 FOR UPDATE;
$$;

REVOKE EXECUTE ON FUNCTION batch__lock_for_update(int) FROM PUBLIC;

COMMENT ON FUNCTION batch__lock_for_update(in_batch_id integer) is
$$ Locks a batch for the duration of the running transaction.
To be used when adding vouchers to the batch to prevent others
from hitting the batch for other purposes (e.g. approval) $$;

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

COMMENT ON FUNCTION voucher_get_batch (in_batch_id integer) is
$$ Retrieves basic batch information based on batch_id.$$;

DROP TYPE IF EXISTS voucher_list CASCADE;
CREATE TYPE voucher_list AS (
        id int,
        invoice bool,
        reference text,
        description text,
        batch_id int,
        transaction_id integer,
        amount numeric,
        transaction_date date,
        batch_class text,
        batch_class_id int
);

-- voucher_list could use refactoring

CREATE OR REPLACE FUNCTION voucher__list (in_batch_id integer)
RETURNS SETOF voucher_list AS
$$
                SELECT v.id, a.invoice, a.invnumber,
                        eca.meta_number || '--' || e.name,
                        v.batch_id, v.trans_id,
                        a.amount_bc, a.transdate, 'Payable', v.batch_class
                FROM voucher v
                JOIN ap a ON (v.trans_id = a.id)
                JOIN entity_credit_account eca
                        ON (eca.id = a.entity_credit_account)
                JOIN entity e ON (eca.entity_id = e.id)
                WHERE v.batch_id = in_batch_id
                        AND v.batch_class = (select id from batch_class
                                        WHERE class = 'ap')
                UNION
                SELECT v.id, a.invoice, a.invnumber,
                        eca.meta_number || '--' || e.name,
                        v.batch_id, v.trans_id,
                        a.amount_bc, a.transdate, 'Receivable', v.batch_class
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
                SELECT v.id, ap.invoice, a.source,
                        eca.meta_number || '--'  || e.name,
                        v.batch_id, v.trans_id,
                        sum(CASE WHEN bc.class LIKE 'payment%' THEN a.amount_bc * -1
                             ELSE a.amount_bc  END), a.transdate,
                        CASE WHEN bc.class = 'payment' THEN 'Payment'
                             WHEN bc.class = 'payment_reversal'
                             THEN 'Payment Reversal'
                        END, v.batch_class
                FROM voucher v
                JOIN acc_trans a ON (v.id = a.voucher_id)
                JOIN batch_class bc ON (bc.id = v.batch_class)
                JOIN account_link l ON (a.chart_id = l.account_id)
                JOIN ap ON (ap.id = a.trans_id)
                JOIN entity_credit_account eca
                        ON (ap.entity_credit_account = eca.id)
                JOIN entity e ON (eca.entity_id = e.id)
                WHERE v.batch_id = in_batch_id
                        AND a.voucher_id = v.id
                        AND (bc.class like 'payment%' AND l.description = 'AP')
                GROUP BY v.id, ap.invoice, a.source, eca.meta_number, e.name,
                        v.batch_id, v.trans_id, a.transdate, bc.class

                UNION ALL
                SELECT v.id, ar.invoice, a.source,
                        eca.meta_number || '--'  || e.name,
                        v.batch_id, v.trans_id,
                        CASE WHEN bc.class LIKE 'receipt%' THEN sum(a.amount_bc) * -1
                             ELSE sum(a.amount_bc)  END, a.transdate,
                        CASE WHEN bc.class = 'receipt' THEN 'Receipt'
                             WHEN bc.class = 'receipt_reversal'
                             THEN 'Receipt Reversal'
                        END, v.batch_class
                FROM voucher v
                JOIN acc_trans a ON (v.id = a.voucher_id)
                JOIN batch_class bc ON (bc.id = v.batch_class)
                JOIN account_link l ON (a.chart_id = l.account_id)
                JOIN ar ON (ar.id = a.trans_id)
                JOIN entity_credit_account eca
                        ON (ar.entity_credit_account = eca.id)
                JOIN entity e ON (eca.entity_id = e.id)
                WHERE v.batch_id = in_batch_id
                        AND a.voucher_id = v.id
                        AND (bc.class like 'receipt%' AND l.description = 'AR')
                GROUP BY v.id, ar.invoice, a.source, eca.meta_number, e.name,
                        v.batch_id, v.trans_id, a.transdate, bc.class
                UNION ALL
                SELECT v.id, false, g.reference, g.description,
                        v.batch_id, v.trans_id,
                        sum(a.amount_bc), g.transdate, 'GL', v.batch_class
                FROM voucher v
                JOIN gl g ON (g.id = v.trans_id)
                JOIN acc_trans a ON (v.trans_id = a.trans_id)
                WHERE a.amount_bc > 0
                        AND v.batch_id = in_batch_id
                        AND v.batch_class IN (select id from batch_class
                                        where class = 'gl')
                GROUP BY v.id, g.reference, g.description, v.batch_id,
                        v.trans_id, g.transdate
                ORDER BY 7, 1
$$ language sql;

COMMENT ON FUNCTION voucher__list (in_batch_id integer) IS
$$ Retrieves a list of vouchers and amounts attached to the batch.$$;

DROP TYPE IF EXISTS batch_list_item CASCADE;
CREATE TYPE batch_list_item AS (
    id integer,
    batch_class text,
    control_code text,
    description text,
    created_by text,
    created_on date,
    default_date date,
    transaction_total numeric,
    payment_total numeric,
    lock_success bool
);

CREATE OR REPLACE FUNCTION batch__lock(in_batch_id int)
RETURNS BOOL LANGUAGE SQL SECURITY DEFINER AS
$$
UPDATE batch SET locked_by = (select max(session_id)
                                FROM "session" where users_id = (
                                        select id from users
                                         WHERE username = SESSION_USER))
 WHERE locked_by IS NULL
RETURNING true;
$$;

CREATE OR REPLACE FUNCTION batch__unlock(in_batch_id int)
RETURNS BOOL LANGUAGE sql SECURITY DEFINER AS
$$
UPDATE batch SET locked_by = NULL
 WHERE id = $1 AND locked_by IN (select session_id
                                   from "session" s
                                   join users u on (u.id = s.users_id)
                                  where username = SESSION_USER)
RETURNING true;
$$;

CREATE OR REPLACE FUNCTION
batch__search(in_class_id int, in_description text, in_created_by_eid int,
        in_date_from date, in_date_to date,
        in_amount_gt numeric,
        in_amount_lt numeric, in_approved bool)
RETURNS SETOF batch_list_item AS
$$
                SELECT b.id, c.class, b.control_code, b.description, u.username,
                        b.created_on, b.default_date,
                        sum(
                                CASE WHEN vc.id = 5 AND al.amount_bc < 0 -- GL
                                     THEN al.amount_bc
                                     WHEN vc.id  = 1
                                     THEN ap.amount_bc
                                     WHEN vc.id = 2
                 THEN ar.amount_bc
                                     ELSE 0
                                END) AS transaction_total,
                        sum(
                                CASE WHEN alc.description = 'AR' AND vc.id IN (6, 7)
                                     THEN al.amount_bc
                                     WHEN alc.description = 'AP' AND vc.id IN (3, 4)
                                     THEN al.amount_bc * -1
                                     ELSE 0
                                END
                           ) AS payment_total,
                     batch__lock(b.id)
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
                LEFT JOIN account_link alc ON (al.chart_id = alc.account_id)
                WHERE (c.id = in_class_id OR in_class_id IS NULL) AND
                        (b.description LIKE
                                '%' || in_description || '%' OR
                                in_description IS NULL) AND
                        (in_created_by_eid = b.created_by OR
                                in_created_by_eid IS NULL) AND
                        (
                          (in_approved = false AND approved_on IS NULL)
                          OR (in_approved = true AND approved_on IS NOT NULL)
                          OR in_approved IS NULL
                        )
                        and (in_date_from IS NULL
                                or b.default_date >= in_date_from)
                        and (in_date_to IS NULL
                                or b.default_date <= in_date_to)
                GROUP BY b.id, c.class, b.description, u.username, b.created_on,
                        b.control_code, b.default_date
                HAVING
                        (in_amount_gt IS NULL OR
                        sum(coalesce(ar.amount_bc, ap.amount_bc,
                                al.amount_bc))
                        >= in_amount_gt)
                        AND
                        (in_amount_lt IS NULL OR
                        sum(coalesce(ar.amount_bc, ap.amount_bc,
                                al.amount_bc))
                        <= in_amount_lt)
                ORDER BY b.control_code, b.description

$$ LANGUAGE SQL;

COMMENT ON FUNCTION
batch__search(in_class_id int, in_description text, in_created_by_eid int,
        in_date_from date, in_date_to date,
        in_amount_gt numeric,
        in_amount_lt numeric, in_approved bool) IS
$$Returns a list of batches and amounts processed on the batch.

Nulls match all values.
in_date_from and in_date_to specify date ranges.
in_description is a partial match.
All other criteria are exact matches.
$$;

CREATE OR REPLACE FUNCTION batch_get_class_id (in_type text) returns int AS
$$
SELECT id FROM batch_class WHERE class = $1;
$$ language sql;

COMMENT ON FUNCTION batch_get_class_id (in_type text) IS
$$ returns the batch class id associated with the in_type label provided.$$;

CREATE OR REPLACE FUNCTION batch_get_class_name (in_class_id int) returns text AS
$$
SELECT class FROM batch_class WHERE id = $1;
$$ language sql;

COMMENT ON FUNCTION batch_get_class_name (in_class_id int) IS
$$ returns the batch class name associated with the in_class_id id provided.$$;

CREATE OR REPLACE FUNCTION
batch_search_mini
(in_class_id int, in_description text, in_created_by_eid int, in_approved bool)
RETURNS SETOF batch_list_item AS
$$
                SELECT b.id, c.class, b.control_code, b.description, u.username,
                        b.created_on, b.default_date, NULL::NUMERIC, NULL::numeric, false
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
$$ LANGUAGE SQL;

COMMENT ON FUNCTION batch_search_mini
(in_class_id int, in_description text, in_created_by_eid int, in_approved bool)
IS $$ This performs a simple search of open batches created by the entity_id
in question.  This is used to pull up batches that were currently used so that
they can be picked up and more vouchers added.

NULLs match all values.
in_description is a partial match
All other inouts are exact matches.
$$;

CREATE OR REPLACE FUNCTION
batch_search_empty(in_class_id int, in_description text, in_created_by_eid int,
        in_amount_gt numeric,
        in_amount_lt numeric, in_approved bool)
RETURNS SETOF batch_list_item AS
$$
               SELECT b.id, c.class, b.control_code, b.description, u.username,
                        b.created_on, b.default_date, 0::numeric, 0::numeric, false
                FROM batch b
                JOIN batch_class c ON (b.batch_class_id = c.id)
                JOIN users u ON (u.entity_id = b.created_by)
                LEFT JOIN voucher v ON (v.batch_id = b.id)
               where v.id is null
                     and(u.entity_id = in_created_by_eid
                     or in_created_by_eid is null) and
                     (in_description is null or b.description
                     like '%'  || in_description || '%') and
                     (in_class_id is null or c.id = in_class_id)
            GROUP BY b.id, c.class, b.description, u.username, b.created_on,
                     b.control_code, b.default_date
            ORDER BY b.control_code, b.description


$$ LANGUAGE SQL;

COMMENT ON FUNCTION
batch_search_empty(in_class_id int, in_description text, in_created_by_eid int,
        in_amount_gt numeric,
        in_amount_lt numeric, in_approved bool) IS
$$ This is a full search for the batches, listing them by amount processed.
in_amount_gt and in_amount_lt provide a range to search for.
in_description is a partial match field.
Other fields are exact matches.

NULLs match all values.
$$;


CREATE OR REPLACE FUNCTION batch_post(in_batch_id INTEGER)
returns date AS
$$
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
                WHERE batch_id = in_batch_id);

        -- When approving the AR/AP batch import,
        -- we need to approve the acc_trans line also.
        UPDATE acc_trans SET approved = true
        WHERE trans_id IN (select trans_id FROM voucher
                WHERE batch_id = in_batch_id
                AND batch_class IN (1, 2));

        UPDATE acc_trans SET approved = true
        WHERE voucher_id IN (select id FROM voucher
                WHERE batch_id = in_batch_id
                AND batch_class IN (3, 4, 6, 7));

        UPDATE batch
        SET approved_on = now(),
                approved_by = (select entity_id FROM users
                        WHERE username = SESSION_USER)
        WHERE id = in_batch_id;

        SELECT now()::date;
$$ LANGUAGE SQL SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION batch_post(in_batch_id INTEGER) FROM public;

COMMENT ON FUNCTION batch_post(in_batch_id INTEGER) is
$$ Posts the specified batch to the books.  Only posted batches should show up
on standard financial reports.$$;

CREATE OR REPLACE FUNCTION batch_list_classes() RETURNS SETOF batch_class AS
$$
DECLARE out_val record;
BEGIN
        FOR out_val IN select * from batch_class order by id
        LOOP
                return next out_val;
        END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION batch_list_classes()
IS $$ Returns a list of all batch classes.$$;

-- Move to the admin module and call it from there.
CREATE OR REPLACE FUNCTION batch_get_users() RETURNS SETOF users AS
$$
                SELECT * from users WHERE entity_id IN (select created_by from batch)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION batch_get_users() IS
$$ Returns a sim[ple set of user objects.  This should be renamed so that
it is more obvious it is a general purpose function.$$;

CREATE OR REPLACE FUNCTION batch_create(
in_batch_number text, in_description text, in_batch_class text,
in_batch_date date)
RETURNS int AS
$$
        INSERT INTO
                batch (batch_class_id, default_date, description, control_code,
                        created_by)
        VALUES ((SELECT id FROM batch_class WHERE class = in_batch_class),
                in_batch_date, in_description, in_batch_number,
                        (select entity_id FROM users WHERE username = session_user))
        RETURNING id;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION batch_create(
in_batch_number text, in_description text, in_batch_class text,
in_batch_date date) IS
$$ Inserts the batch into the table.$$;

CREATE OR REPLACE FUNCTION batch_delete(in_batch_id int) RETURNS int AS
$$
DECLARE
        t_transaction_ids int[];
        t_payment_ids int[];
BEGIN
        -- Adjust AR/AP tables for payment and payment reversal vouchers
        -- voucher_id is only set in acc_trans on payment/receipt vouchers and
        -- their reversals. -CT
        perform * from batch where id = in_batch_id and approved_on IS NULL;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Batch not found';
        END IF;

        DELETE FROM ac_tax_form WHERE entry_id IN
               (select entry_id from acc_trans where voucher_id in
                       (select id from voucher where batch_id = in_batch_id)
               );

        WITH deleted_payment_ids AS (
           DELETE FROM payment_links p
            WHERE EXISTS (select 1 from acc_trans a
                           where p.entry_id = a.entry_id
                                 and a.voucher_id IN (select id from voucher
                                                       where batch_id = in_batch_id))
         RETURNING p.payment_id
        )
        SELECT array_agg(payment_id) INTO t_payment_ids
          FROM deleted_payment_ids;

        DELETE FROM payment
         WHERE id = any(t_payment_ids)
               AND NOT EXISTS (select 1 from payment_links
                                where payment_id = id);

        DELETE FROM acc_trans WHERE voucher_id IN
                (select id FROM voucher where batch_id = in_batch_id);

        -- The rest of this function involves the deletion of actual
        -- transactions, vouchers, and batches, and jobs which are in progress.
        -- -CT
        SELECT array_agg(trans_id) INTO t_transaction_ids
        FROM voucher WHERE batch_id = in_batch_id AND batch_class IN (1, 2, 5, 8, 9);

        DELETE FROM ac_tax_form WHERE entry_id in
               (select entry_id from acc_trans
                 where trans_id = any(t_transaction_ids));
        DELETE FROM invoice_tax_form WHERE invoice_id in
               (select id from invoice
                 where trans_id = any(t_transaction_ids));

        DELETE FROM invoice WHERE trans_id = ANY(t_transaction_ids);
        DELETE FROM acc_trans WHERE trans_id = ANY(t_transaction_ids);
        DELETE FROM voucher WHERE batch_id = in_batch_id;
        DELETE FROM batch WHERE id = in_batch_id;
        DELETE FROM ar WHERE id = ANY(t_transaction_ids);
        DELETE FROM ap WHERE id = ANY(t_transaction_ids);
        DELETE FROM gl WHERE id = ANY(t_transaction_ids);
        DELETE FROM transactions WHERE id = ANY(t_transaction_ids);

        RETURN 1;
END;
$$ language plpgsql SECURITY DEFINER;

COMMENT ON  FUNCTION batch_delete(in_batch_id int) IS
$$ If the batch is found and unapproved, deletes it and returns 1.
Otherwise raises an exception.$$;

REVOKE ALL ON FUNCTION batch_delete(int) FROM PUBLIC;

CREATE OR REPLACE FUNCTION voucher__delete(in_voucher_id int)
RETURNS int AS
$$
DECLARE
        voucher_row RECORD;
BEGIN
    SELECT * INTO voucher_row FROM voucher WHERE id = in_voucher_id;
    IF voucher_row.batch_class IN (1, 2, 5) THEN -- GL/AR/AP voucher
        -- Delete *all* lines from acc_trans (in the transaction)
        -- /even/ if not explicitly linked to the voucher
        DELETE FROM ac_tax_form WHERE entry_id IN (
               SELECT entry_id
                 FROM acc_trans
               WHERE trans_id = voucher_row.trans_id);

        -- Note that this query *looks* duplicated with the next section
        -- but it's not! Notably, the WHERE clause in the EXISTS subquery
        -- has a different condition (trans_id vs voucher_id!)
        WITH deleted_links AS (
             DELETE FROM payment_links pl WHERE
                   EXISTS (select 1 from acc_trans a
                            where pl.entry_id    = a.entry_id
                                  and a.trans_id = voucher_row.trans_id)
             RETURNING *
        )
        DELETE FROM payment p
         WHERE id IN (select payment_id from deleted_links)
                AND NOT EXISTS (select 1 from payment_links pl
                                 where pl.payment_id = p.id);
        DELETE FROM acc_trans WHERE trans_id = voucher_row.trans_id;

        -- deletion of the ar/ap/gl row causes removal of the `transactions`
        -- row, which fails if the voucher isn't deleted...
        DELETE FROM voucher WHERE id = voucher_row.id;
        DELETE FROM ar WHERE id = voucher_row.trans_id;
        DELETE FROM ap WHERE id = voucher_row.trans_id;
        DELETE FROM gl WHERE id = voucher_row.trans_id;
    ELSE
        -- Delete only the lines in the transaction which are explicitly
        -- linked to the voucher
        DELETE FROM ac_tax_form WHERE entry_id IN
               (select entry_id from acc_trans
                 where voucher_id = voucher_row.id);

        WITH deleted_links AS (
             DELETE FROM payment_links pl WHERE
                   EXISTS (select 1 from acc_trans a
                            where pl.entry_id    = a.entry_id
                                  and a.voucher_id = voucher_row.id)
             RETURNING *
        )
        DELETE FROM payment p
         WHERE id IN (select payment_id from deleted_links)
                AND NOT EXISTS (select 1 from payment_links pl
                                 where pl.payment_id = p.id);
        DELETE FROM acc_trans where voucher_id = voucher_row.id;
        DELETE FROM voucher WHERE id = voucher_row.id;
    END IF;

    RETURN 1;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

REVOKE ALL ON FUNCTION voucher__delete(int) FROM public;

COMMENT ON FUNCTION voucher__delete(in_voucher_id int) IS
$$ Deletes the specified voucher from the batch.$$;

CREATE OR REPLACE FUNCTION voucher__save
(in_trans_id int, in_batch_id int, in_batch_class int)
LANGUAGE SQL RETURNS voucher AS
$$
    insert into voucher (trans_id, batch_id, batch_class)
     values (in_trans_id, in_batch_id, in_batch_class)
    RETURNING *;
$$;

-- once payments are rewritten, we should get rid of the in_batch_class
-- argument.  In fact we could probably get rid of the field in voucher.
CREATE OR REPLACE FUNCTION voucher__get_by_trans_id(in_trans_id, in_batch_class)
RETURNS SETOF voucher LANGUAGE SQL AS -- SETOF so we don't have a row of nulls
$$
SELECT * FROM voucher 
 WHERE trans_id = in_trans_id AND batch_class = in_batch_class;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
