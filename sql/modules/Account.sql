BEGIN;

DROP TYPE IF EXISTS trial_balance_line CASCADE;
CREATE TYPE trial_balance_line AS (
	chart_id int,
	accno text,
	description text,
	beginning_balance numeric,
	credits numeric,
	debits numeric,
	ending_balance numeric
);

CREATE OR REPLACE FUNCTION report_trial_balance
(in_datefrom date, in_dateto date, in_department_id int, in_project_id int,
in_gifi bool)
RETURNS setof trial_balance_line
AS $$
DECLARE out_row trial_balance_line;
BEGIN
	IF in_department_id IS NULL THEN
		FOR out_row IN
			SELECT c.id, c.accno, c.description,
				SUM(CASE WHEN ac.transdate < in_datefrom
				              AND c.category IN ('I', 'L', 'Q')
				    THEN ac.amount
				    ELSE ac.amount * -1
				    END),
			        SUM(CASE WHEN ac.transdate >= in_date_from
				              AND ac.amount > 0
			            THEN ac.amount
			            ELSE 0 END),
			        SUM(CASE WHEN ac.transdate >= in_date_from
				              AND ac.amount < 0
			            THEN ac.amount
			            ELSE 0 END) * -1,
				SUM(CASE WHEN ac.transdate >= in_date_from
					AND c.charttype IN ('I')
				    THEN ac.amount
				    WHEN ac.transdate >= in_date_from
				              AND c.category IN ('I', 'L', 'Q')
				    THEN ac.amount
				    ELSE ac.amount * -1
				    END)
				FROM acc_trans ac
				JOIN (select id, approved FROM ap
					UNION ALL
					select id, approved FROM gl
					UNION ALL
					select id, approved FROM ar) g
					ON (g.id = ac.trans_id)
				JOIN chart c ON (c.id = ac.chart_id)
				WHERE ac.transdate <= in_date_to
					AND ac.approved AND g.approved
					AND (in_project_id IS NULL
						OR in_project_id = ac.project_id)
				GROUP BY c.id, c.accno, c.description
				ORDER BY c.accno

		LOOP
			RETURN NEXT out_row;
		END LOOP;
	ELSE
		FOR out_row IN
			SELECT 1
		LOOP
			RETURN NEXT out_row;
		END LOOP;
	END IF;
END;
$$ language plpgsql;

COMMENT ON FUNCTION report_trial_balance
(in_datefrom date, in_dateto date, in_department_id int, in_project_id int,
in_gifi bool) IS
$$ This is a simple routine to generate trial balances for the full
company, for a project, or for a department.$$;

CREATE OR REPLACE FUNCTION chart_list_all()
RETURNS SETOF chart AS
$$
SELECT * FROM chart ORDER BY accno;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION chart_list_all() IS
$$ Generates a list of chart view entries.$$;

CREATE OR REPLACE FUNCTION chart_get_ar_ap(in_account_class int)
RETURNS SETOF chart AS
$$
DECLARE out_row chart%ROWTYPE;
BEGIN
	IF in_account_class NOT IN (1, 2) THEN
		RAISE EXCEPTION 'Bad Account Type';
	END IF;
       FOR out_row IN
               SELECT * FROM chart
               WHERE link = CASE WHEN in_account_class = 1 THEN 'AP'
                               WHEN in_account_class = 2 THEN 'AR'
                               END
               ORDER BY accno
       LOOP
               RETURN NEXT out_row;
       END LOOP;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION chart_get_ar_ap(in_account_class int) IS
$$ This function returns the cash account according with in_account_class which
must be 1 or 2.

If in_account_class is 1 then it returns a list of AP accounts, and if
in_account_class is 2, then a list of AR accounts.$$;

CREATE OR REPLACE FUNCTION chart_list_search(in_search text, in_link_desc text)
RETURNS SETOF account AS
$$
		SELECT * FROM account
                 WHERE (accno ~* ('^'||in_search)
                       OR description ~* ('^'||in_search))
                       AND (in_link_desc IS NULL
                           or id in
                          (select account_id from account_link
                            where description = in_link_desc))
                       AND not obsolete
              ORDER BY accno
