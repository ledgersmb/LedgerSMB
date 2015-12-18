-- Copyright 2012 The LedgerSMB Core Team.  This file may be re-used in
-- accordance with the GNU GPL version 2 or at your option any later version.
-- Please see your included LICENSE.txt for details

BEGIN;

-- This holds general PNL type report definitions.  The idea is to gather them
-- here so that they share as many common types as possible.  Note that PNL
-- reports do not return total and summary lines.  These must be done by the
-- application handling this.

DROP FUNCTION IF EXISTS pnl__product(in_from_date date, in_to_date date, in_parts_id integer, in_business_units integer[]);
DROP TYPE IF EXISTS pnl_line CASCADE;
CREATE TYPE pnl_line AS (
    account_id int,
    account_number text,
    account_description text,
    account_type char,
    account_category char,
    gifi text,
    gifi_description text,
    contra boolean,
    amount numeric,
    heading_path int[]
);

CREATE OR REPLACE FUNCTION pnl__product(in_from_date date, in_to_date date, in_parts_id integer, in_business_units integer[], in_language text)
  RETURNS SETOF pnl_line LANGUAGE SQL AS
$$
WITH acc_meta AS (
  SELECT a.id, a.accno,
         coalesce(at.description, a.description) as description,
         CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
         ELSE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
         END AS path,
         a.category, 'A'::char as account_type, contra, a.gifi_accno,
         gifi.description as gifi_description
     FROM account a
    INNER JOIN account_heading_tree aht on a.heading = aht.id
     LEFT JOIN gifi ON a.gifi_accno = gifi.accno
     LEFT JOIN (SELECT trans_id, description
                  FROM account_translation
                 WHERE language_code =
                        coalesce($5,
                          (SELECT up.language
                             FROM user_preference up
                       INNER JOIN users ON up.id = users.id
                            WHERE users.username = SESSION_USER))) at
               ON a.id = at.trans_id
   WHERE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
                          IS NOT NULL
         -- legacy: earn_id not configured (yet)
         OR (NOT EXISTS (SELECT 1 FROM defaults
                         WHERE setting_key = 'earn_id'
                           AND value IS NOT NULL)
             AND category IN ('E', 'I'))
),
hdr_meta AS (
   SELECT aht.id, aht.accno,
          coalesce(at.description, aht.description) as description,
          CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
          ELSE array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
          END AS path,
          ahc.derived_category as category,
          'H'::char as account_type, 'f'::boolean as contra
     FROM account_heading_tree aht
    INNER JOIN account_heading_derived_category ahc ON aht.id = ahc.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation
                WHERE language_code =
                       coalesce($5,
                         (SELECT up.language
                            FROM user_preference up
                      INNER JOIN users ON up.id = users.id
                           WHERE users.username = SESSION_USER))) at
              ON aht.id = at.trans_id
    WHERE ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NOT NULL
           AND array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
                           IS NOT NULL)
          -- legacy: earn_id not configured; select headings belonging to
          --    selected accounts
          OR ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NULL
              AND EXISTS (SELECT 1 FROM acc_meta
                                  WHERE aht.id = ANY(acc_meta.path)))
),
acc_balance AS (
   WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($4)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
   )
SELECT ac.chart_id AS id, sum(ac.amount) AS balance
     FROM acc_trans ac
     JOIN invoice i ON i.id = ac.invoice_id
     JOIN account_link l ON l.account_id = ac.chart_id
     JOIN ar ON ar.id = ac.trans_id
LEFT JOIN (select as_array(bu.path) as bu_ids, entry_id
             from business_unit_inv bui
             JOIN bu_tree bu ON bui.bu_id = bu.id
         GROUP BY entry_id) bui ON bui.entry_id = i.id
    WHERE i.parts_id = $3
          AND (ac.transdate >= $1 OR $1 IS NULL)
          AND (ac.transdate <= $2 OR $2 IS NULL)
          AND ar.approved
          AND l.description = 'IC_expense'
          AND ($4 is null or $4 = '{}' OR in_tree($4, bu_ids))
 GROUP BY ac.chart_id
   HAVING sum(ac.amount) <> 0.00
    UNION
   SELECT ac.chart_id,
          sum(i.sellprice * i.qty * (1 - coalesce(i.discount, 0)))
     FROM invoice i
     JOIN acc_trans ac ON ac.invoice_id = i.id
     JOIN ar ON ar.id = ac.trans_id
