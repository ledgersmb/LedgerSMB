
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

CREATE OR REPLACE FUNCTION voucher__list (in_batch_id integer)
RETURNS SETOF voucher_list AS
$$
SELECT v.id, a.invoice, a.invnumber,
       eca.meta_number || '--' || e.name,
       v.batch_id, v.trans_id,
       a.amount_bc, txn.transdate,
       bc.class, v.batch_class
  FROM voucher v
         JOIN (
           select trans_id, invoice, invnumber, amount_bc,
                  entity_credit_account, open_item_id
             from ap
            union all
           select trans_id, invoice, invnumber, amount_bc,
                  entity_credit_account, open_item_id
             from ar
         ) a
             ON (v.trans_id = a.trans_id)
         JOIN transactions txn
             ON a.trans_id = txn.id
         JOIN entity_credit_account eca
             ON (eca.id = a.entity_credit_account)
         JOIN entity e
             ON (eca.entity_id = e.id)
         JOIN batch_class bc
             ON bc.id = v.batch_class
 WHERE v.batch_id = in_batch_id
       UNION ALL
SELECT v.id, a.invoice, ac.source,
       eca.meta_number || '--'  || e.name,
       v.batch_id, v.trans_id,
       sum(ac.amount_bc * -1), ac.transdate,
       bc.class, v.batch_class
FROM voucher v
       JOIN acc_trans ac
           ON v.id = ac.voucher_id
       JOIN batch_class bc
           ON bc.id = v.batch_class
       JOIN (
         select invoice, open_item_id, entity_credit_account
           from ap
          union all
         select invoice, open_item_id, entity_credit_account
           from ar
       ) a
           ON a.open_item_id = ac.open_item_id
       JOIN entity_credit_account eca
           ON a.entity_credit_account = eca.id
       JOIN entity e
           ON eca.entity_id = e.id
 WHERE v.batch_id = in_batch_id
  -- no need to select batch_class: ac.voucher_id == null for all but classes 3,4,6,7
   AND ac.voucher_id = v.id
 GROUP BY v.id, a.invoice, ac.source, eca.meta_number, e.name,
          v.batch_id, v.trans_id, ac.transdate, bc.class

 UNION ALL
SELECT v.id, false, txn.reference, txn.description,
       v.batch_id, v.trans_id,
       sum(a.amount_bc), txn.transdate, 'GL', v.batch_class
  FROM voucher v
         JOIN transactions txn
             ON (txn.id = v.trans_id)
         JOIN acc_trans a
             ON (v.trans_id = a.trans_id)
 WHERE a.amount_bc > 0
   AND v.batch_id = in_batch_id
   AND exists (select 1
                 from gl
                where gl.id = v.trans_id)
 GROUP BY v.id, txn.reference, txn.description, v.batch_id,
          v.trans_id, txn.transdate
 ORDER BY transdate, id

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
 WHERE id = $1
   AND locked_by IN (select session_id
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
         CASE
         WHEN al.amount_bc > 0
           THEN al.amount_bc
         ELSE 0
         END) AS transaction_total,
       batch__lock(b.id)
  FROM batch b
         JOIN batch_class c
             ON (b.batch_class_id = c.id)
         LEFT JOIN users u
             ON (u.entity_id = b.created_by)
         LEFT JOIN voucher v
             ON (v.batch_id = b.id)
         LEFT JOIN batch_class vc
             ON (v.batch_class = vc.id)
         LEFT JOIN acc_trans al
             ON v.trans_id = al.trans_id
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
                        sum(
                          CASE WHEN al.amount_bc > 0
                            THEN al.amount_bc
                          ELSE 0
                          END) >= in_amount_gt)
                        AND
                        (in_amount_lt IS NULL OR
                        sum(
                          CASE WHEN al.amount_bc > 0
                            THEN al.amount_bc
                          ELSE 0
                          END) <= in_amount_lt)
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
       b.created_on, b.default_date, NULL::NUMERIC, false
  FROM batch b
         JOIN batch_class c
             ON (b.batch_class_id = c.id)
         LEFT JOIN users u
             ON (u.entity_id = b.created_by)
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
       b.created_on, b.default_date, 0::numeric, false
  FROM batch b
         JOIN batch_class c
             ON (b.batch_class_id = c.id)
         JOIN users u
             ON (u.entity_id = b.created_by)
         LEFT JOIN voucher v
             ON (v.batch_id = b.id)
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
UPDATE transactions txn
   SET approved = true
       FROM voucher v
 WHERE txn.id = v.trans_id
       AND v.batch_id = in_batch_id;

-- When approving the AR/AP batch import,
-- we need to approve the acc_trans line also.
UPDATE acc_trans ac
   SET approved = true
       FROM voucher v
 WHERE ac.trans_id = v.trans_id
       AND v.batch_id = in_batch_id;

UPDATE batch
   SET approved_on = now(),
       approved_by = (select entity_id
                        FROM users
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
  FOR out_val IN
    select *
      from batch_class
     order by id
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
INSERT INTO batch (batch_class_id,
                   default_date, description, control_code,
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
BEGIN
  perform *
     from batch
    where id = in_batch_id
      and approved_on IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Batch not found';
  END IF;

  SELECT array_agg(trans_id) INTO t_transaction_ids
    FROM voucher
   WHERE batch_id = in_batch_id;

  DELETE FROM ac_tax_form
   WHERE entry_id in
         (select entry_id from acc_trans
           where trans_id = any(t_transaction_ids));

  DELETE FROM invoice_tax_form
   WHERE invoice_id in
         (select id from invoice
           where trans_id = any(t_transaction_ids));

  DELETE FROM invoice
   WHERE trans_id = ANY(t_transaction_ids);
  DELETE FROM acc_trans
   WHERE trans_id = ANY(t_transaction_ids);
  DELETE FROM voucher
   WHERE batch_id = in_batch_id;
  DELETE FROM batch
   WHERE id = in_batch_id;
  /* deleting from transactions means deleting from
     a whole slew of other tables too; check the schema for ON DELETE CASCADE */
  DELETE FROM transactions
   WHERE id = ANY(t_transaction_ids);

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

  DELETE FROM ac_tax_form atf
              USING acc_trans ac
   WHERE atf.entry_id = ac.entry_id
     AND ac.trans_id = voucher_row.trans_id;

  DELETE FROM acc_trans
   WHERE trans_id = voucher_row.trans_id;

  DELETE FROM voucher
   WHERE id = voucher_row.id;

  /* deletes from ar/ap/gl/payments and a slew of other tables */
  DELETE FROM transactions
   WHERE id = voucher_row.trans_id;

  RETURN 1;
END;

$$ LANGUAGE PLPGSQL SECURITY DEFINER;

REVOKE ALL ON FUNCTION voucher__delete(int) FROM public;

COMMENT ON FUNCTION voucher__delete(in_voucher_id int) IS
$$ Deletes the specified voucher from the batch.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