$$
LANGUAGE 'sql';

COMMENT ON FUNCTION chart_list_search(in_search text, in_link_desc text) IS
$$ This returns a list of account entries where the description or account
number begins with in_search.

If in_link_desc is provided, the list is further filtered by which accounts are
set to an account_link.description equal to that provided.$$;

CREATE OR REPLACE FUNCTION chart_list_overpayment(in_account_class int)
RETURNS SETOF chart AS
$$
DECLARE resultrow record;
        link_string text;
BEGIN
        IF in_account_class = 1 THEN
           link_string := '%AP_overpayment%';
        ELSE
           link_string := '%AR_overpayment%';
        END IF;

        FOR resultrow IN
          SELECT *  FROM chart
          WHERE link LIKE link_string
          ORDER BY accno
          LOOP
          return next resultrow;
        END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION chart_list_overpayment(in_account_class int) is
$$ Returns a list of AP_overpayment accounts if in_account_class is 1
Otherwise it returns a list of AR_overpayment accounts.$$;

CREATE OR REPLACE FUNCTION chart_list_cash(in_account_class int)
returns setof chart
as $$
 DECLARE resultrow record;
         link_string text;
 BEGIN
         IF in_account_class = 1 THEN
            link_string := '%AP_paid%';
         ELSE
            link_string := '%AR_paid%';
         END IF;

         FOR resultrow IN
           SELECT *  FROM chart
           WHERE link LIKE link_string
           ORDER BY accno
           LOOP
           return next resultrow;
         END LOOP;
 END;
$$ language plpgsql;
COMMENT ON FUNCTION chart_list_cash(in_account_class int) IS
$$ This function returns the overpayment accounts acording with
in_account_class which must be 1 or 2.

If in_account_class is 1 it returns a list of AP cash accounts and
if 2, AR cash accounts.$$;

CREATE OR REPLACE FUNCTION chart_list_discount(in_account_class int)
RETURNS SETOF chart AS
$$
DECLARE resultrow record;
        link_string text;
BEGIN
        IF in_account_class = 1 THEN
           link_string := '%AP_discount%';
        ELSE
           link_string := '%AR_discount%';
        END IF;

        FOR resultrow IN
          SELECT *  FROM chart
          WHERE link LIKE link_string
          ORDER BY accno
          LOOP
          return next resultrow;
        END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION chart_list_discount(in_account_class int) IS
$$ This function returns the discount accounts acording with in_account_class
which must be 1 or 2.

If in_account_class is 1, returns AP discount accounts, if 2, AR discount
accounts.$$;


CREATE OR REPLACE FUNCTION account__get_from_accno(in_accno text)
returns account as
$$
     select * from account where accno = $1;
$$ language sql;

COMMENT ON FUNCTION account__get_from_accno(in_accno text) IS
$$ Returns the account where the accno field matches (excatly) the
in_accno provided.$$;

CREATE OR REPLACE FUNCTION account__is_recon(in_accno text) RETURNS BOOL AS
$$ SELECT count(*) > 0
     FROM cr_coa_to_account c2a
     JOIN account ON account.id = c2a.chart_id
    WHERE accno = $1; $$
LANGUAGE SQL;

COMMENT ON FUNCTION account__is_recon(in_accno text) IS
$$ Returns true if account is set up for reconciliation, false otherwise.
Note that returns false on invalid account number too$$;

CREATE OR REPLACE FUNCTION account__get_taxes()
RETURNS setof account AS
$$
SELECT * FROM account
 WHERE tax is true
ORDER BY accno;
$$ language sql;

COMMENT ON FUNCTION account__get_taxes() IS
$$ Returns set of accounts where the tax attribute is true.$$;

DROP FUNCTION IF EXISTS account_get(int);

CREATE OR REPLACE FUNCTION account_get (in_id int) RETURNS chart AS
$$
select c.id, c.accno, c.description,
       'A'::text as charttype, c.category, concat_colon(l.description) as link,
       heading, gifi_accno, contra, tax
  from account c
  left join account_link l
    ON (c.id = l.account_id)
  where  id = $1
group by c.id, c.accno, c.description, c.category,
         c.heading, c.gifi_accno, c.contra, c.tax;