LEFT JOIN (select as_array(bu.path) as bu_ids, entry_id
             from business_unit_inv bui
             JOIN bu_tree bu ON bui.bu_id = bu.id
         GROUP BY entry_id) bui ON bui.entry_id = i.id
    WHERE i.parts_id = $3
          AND (ac.transdate >= $1 OR $1 IS NULL)
          AND (ac.transdate <= $2 OR $2 IS NULL)
          AND ar.approved
          AND ($4 is null or $4 = '{}' OR in_tree($4, bu_ids))
 GROUP BY ac.chart_id
   HAVING sum(i.sellprice * i.qty * (1 - coalesce(i.discount, 0))) <> 0.00
 ),
hdr_balance AS (
   select ahd.id, sum(balance) as balance
     FROM acc_balance ab
    INNER JOIN account acc ON ab.id = acc.id
    INNER JOIN account_heading_descendant ahd
            ON acc.heading = ahd.descendant_id
    GROUP BY ahd.id
)
   SELECT hm.id, hm.accno, hm.description, hm.account_type, hm.category,
          null::text as gifi, null::text as gifi_description, hm.contra,
          hb.balance, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

DROP FUNCTION IF EXISTS  pnl__income_statement_accrual(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[]);
CREATE OR REPLACE FUNCTION pnl__income_statement_accrual(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[], in_language text)
  RETURNS SETOF pnl_line AS
$BODY$
WITH acc_meta AS (
  SELECT a.id, a.accno,
         coalesce(at.description, a.description) as description,
         CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
         ELSE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
         END AS path,
         a.category, 'A'::char as account_type, contra, a.gifi_accno,
         gifi.description as gifi_description
     FROM account a
    INNER JOIN account_heading_tree aht on a.heading = aht.id
     LEFT JOIN gifi ON a.gifi_accno = gifi.accno
     LEFT JOIN (SELECT trans_id, description
                  FROM account_translation
                 WHERE language_code =
                        coalesce($5,
                          (SELECT up.language
                             FROM user_preference up
                       INNER JOIN users ON up.id = users.id
                            WHERE users.username = SESSION_USER))) at
               ON a.id = at.trans_id
   WHERE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
                          IS NOT NULL
         -- legacy: earn_id not configured (yet)
         OR (NOT EXISTS (SELECT 1 FROM defaults
                         WHERE setting_key = 'earn_id'
                               AND value IS NOT NULL)
             AND category IN ('E', 'I'))
),
hdr_meta AS (
   SELECT aht.id, aht.accno,
          coalesce(at.description, aht.description) as description,
          CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
          ELSE array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
          END AS path,
          ahc.derived_category as category,
          'H'::char as account_type, 'f'::boolean as contra
     FROM account_heading_tree aht
    INNER JOIN account_heading_derived_category ahc ON aht.id = ahc.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation
                WHERE language_code =
                       coalesce($5,
                         (SELECT up.language
                            FROM user_preference up
                      INNER JOIN users ON up.id = users.id
                           WHERE users.username = SESSION_USER))) at
              ON aht.id = at.trans_id
    WHERE ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NOT NULL
           AND array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
                           IS NOT NULL)
          -- legacy: earn_id not configured; select headings belonging to
          --    selected accounts
          OR ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NULL
              AND EXISTS (SELECT 1 FROM acc_meta
                                  WHERE aht.id = ANY(acc_meta.path)))
),
acc_balance AS (
   WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($4)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
   )
   SELECT ac.chart_id AS id, sum(ac.amount) AS balance
     FROM acc_trans ac
    INNER JOIN tx_report gl ON ac.trans_id = gl.id AND gl.approved
     LEFT JOIN (SELECT array_agg(path) AS bu_ids, entry_id
                  FROM business_unit_ac buac
                 INNER JOIN bu_tree ON bu_tree.id = buac.bu_id
                 GROUP BY buac.entry_id) bu
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved
          AND ($1 IS NULL OR ac.transdate >= $1)
          AND ($2 IS NULL OR ac.transdate <= $2)
          AND ($4 = '{}'
              OR $4 is null or in_tree($4, bu_ids))
           AND ($3 = 'none'
               OR ($3 = 'all'
                   AND NOT EXISTS (SELECT * FROM yearend
                                    WHERE trans_id = gl.id))
               OR ($3 = 'last'
                   AND NOT EXISTS (SELECT 1 FROM yearend
                                   HAVING max(trans_id) = gl.id))
              )
   GROUP BY ac.chart_id
     HAVING sum(ac.amount) <> 0.00
 ),
