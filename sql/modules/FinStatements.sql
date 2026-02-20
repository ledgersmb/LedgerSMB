
set client_min_messages = 'warning';


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
DROP TYPE IF EXISTS financial_statement_line CASCADE;
CREATE TYPE financial_statement_line AS (
    account_id int,
    account_number text,
    account_description text,
    account_type char,
    account_category char,
    gifi text,
    gifi_description text,
    contra boolean,
    amount numeric,
    curr char(3),
    amount_tc numeric,
    heading_path int[]
);

CREATE OR REPLACE FUNCTION pnl__product(in_from_date date, in_to_date date, in_parts_id integer, in_business_units integer[], in_language text)
  RETURNS SETOF financial_statement_line LANGUAGE SQL AS
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
                        coalesce(in_language, preference__get('language'))) at
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
                       coalesce(in_language, preference__get('language'))) at
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
       WHERE id = any(in_business_units)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
   )
SELECT ac.chart_id AS id, sum(ac.amount_bc) AS balance
     FROM acc_trans ac
     JOIN invoice i ON i.id = ac.invoice_id
     JOIN account_link l ON l.account_id = ac.chart_id
     JOIN ar ON ar.id = ac.trans_id
     JOIN transactions txn ON txn.id = ar.id
LEFT JOIN (select array_agg(bu.path) as bu_ids, entry_id
             from business_unit_inv bui
             JOIN bu_tree bu ON bui.bu_id = bu.id
         GROUP BY entry_id) bui ON bui.entry_id = i.id
    WHERE i.parts_id = in_parts_id
          AND (ac.transdate >= in_from_date OR in_from_date IS NULL)
          AND (ac.transdate <= in_to_date OR in_to_date IS NULL)
          AND txn.approved
          AND l.description = 'IC_expense'
          AND (in_business_units is null or in_business_units = '{}' OR in_tree(in_business_units, bu_ids))
 GROUP BY ac.chart_id
   HAVING sum(ac.amount_bc) <> 0.00
    UNION
   SELECT ac.chart_id,
          sum(i.sellprice * i.qty * (1 - coalesce(i.discount, 0)))
     FROM invoice i
     JOIN acc_trans ac ON ac.invoice_id = i.id
     JOIN transactions txn ON txn.id = ac.trans_id
LEFT JOIN (select array_agg(bu.path) as bu_ids, entry_id
             from business_unit_inv bui
             JOIN bu_tree bu ON bui.bu_id = bu.id
         GROUP BY entry_id) bui ON bui.entry_id = i.id
    WHERE i.parts_id = in_parts_id
          AND (ac.transdate >= in_from_date OR in_from_date IS NULL)
          AND (ac.transdate <= in_to_date OR in_to_date IS NULL)
          AND txn.approved
          AND (in_business_units is null or in_business_units = '{}' OR in_tree(in_business_units, bu_ids))
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
          hb.balance, null::char(3) as curr, null::numeric as amount_tc, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance,
          null::char(3) as curr, null::numeric as amount_tc, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