$$ LANGUAGE sql;

COMMENT ON FUNCTION account_get(in_id int) IS
$$Returns an entry from the chart view which matches the id requested, and which
is an account, not a heading.$$;

DROP FUNCTION IF EXISTS account__list_translations(int);
CREATE OR REPLACE FUNCTION account__list_translations(in_id int)
RETURNS SETOF account_translation AS
$$
   SELECT * FROM account_translation WHERE trans_id = $1;
$$ LANGUAGE sql;

COMMENT ON FUNCTION account__list_translations(in_id int) IS
$$Returns the list of translations for the given account.$$;

CREATE OR REPLACE FUNCTION account__save_translation(
       in_id int, in_language_code text, in_description text)
RETURNS void AS
$$
BEGIN
   UPDATE account_translation
      SET description = in_description
    WHERE language_code = in_language_code
      AND trans_id = in_id;

   IF NOT FOUND THEN
      INSERT INTO account_translation
             (trans_id, language_code, description)
      VALUES (in_id, in_language_code, in_description);
   END IF;
   RETURN;
END;$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION account__save_translation(in_id int,
           in_language_code text, in_description text) IS
$$Saves the translation for the given account, creating a new
translation if none existed for the account+language combination.$$;

CREATE OR REPLACE FUNCTION account__delete_translation(
       in_id int, in_language_code text)
RETURNS void AS
$$
   DELETE FROM account_translation
    WHERE trans_id = $1
      AND language_code = $2;
$$ LANGUAGE sql;

COMMENT ON FUNCTION account__delete_translation(
       in_id int, in_language_code text) IS
$$Deletes the translation for the account+language combination.$$;



CREATE OR REPLACE FUNCTION account_heading_get (in_id int) RETURNS chart AS
$$
SELECT ah.id, ah.accno, ah.description,
       'H'::text as charttype, NULL::char as category, null::text as link,
       ah.parent_id as account_heading,
       null::text as gifi_accno, false as contra,
       false as tax
   from account_heading ah
  WHERE id = in_id;
$$ LANGUAGE sql;

COMMENT ON FUNCTION account_heading_get(in_id int) IS
$$Returns an entry from the chart view which matches the id requested, and which
is a heading, not an account.$$;

DROP FUNCTION IF EXISTS account_heading__list_translations(int);
CREATE OR REPLACE FUNCTION account_heading__list_translations(in_id int)
RETURNS SETOF account_heading_translation AS
$$
   SELECT * FROM account_heading_translation WHERE trans_id = $1;
$$ LANGUAGE sql;

COMMENT ON FUNCTION account_heading__list_translations(in_id int) IS
$$Returns the list of translations for the given account.$$;

CREATE OR REPLACE FUNCTION account_heading__save_translation(
       in_id int, in_language_code text, in_description text)
RETURNS void AS
$$
BEGIN
   UPDATE account_heading_translation
      SET description = in_description
    WHERE language_code = in_language_code
      AND trans_id = in_id;

   IF NOT FOUND THEN
      INSERT INTO account_heading_translation
             (trans_id, language_code, description)
      VALUES (in_id, in_language_code, in_description);
   END IF;
   RETURN;
END;$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION account_heading__save_translation(in_id int,
           in_language_code text, in_description text) IS
$$Saves the translation for the given account, creating a new
translation if none existed for the account+language combination.$$;

CREATE OR REPLACE FUNCTION account_heading__delete_translation(
       in_id int, in_language_code text)
RETURNS void AS
$$
   DELETE FROM account_heading_translation
    WHERE trans_id = $1
      AND language_code = $2;
$$ LANGUAGE sql;

COMMENT ON FUNCTION account_heading__delete_translation(
       in_id int, in_language_code text) IS
$$Deletes the translation for the account+language combination.$$;

CREATE OR REPLACE FUNCTION account_has_transactions (in_id int) RETURNS bool AS
$$
BEGIN
	PERFORM trans_id FROM acc_trans WHERE chart_id = in_id LIMIT 1;
	IF FOUND THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION account_has_transactions (in_id int) IS
$$ Checks to see if any transactions use this account.  If so, returns true.
If not, returns false.$$;