hdr_balance AS (
   select ahd.id, sum(balance) as balance
     FROM acc_balance ab
    INNER JOIN account acc ON ab.id = acc.id
    INNER JOIN account_heading_descendant ahd
            ON acc.heading = ahd.descendant_id
    GROUP BY ahd.id
)
   SELECT hm.id, hm.accno, hm.description, hm.account_type, hm.category,
          null::text as gifi, null::text as gifi_description, hm.contra,
          hb.balance, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$BODY$
  LANGUAGE sql;


DROP FUNCTION IF EXISTS pnl__income_statement_cash(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[]);
CREATE OR REPLACE FUNCTION pnl__income_statement_cash(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[], in_language text)
  RETURNS SETOF pnl_line LANGUAGE SQL AS
$$
WITH acc_meta AS (
  SELECT a.id, a.accno,
         coalesce(at.description, a.description) as description,
         CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
         ELSE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
         END AS path,
         a.category, 'A'::char as account_type, contra, a.gifi_accno,
         gifi.description as gifi_description
     FROM account a
    INNER JOIN account_heading_tree aht on a.heading = aht.id
     LEFT JOIN gifi ON a.gifi_accno = gifi.accno
     LEFT JOIN (SELECT trans_id, description
                  FROM account_translation
                 WHERE language_code =
                        coalesce($5,
                          (SELECT up.language
                             FROM user_preference up
                       INNER JOIN users ON up.id = users.id
                            WHERE users.username = SESSION_USER))) at
               ON a.id = at.trans_id
   WHERE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
                          IS NOT NULL
         -- legacy: earn_id not configured (yet)
         OR (NOT EXISTS (SELECT 1 FROM defaults
                         WHERE setting_key = 'earn_id'
                           AND value IS NOT NULL)
             AND category IN ('E', 'I'))
),
hdr_meta AS (
   SELECT aht.id, aht.accno,
          coalesce(at.description, aht.description) as description,
          CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
          ELSE array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
          END AS path,
          ahc.derived_category as category,
          'H'::char as account_type, 'f'::boolean as contra
     FROM account_heading_tree aht
    INNER JOIN account_heading_derived_category ahc ON aht.id = ahc.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation
                WHERE language_code =
                       coalesce($5,
                         (SELECT up.language
                            FROM user_preference up
                      INNER JOIN users ON up.id = users.id
                           WHERE users.username = SESSION_USER))) at
              ON aht.id = at.trans_id
    WHERE ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NOT NULL
           AND array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
                           IS NOT NULL)
          -- legacy: earn_id not configured; select headings belonging to
          --    selected accounts
          OR ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NULL
              AND EXISTS (SELECT 1 FROM acc_meta
                                  WHERE aht.id = ANY(acc_meta.path)))
),
acc_balance AS (
WITH RECURSIVE bu_tree (id, parent, path) AS (
      SELECT id, null, row(array[id])::tree_record FROM business_unit
       WHERE id = any($4)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
)
   SELECT ac.chart_id AS id, sum(ac.amount * ca.portion) AS balance
     FROM acc_trans ac
     JOIN tx_report gl ON ac.trans_id = gl.id AND gl.approved
     JOIN (SELECT id, sum(portion) as portion
             FROM cash_impact ca
            WHERE ($1 IS NULL OR ca.transdate >= $1)
                  AND ($2 IS NULL OR ca.transdate <= $2)
           GROUP BY id
          ) ca ON gl.id = ca.id
LEFT JOIN (select array_agg(path) as bu_ids, entry_id
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id
         GROUP BY entry_id) bu
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved
          AND ($4 = '{}'
              OR $4 is null or in_tree($4, bu_ids))
          AND ($3 = 'none'
               OR ($3 = 'all'
                   AND NOT EXISTS (SELECT * FROM yearend WHERE trans_id = gl.id
                   ))
               OR ($3 = 'last'
                   AND NOT EXISTS (SELECT 1 FROM yearend
                                   HAVING max(trans_id) = gl.id))
              )
 GROUP BY ac.chart_id
   HAVING sum(ac.amount * ca.portion) <> 0.00
 ),