DROP FUNCTION IF EXISTS pnl__income_statement_accrual(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[]);
DROP FUNCTION IF EXISTS pnl__income_statement_accrual(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[], in_language text);
CREATE OR REPLACE FUNCTION pnl__income_statement_accrual(in_from_date date, in_to_date date, in_business_units integer[], in_language text)
  RETURNS SETOF financial_statement_line AS
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
                        coalesce(in_language, preference__get('language'))) at
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
                       coalesce(in_language, preference__get('language'))) at
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
       WHERE id = any(in_business_units)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
   )
   SELECT ac.chart_id AS id, sum(ac.amount_bc) AS balance
     FROM acc_trans ac
    INNER JOIN transactions txn ON ac.trans_id = txn.id AND txn.approved
     LEFT JOIN (SELECT array_agg(path) AS bu_ids, entry_id
                  FROM business_unit_ac buac
                 INNER JOIN bu_tree ON bu_tree.id = buac.bu_id
                 GROUP BY buac.entry_id) bu
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved
      AND (in_from_date IS NULL OR ac.transdate >= in_from_date)
      AND (in_from_date IS NULL OR in_to_date IS NULL
           OR NOT EXISTS (select 1 from yearend ye
                           where in_from_date < ye.transdate
                             and ye.transdate < in_to_date
                             and not ye.reversed
                             and ac.trans_id = ye.trans_id))
      AND (in_to_date IS NULL OR ac.transdate <= in_to_date)
      AND (in_business_units IS NULL OR in_business_units = '{}'
           OR in_tree(in_business_units, bu_ids))
      AND (in_to_date is null
           OR (ac.transdate <= in_to_date
               AND ac.trans_id IS DISTINCT FROM (SELECT trans_id
                                                   FROM yearend
                                                  WHERE transdate = in_to_date
                                                    AND NOT reversed)))
   GROUP BY ac.chart_id
     HAVING sum(ac.amount_bc) <> 0.00
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
          hb.balance, null::char(3) as curr, null::numeric as amount_tc, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
    UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance,
          null::char(3) as curr, null::numeric as amount_tc, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$BODY$
  LANGUAGE sql;


DROP FUNCTION IF EXISTS pnl__income_statement_cash(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[]);
DROP FUNCTION IF EXISTS pnl__income_statement_cash(in_from_date date, in_to_date date, in_ignore_yearend text, in_business_units integer[], in_language text);
CREATE OR REPLACE FUNCTION pnl__income_statement_cash(in_from_date date, in_to_date date, in_business_units integer[], in_language text)
  RETURNS SETOF financial_statement_line LANGUAGE SQL AS
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
                        coalesce(in_language, preference__get('language'))) at
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
                       coalesce(in_language, preference__get('language'))) at
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
       WHERE id = any(in_business_units)
      UNION ALL
      SELECT bu.id, parent, row((path).t || bu.id)::tree_record
        FROM business_unit bu
        JOIN bu_tree ON bu.parent_id = bu_tree.id
)
   SELECT ac.chart_id AS id, sum(ac.amount_bc * ca.portion) AS balance
     FROM acc_trans ac
     JOIN transactions txn ON ac.trans_id = txn.id AND txn.approved
     JOIN (SELECT id, sum(portion) as portion
             FROM cash_impact ca
            WHERE (in_from_date IS NULL OR ca.transdate >= in_from_date)
                  AND (in_to_date IS NULL OR ca.transdate <= in_to_date)
           GROUP BY id
          ) ca ON txn.id = ca.id
LEFT JOIN (select array_agg(path) as bu_ids, entry_id
             FROM business_unit_ac buac
             JOIN bu_tree ON bu_tree.id = buac.bu_id
         GROUP BY entry_id) bu
          ON (ac.entry_id = bu.entry_id)
    WHERE ac.approved
      AND (in_business_units = '{}'
           OR in_business_units is null or in_tree(in_business_units, bu_ids))
      AND (in_from_date IS NULL OR in_to_date IS NULL
           OR NOT EXISTS (select 1 from yearend ye
                           where in_from_date < ye.transdate
                             and ye.transdate < in_to_date
                             and not ye.reversed
                             and ac.trans_id = ye.trans_id))
      AND (in_to_date is null
           OR (ac.transdate <= in_to_date
               AND ac.trans_id IS DISTINCT FROM (SELECT trans_id
                                                   FROM yearend
                                                  WHERE transdate = in_to_date
                                                    AND NOT reversed)))
 GROUP BY ac.chart_id
   HAVING sum(ac.amount_bc * ca.portion) <> 0.00
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
          hb.balance, null::char(3) as curr, null::numeric as amount_tc, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance,
          null::char(3) as curr, null::numeric as amount_tc, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