CREATE OR REPLACE FUNCTION account__save
(in_id int, in_accno text, in_description text, in_category char(1),
in_gifi_accno text, in_heading int, in_contra bool, in_tax bool,
in_link text[], in_obsolete bool, in_is_temp bool)
RETURNS int AS $$
DECLARE
	t_heading_id int;
	t_link record;
	t_id int;
        t_tax bool;
BEGIN

    SELECT count(*) > 0 INTO t_tax FROM tax WHERE in_id = chart_id;
    t_tax := t_tax OR in_tax;
	-- check to ensure summary accounts are exclusive
        -- necessary for proper handling by legacy code
    FOR t_link IN SELECT description FROM account_link_description
    WHERE summary='t'
	LOOP
		IF t_link.description = ANY (in_link) and array_upper(in_link, 1) > 1 THEN
			RAISE EXCEPTION 'Invalid link settings:  Summary';
		END IF;
	END LOOP;
	-- heading settings
	IF in_heading IS NULL THEN
		SELECT id INTO t_heading_id FROM account_heading
		WHERE accno < in_accno order by accno desc limit 1;
	ELSE
		t_heading_id := in_heading;
	END IF;

    -- don't remove custom links.
	DELETE FROM account_link
	WHERE account_id = in_id
              and description in ( select description
                                    from  account_link_description
                                    where custom = 'f');

	UPDATE account
	SET accno = in_accno,
		description = in_description,
		category = in_category,
		gifi_accno = in_gifi_accno,
		heading = t_heading_id,
		contra = in_contra,
                obsolete = coalesce(in_obsolete,'f'),
                tax = t_tax,
                is_temp = coalesce(in_is_temp,'f')
	WHERE id = in_id;

	IF FOUND THEN
		t_id := in_id;
	ELSE
                -- can't obsolete on insert, but this can be changed if users
                -- request it --CT
		INSERT INTO account (accno, description, category, gifi_accno,
			heading, contra, tax, is_temp)
		VALUES (in_accno, in_description, in_category, in_gifi_accno,
			t_heading_id, in_contra, in_tax, coalesce(in_is_temp, 'f'));

		t_id := currval('account_id_seq');
	END IF;

	FOR t_link IN
		select in_link[generate_series] AS val
		FROM generate_series(array_lower(in_link, 1),
			array_upper(in_link, 1))
	LOOP
		INSERT INTO account_link (account_id, description)
		VALUES (t_id, t_link.val);
	END LOOP;


	RETURN t_id;
END;
$$ language plpgsql;

COMMENT ON FUNCTION account__save
(in_id int, in_accno text, in_description text, in_category char(1),
in_gifi_accno text, in_heading int, in_contra bool, in_tax bool,
in_link text[], in_obsolete bool, in_is_temp bool) IS
$$ This deletes existing account_link entries, where the
account_link.description is not designated as a custom one in the
account_link_description table.

If no account heading is provided, the account heading which has an accno field
closest to but prior (by collation order) is used.

Then it saves the account information, and rebuilds the account_link records
based on the in_link array.
$$;

CREATE OR REPLACE FUNCTION account__delete(in_id int)
RETURNS BOOL AS
$$
BEGIN
DELETE FROM tax WHERE chart_id = in_id;
DELETE FROM account_link WHERE account_id = in_id;
DELETE FROM account WHERE id = in_id;
RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION account__delete(int) IS
$$ This deletes an account with the id specified.  If the account has
transactions associated with it, it will fail and raise a foreign key constraint.
$$;

CREATE OR REPLACE FUNCTION account_heading_list()
RETURNS SETOF account_heading AS
$$
SELECT * FROM account_heading order by accno;
$$ language sql;

CREATE OR REPLACE FUNCTION account__list_by_heading()
RETURNS SETOF account AS $$
SELECT * FROM account ORDER BY heading;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION account_heading_list() IS
$$ Lists all existing account headings.$$;