hdr_balance AS (
   select ahd.id, sum(balance) as balance
     FROM acc_balance ab
    INNER JOIN account acc ON ab.id = acc.id
    INNER JOIN account_heading_descendant ahd
            ON acc.heading = ahd.descendant_id
    GROUP BY ahd.id
)
   SELECT hm.id, hm.accno, hm.description, hm.account_type, hm.category,
          null::text as gifi, null::text as gifi_description, hm.contra,
          hb.balance, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

DROP FUNCTION IF EXISTS pnl__invoice(in_id integer);
CREATE OR REPLACE FUNCTION pnl__invoice(in_id integer, in_language text)
  RETURNS SETOF pnl_line LANGUAGE SQL AS
$$
WITH acc_meta AS (
  SELECT a.id, a.accno,
         coalesce(at.description, a.description) as description,
         CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
         ELSE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
         END AS path,
         a.category, 'A'::char as account_type, contra, a.gifi_accno,
         gifi.description as gifi_description
     FROM account a
    INNER JOIN account_heading_tree aht on a.heading = aht.id
     LEFT JOIN gifi ON a.gifi_accno = gifi.accno
     LEFT JOIN (SELECT trans_id, description
                  FROM account_translation
                 WHERE language_code =
                        coalesce($2,
                          (SELECT up.language
                             FROM user_preference up
                       INNER JOIN users ON up.id = users.id
                            WHERE users.username = SESSION_USER))) at
               ON a.id = at.trans_id
   WHERE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
                          IS NOT NULL
         -- legacy: earn_id not configured (yet)
         OR (NOT EXISTS (SELECT 1 FROM defaults
                         WHERE setting_key = 'earn_id'
                           AND value IS NOT NULL)
             AND category IN ('E', 'I'))
),
hdr_meta AS (
   SELECT aht.id, aht.accno,
          coalesce(at.description, aht.description) as description,
          CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
          ELSE array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
          END AS path,
          ahc.derived_category as category,
          'H'::char as account_type, 'f'::boolean as contra
     FROM account_heading_tree aht
    INNER JOIN account_heading_derived_category ahc ON aht.id = ahc.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation
                WHERE language_code =
                       coalesce($2,
                         (SELECT up.language
                            FROM user_preference up
                      INNER JOIN users ON up.id = users.id
                           WHERE users.username = SESSION_USER))) at
              ON aht.id = at.trans_id
    WHERE ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NOT NULL
           AND array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
                           IS NOT NULL)
          -- legacy: earn_id not configured; select headings belonging to
          --    selected accounts
          OR ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NULL
              AND EXISTS (SELECT 1 FROM acc_meta
                                  WHERE aht.id = ANY(acc_meta.path)))
),
acc_balance AS (
SELECT ac.chart_id AS id, sum(ac.amount) AS balance
  FROM acc_trans ac
 WHERE ac.approved AND ac.trans_id = $1
 GROUP BY ac.chart_id
 ),