DROP FUNCTION IF EXISTS pnl__invoice(in_id integer);
CREATE OR REPLACE FUNCTION pnl__invoice(in_id integer, in_language text)
  RETURNS SETOF financial_statement_line LANGUAGE SQL AS
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
                        coalesce(in_language, preference__get('language'))) at
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
                       coalesce(in_language, preference__get('language'))) at
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
SELECT ac.chart_id AS id, sum(ac.amount_bc) AS balance
  FROM acc_trans ac
 WHERE ac.approved AND ac.trans_id = in_id
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
          hb.balance, null::char(3) as curr, null::numeric as amount_tc, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance,
          null::char(3) as curr, null::numeric as amount_tc, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;

DROP FUNCTION IF EXISTS pnl__customer(in_id integer, in_from_date date, in_to_date date);
CREATE OR REPLACE FUNCTION pnl__customer(in_id integer, in_from_date date, in_to_date date, in_language text)
  RETURNS SETOF financial_statement_line LANGUAGE SQL AS
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
                        coalesce(in_language, preference__get('language'))) at
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
                       coalesce(in_language, preference__get('language'))) at
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
WITH aa (id) AS
 ( SELECT id FROM ap JOIN transactions USING (id) WHERE approved is true AND entity_credit_account = in_id
UNION ALL
   SELECT id FROM ar JOIN transactions USING (id) WHERE approved is true AND entity_credit_account = in_id
)
SELECT ac.chart_id AS id, sum(ac.amount_bc) AS balance
  FROM acc_trans ac
  JOIN aa ON ac.trans_id = aa.id
 WHERE ac.approved is true
          AND (in_from_date IS NULL OR ac.transdate >= in_from_date)
          AND (in_to_date IS NULL OR ac.transdate <= in_to_date)
 GROUP BY ac.chart_id
   HAVING sum(ac.amount_bc) <> 0.00
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
          hb.balance, null::char(3) as curr, null::numeric as amount_tc, hm.path
     FROM hdr_meta hm
    INNER JOIN hdr_balance hb ON hm.id = hb.id
   UNION
   SELECT am.id, am.accno, am.description, am.account_type, am.category,
          gifi_accno as gifi, gifi_description, am.contra, ab.balance,
          null::char(3) as curr, null::numeric as amount_tc, am.path
     FROM acc_meta am
    INNER JOIN acc_balance ab on am.id = ab.id
$$;


DROP FUNCTION IF EXISTS report__balance_sheet(in_to_date date);
DROP FUNCTION IF EXISTS report__balance_sheet(in_to_date date, in_language text);
CREATE OR REPLACE FUNCTION report__balance_sheet(in_to_date date,
                                                 in_language text,
                                                 in_timing text)