CREATE OR REPLACE FUNCTION account_heading_save
(in_id int, in_accno text, in_description text, in_parent int)
RETURNS int AS
$$
BEGIN
	UPDATE account_heading
	SET accno = in_accno,
		description = in_description,
		parent_id = in_parent
	WHERE id = in_id;

	IF FOUND THEN
		RETURN in_id;
	END IF;
	INSERT INTO account_heading (accno, description, parent_id)
	VALUES (in_accno, in_description, in_parent);

	RETURN currval('account_heading_id_seq');
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION account_heading_save
(in_id int, in_accno text, in_description text, in_parent int) IS
$$ Saves an account heading. $$;

CREATE OR REPLACE FUNCTION account_heading__delete(in_id int)
RETURNS BOOL AS
$$
BEGIN
DELETE FROM account_heading WHERE id = in_id;
RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION account_heading__delete(int) IS
$$ This deletes an account heading with the id specified.  If the heading has
accounts associated with it, it will fail and raise a foreign key constraint.
$$;

CREATE OR REPLACE RULE chart_i AS ON INSERT TO chart
DO INSTEAD
SELECT CASE WHEN new.charttype='H' THEN
 account_heading_save(new.id, new.accno, new.description, NULL)
ELSE
 account__save(new.id, new.accno, new.description, new.category,
  new.gifi_accno, NULL,
  -- should these be rewritten as coalesces? --CT
  CASE WHEN new.contra IS NULL THEN FALSE ELSE new.contra END,
  CASE WHEN new.tax IS NULL THEN FALSE ELSE new.tax END,
  string_to_array(new.link, ':'), false, false)
END;

CREATE OR REPLACE FUNCTION cr_coa_to_account_save(in_accno text, in_description text)
RETURNS void AS $BODY$
    DECLARE
       v_chart_id int;
    BEGIN
        -- Check for existence of the account already
        PERFORM * FROM cr_coa_to_account WHERE account = in_accno;

        IF NOT FOUND THEN
           -- This is a new account. Insert the relevant data.
           SELECT id INTO v_chart_id FROM chart WHERE accno = in_accno;
           INSERT INTO cr_coa_to_account (chart_id, account) VALUES (v_chart_id, in_accno||'--'||in_description);
        END IF;
        -- Already found, no need to do anything. =)
    END;
$BODY$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION cr_coa_to_account_save(in_accno text, in_description text)
IS $$ Provides default rules for setting reconciliation labels.  Currently
saves a label of accno ||'--' || description.$$;

CREATE OR REPLACE FUNCTION account__get_by_accno(in_accno text)
RETURNS account AS $$
SELECT * FROM account WHERE accno = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION account__get_by_link_desc(in_description text)
RETURNS SETOF account AS $$
SELECT * FROM account
WHERE id IN (SELECT account_id FROM account_link WHERE description = $1);
$$ language sql;

COMMENT ON FUNCTION account__get_by_link_desc(in_description text) IS
$$ Gets a list of accounts with a specific link description set.  For example,
for a dropdown list.$$;

CREATE OR REPLACE FUNCTION get_link_descriptions()
RETURNS SETOF account_link_description AS
$$
    SELECT * FROM account_link_description;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION get_link_descriptions() IS
$$ Gets a set of all valid account_link descriptions.$$;

CREATE OR REPLACE FUNCTION account_heading__list()
RETURNS SETOF account_heading AS
$$ SELECT * FROM account_heading order by accno; $$ language sql;

COMMENT ON FUNCTION account_heading__list() IS
$$ Returns a list of all account headings, currently ordered by account number.
$$;

DROP FUNCTION IF EXISTS account__save_tax
(in_chart_id int, in_validto date, in_rate numeric, in_taxnumber text,
in_pass int, in_taxmodule_id int, in_old_validto date);

CREATE OR REPLACE FUNCTION account__save_tax
(in_chart_id int, in_validto date, in_rate numeric, in_minvalue numeric,
in_maxvalue numeric, in_taxnumber text,
in_pass int, in_taxmodule_id int, in_old_validto date)
returns bool as
$$
BEGIN
	UPDATE tax SET validto = in_validto,
               rate = in_rate,
               minvalue = in_minvalue,
               maxvalue = in_maxvalue,
               taxnumber = in_taxnumber,
               pass = in_pass,
               taxmodule_id = in_taxmodule_id
         WHERE chart_id = in_chart_id and validto = in_old_validto;

         IF FOUND THEN
             return true;
         END IF;

         INSERT INTO tax(chart_id, validto, rate, minvalue, maxvalue, taxnumber,
                        pass, taxmodule_id)
         VALUES (in_chart_id, in_validto, in_rate, in_minvalue, in_maxvalue,
                in_taxnumber, in_pass, in_taxmodule_id);

         RETURN TRUE;