hdr_balance AS (
   select ahd.id, sum(balance) as balance
     FROM acc_balance ab
    INNER JOIN account acc ON ab.id = acc.id
    INNER JOIN account_heading_descendant ahd
            ON acc.heading = ahd.descendant_id
    GROUP BY ahd.id
)
   SELECT hm.id, hm.accno, hm.description, hm.account_type, hm.category,
          null::text as gifi, null::text as gifi_description, hm.contra,
          hb.balance, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

DROP FUNCTION IF EXISTS pnl__customer(in_id integer, in_from_date date, in_to_date date);
CREATE OR REPLACE FUNCTION pnl__customer(in_id integer, in_from_date date, in_to_date date, in_language text)
  RETURNS SETOF pnl_line LANGUAGE SQL AS
$$
WITH acc_meta AS (
  SELECT a.id, a.accno,
         coalesce(at.description, a.description) as description,
         CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
         ELSE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
         END AS path,
         a.category, 'A'::char as account_type, contra, a.gifi_accno,
         gifi.description as gifi_description
     FROM account a
    INNER JOIN account_heading_tree aht on a.heading = aht.id
     LEFT JOIN gifi ON a.gifi_accno = gifi.accno
     LEFT JOIN (SELECT trans_id, description
                  FROM account_translation
                 WHERE language_code =
                        coalesce($4,
                          (SELECT up.language
                             FROM user_preference up
                       INNER JOIN users ON up.id = users.id
                            WHERE users.username = SESSION_USER))) at
               ON a.id = at.trans_id
   WHERE array_splice_from((SELECT value::int FROM defaults
                             WHERE setting_key = 'earn_id'),aht.path)
                          IS NOT NULL
         -- legacy: earn_id not configured (yet)
         OR (NOT EXISTS (SELECT 1 FROM defaults
                         WHERE setting_key = 'earn_id'
                           AND value IS NOT NULL)
             AND category IN ('E', 'I'))
),
hdr_meta AS (
   SELECT aht.id, aht.accno,
          coalesce(at.description, aht.description) as description,
          CASE WHEN (SELECT value::int FROM defaults where setting_key = 'earn_id') IS NULL THEN aht.path
          ELSE array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
          END AS path,
          ahc.derived_category as category,
          'H'::char as account_type, 'f'::boolean as contra
     FROM account_heading_tree aht
    INNER JOIN account_heading_derived_category ahc ON aht.id = ahc.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation
                WHERE language_code =
                       coalesce($4,
                         (SELECT up.language
                            FROM user_preference up
                      INNER JOIN users ON up.id = users.id
                           WHERE users.username = SESSION_USER))) at
              ON aht.id = at.trans_id
    WHERE ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NOT NULL
           AND array_splice_from((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id'),aht.path)
                           IS NOT NULL)
          -- legacy: earn_id not configured; select headings belonging to
          --    selected accounts
          OR ((SELECT value::int FROM defaults
                              WHERE setting_key = 'earn_id') IS NULL
              AND EXISTS (SELECT 1 FROM acc_meta
                                  WHERE aht.id = ANY(acc_meta.path)))
),
acc_balance AS (
WITH gl (id) AS
 ( SELECT id FROM ap WHERE approved is true AND entity_credit_account = $1
UNION ALL
   SELECT id FROM ar WHERE approved is true AND entity_credit_account = $1
)
SELECT ac.chart_id AS id, sum(ac.amount) AS balance
  FROM acc_trans ac
  JOIN gl ON ac.trans_id = gl.id
 WHERE ac.approved is true
          AND ($2 IS NULL OR ac.transdate >= $2)
          AND ($3 IS NULL OR ac.transdate <= $3)
 GROUP BY ac.chart_id
   HAVING sum(ac.amount) <> 0.00
 ),
hdr_balance AS (
   select ahd.id, sum(balance) as balance
     FROM acc_balance ab
    INNER JOIN account acc ON ab.id = acc.id
    INNER JOIN account_heading_descendant ahd
            ON acc.heading = ahd.descendant_id
    GROUP BY ahd.id
)
   SELECT hm.id, hm.accno, hm.description, hm.account_type, hm.category,
          null::text as gifi, null::text as gifi_description, hm.contra,
          hb.balance, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