RETURNS SETOF financial_statement_line LANGUAGE SQL AS
$$
WITH chkpoint_date AS (
   SELECT coalesce(max(end_date),
                   (select min(transdate)-'1 day'::interval
                     from acc_trans)) AS end_date
     FROM account_checkpoint
    WHERE (in_to_date IS NULL
           OR (end_date < in_to_date)
           OR ((end_date = in_to_date)
               and (in_timing is null or in_timing='ultimo')
               and not exists (select 1 from yearend
                                where transdate = in_to_date
                                      and not reversed)))
),
hdr_meta AS (
   SELECT aht.id, aht.accno, coalesce(at.description, aht.description) as description,
          aht.path,
          ahc.derived_category as category, 'H'::char as account_type,
          'f'::boolean as contra
     FROM account_heading_tree aht
    INNER JOIN account_heading_derived_category ahc ON aht.id = ahc.id
    LEFT JOIN (SELECT trans_id, description
                 FROM account_translation
                WHERE language_code =
                       coalesce(in_language, preference__get('language'))) at
              ON aht.id = at.trans_id
     WHERE array_endswith((SELECT value::int FROM defaults
                            WHERE setting_key = 'earn_id'), aht.path)
           -- legacy (no earn_id) returns all headers
           OR (NOT aht.path @> ARRAY[(SELECT value::int FROM defaults
                                      WHERE setting_key = 'earn_id')])
),
acc_meta AS (
  SELECT a.id, a.accno, coalesce(at.description, a.description) as description,
         a.category, 'A'::char as account_type, contra,
         a.gifi_accno, gifi.description as gifi_description
     FROM account a
     LEFT JOIN gifi ON a.gifi_accno = gifi.accno
     LEFT JOIN (SELECT trans_id, description
                  FROM account_translation
                 WHERE language_code =
                        coalesce(in_language, preference__get('language'))) at
               ON a.id = at.trans_id
),
acc_balance AS (
  SELECT b.id,
         case when a.heading_negative_balance is not null
           then (
             case when ((b.balance > 0 and a.category = 'A')
                        or (b.balance < 0 and a.category = 'L'))
               then a.heading_negative_balance
             else a.heading
             end)
         else a.heading
         end as heading,
         case when a.heading_negative_balance is not null
           then (
             case when ((b.balance > 0 and a.category = 'A')
                        or (b.balance < 0 and a.category = 'L'))
               then nht.path
             else aht.path
             end)
         else aht.path
         end as path,
         case when a.heading_negative_balance is not null
           then (
             case when (b.balance > 0 and a.category = 'A')
               then 'L'
             when (b.balance < 0 and a.category = 'L')
               then 'A'
             else a.category
             end)
         else a.category
         end as category,
         balance,
         curr,
         amount_tc
    FROM (
      SELECT bal.id, sum(bal.balance) as balance, curr, sum(bal.amount_tc) as amount_tc
        FROM (
          SELECT account_id as id, amount_bc as balance, curr, amount_tc
            FROM account_checkpoint
           WHERE end_date = (select end_date from chkpoint_date)

           UNION ALL
          SELECT ac.chart_id as id, ac.amount_bc as balance, ac.curr, ac.amount_tc
            FROM acc_trans ac
                   JOIN transactions t ON t.approved AND t.id = ac.trans_id
           WHERE t.approved AND
                 ac.transdate > (select end_date from chkpoint_date) AND
                 (in_to_date is null
                 OR ((in_timing is null OR in_timing='ultimo')
                     AND ac.transdate <= in_to_date
                     AND ac.trans_id IS DISTINCT FROM (SELECT trans_id
                                                         FROM yearend
                                                        WHERE transdate = in_to_date
                                                          AND NOT reversed))
                                                          OR (in_timing='primo'
                                                              AND ac.transdate < in_to_date))
        ) bal
       GROUP BY bal.id, curr
      HAVING sum(bal.balance) <> 0.00
    ) b
           INNER JOIN account a
               ON b.id = a.id
           INNER JOIN account_heading_tree aht on a.heading = aht.id
           LEFT JOIN account_heading_tree nht on a.heading_negative_balance = nht.id
),
hdr_balance AS (
   select id, sum(balance) as balance, curr, sum(amount_tc) as amount_tc
     FROM (
       select UNNEST(path) as id, balance, curr, amount_tc from acc_balance ab
     ) a
    GROUP BY id, curr
)
  SELECT * FROM (
    SELECT hm.id, hm.accno, hm.description, hm.account_type, hm.category,
           null::text as gifi_accno,
           null::text as gifi_description, hm.contra,
           hb.balance, hb.curr as curr, hb.amount_tc as amount_tc, hm.path
      FROM hdr_meta hm
             INNER JOIN hdr_balance hb ON hm.id = hb.id
     UNION
    SELECT am.id, am.accno, am.description, am.account_type, ab.category,
           am.gifi_accno, am.gifi_description, am.contra,
           ab.balance, ab.curr as curr, ab.amount_tc as amount_tc, ab.path
      FROM acc_meta am
             INNER JOIN acc_balance ab on am.id = ab.id
  ) bs
  WHERE array_endswith((SELECT value::int FROM defaults
                         WHERE setting_key = 'earn_id'), bs.path)
     -- legacy (no earn_id) returns all accounts; bug?
     OR (NOT bs.path @> ARRAY[(SELECT value::int FROM defaults
                                WHERE setting_key = 'earn_id')])
$$;

COMMENT ON function report__balance_sheet(date, text, text) IS
$$ This produces a balance sheet and the paths (acount numbers) of all headings
necessary; output is generated in the language requested, or in the
users default language if not available. $$;




update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