END;
$$ language plpgsql;

COMMENT ON FUNCTION account__save_tax
(in_chart_id int, in_validto date, in_rate numeric, in_minvalue numeric,
in_maxvalue numeric, in_taxnumber text,
in_pass int, in_taxmodule_id int, in_old_validto date) IS
$$ This saves tax rates.$$;

DROP TYPE IF EXISTS coa_entry CASCADE;

CREATE TYPE coa_entry AS (
    id int,
    is_heading bool,
    accno text,
    description text,
    gifi text,
    debit_balance numeric,
    credit_balance numeric,
    rowcount bigint,
    link text
);

CREATE OR REPLACE FUNCTION report__coa() RETURNS SETOF coa_entry AS
$$

WITH ac (chart_id, amount) AS (
     SELECT chart_id, CASE WHEN acc_trans.approved and gl.approved THEN amount
                           ELSE 0
                       END
       FROM acc_trans
       JOIN (select id, approved from ar union all
             select id, approved from ap union all
             select id, approved from gl) gl ON gl.id = acc_trans.trans_id
),
l(account_id, link) AS (
     SELECT account_id, array_to_string(array_agg(description), ':')
       FROM account_link
   GROUP BY account_id
),
hh(parent_id) AS (
     SELECT DISTINCT parent_id
       FROM account_heading
),
ha(heading) AS (
     SELECT heading
       FROM account
),
eca(account_id) AS (
    SELECT DISTINCT discount_account_id
      FROM entity_credit_account
    UNION ALL
    SELECT DISTINCT ar_ap_account_id
      FROM entity_credit_account
    UNION ALL
    SELECT DISTINCT cash_account_id
      FROM entity_credit_account
),
ta(account_id) AS (
    SELECT chart_id
      FROM eca_tax
)
SELECT a.id, a.is_heading, a.accno, a.description, a.gifi_accno,
       CASE WHEN sum(ac.amount) < 0 THEN sum(amount) * -1 ELSE null::numeric
        END,
       CASE WHEN sum(ac.amount) > 0 THEN sum(amount) ELSE null::numeric END,
       count(ac.*)+count(hh.*)+count(ha.*)+count(eca.*)+count(ta.*), l.link
  FROM (SELECT id, heading, false as is_heading, accno, description, gifi_accno
          FROM account
         UNION
        SELECT id, parent_id, true, accno, description, null::text
          FROM account_heading) a

 LEFT JOIN ac ON ac.chart_id = a.id AND not a.is_heading
 LEFT JOIN l ON l.account_id = a.id AND NOT a.is_heading
 LEFT JOIN hh ON hh.parent_id = a.id AND a.is_heading
 LEFT JOIN ha ON ha.heading = a.id AND a.is_heading
 LEFT JOIN eca ON eca.account_id = a.id AND NOT a.is_heading
 LEFT JOIN ta ON ta.account_id = a.id AND NOT a.is_heading
  GROUP BY a.id, a.is_heading, a.accno, a.description, a.gifi_accno, l.link
  ORDER BY a.accno;

$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION account__all_headings() RETURNS SETOF account_heading
LANGUAGE SQL AS
$$
SELECT * FROM account_heading ORDER BY accno;
$$;

DROP VIEW IF EXISTS account_heading_tree CASCADE;
CREATE VIEW account_heading_tree AS
WITH RECURSIVE account_headings AS (
    SELECT id, accno, description, 1 as level, ARRAY[id] as path
      FROM account_heading
     WHERE parent_id IS NULL
    UNION ALL
    SELECT ah.id, ah.accno, ah.description, at.level + 1 as level,
           array_append(at.path, ah.id) as path
      FROM account_heading ah
      JOIN account_headings at ON ah.parent_id = at.id
)
SELECT id, accno, description, level, path
  FROM account_headings;

COMMENT ON VIEW account_heading_tree IS $$ Returns in the 'path' field an
array which contains the path of the heading to its associated root.$$;

DROP VIEW IF EXISTS account_heading_descendant CASCADE;
CREATE VIEW account_heading_descendant
AS
WITH RECURSIVE account_headings AS (
    SELECT account_heading.id as id, 1 AS level,
           id as descendant_id, accno, accno as descendant_accno
      FROM account_heading
    UNION ALL
    SELECT at.id, at.level+1 as level,
    	   ah.id as descendant_id, at.accno, ah.accno as descendant_accno
    FROM account_heading ah
    JOIN account_headings at ON ah.parent_id = at.descendant_id
)
SELECT id, level, descendant_id, accno, descendant_accno
   FROM account_headings;

COMMENT ON VIEW account_heading_descendant IS $$ Returns rows for
each heading listing its immediate children, children of children, etc., etc.

This is primarily practical when calculating subtotals
for PNL and B/S headings.$$;

DROP VIEW IF EXISTS account_heading_derived_category CASCADE;
CREATE VIEW account_heading_derived_category AS
SELECT *, coalesce(original_category, derived_category) as category
FROM (
SELECT *, CASE WHEN equity_count > 0 THEN 'Q'
               WHEN income_count > 0 AND expense_count > 0 THEN 'Q'
               WHEN asset_count > 0 AND liability_count >0 THEN 'Q'
               WHEN asset_count > 0 THEN 'A'
               WHEN liability_count > 0 THEN 'L'
               WHEN expense_count > 0 THEN 'E'
               WHEN income_count > 0 THEN 'I' END AS derived_category
FROM (
     SELECT ah.id, ah.accno, ah.description, ah.parent_id,
            ah.category as original_category,
      count(CASE WHEN acc.category = 'A' THEN acc.category END) AS asset_count,
      count(CASE WHEN acc.category = 'L' THEN acc.category END) AS liability_count,
      count(CASE WHEN acc.category = 'E' THEN acc.category END) AS expense_count,
      count(CASE WHEN acc.category = 'I' THEN acc.category END) AS income_count,
      count(CASE WHEN acc.category = 'Q' THEN acc.category END) AS equity_count
       FROM account_heading_descendant ahd
     INNER JOIN account_heading ah on ahd.id = ah.id
     LEFT JOIN account acc ON ahd.descendant_id = acc.heading
     GROUP BY ah.id, ah.accno, ah.description, ah.parent_id,
              ah.category) category_counts) derivation;

COMMENT ON VIEW account_heading_derived_category IS $$ Lists for each row
the derived category for each heading, based on the categories of the
linked accounts.$$;

CREATE OR REPLACE FUNCTION gifi__list() RETURNS SETOF gifi
LANGUAGE SQL AS
$$
SELECT * FROM gifi ORDER BY accno;
$$;

CREATE OR REPLACE FUNCTION account_heading__check_tree()
RETURNS TRIGGER LANGUAGE PLPGSQL AS $$
BEGIN

PERFORM * from (
  WITH RECURSIVE account_headings AS (
      SELECT id, accno, 1 as level, accno as path
        FROM account_heading
      UNION ALL
      SELECT ah.id, ah.accno, at.level + 1 as level, at.path  || '||||' || ah.accno
        FROM account_heading ah
        JOIN account_headings at ON ah.parent_id = at.id
       WHERE NOT ah.accno = ANY(string_to_array(path, '||||'))
  )
  SELECT *
    FROM account_heading ah
    JOIN account_headings at ON ah.parent_id = at.id
   WHERE at.path || '||||' ||  ah.accno NOT IN
          (select path from account_headings)
) x;

IF found then
   RAISE EXCEPTION 'ACCOUNT_HEADING_LOOP';
END IF;

RETURN NEW;
end;
$$;

DROP TRIGGER IF EXISTS loop_detection ON account_heading;
CREATE TRIGGER loop_detection AFTER INSERT OR UPDATE ON account_heading
FOR EACH ROW EXECUTE PROCEDURE account_heading__check_tree();

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
