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
DECLARE out_row chart%ROWTYPE;
BEGIN
	FOR out_row IN 
		SELECT * FROM chart ORDER BY accno
	LOOP
		RETURN next out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

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
$$ This function returns the cash account acording with in_account_class which 
must be 1 or 2.

If in_account_class is 1 then it returns a list of AP accounts, and if 
in_account_class is 2, then a list of AR accounts.$$;

CREATE OR REPLACE FUNCTION chart_list_search(in_search text, in_link_desc text)
RETURNS SETOF account AS
$$
DECLARE out_row account%ROWTYPE;
BEGIN
	FOR out_row IN 
		SELECT * FROM account 
                 WHERE (accno ~* ('^'||in_search) 
                       OR description ~* ('^'||in_search))
                       AND (in_link_desc IS NULL 
                           or id in 
                          (select account_id from account_link 
                            where description = in_link_desc))
                       AND not obsolete
              ORDER BY accno
	LOOP
		RETURN next out_row;
	END LOOP;
END;$$
LANGUAGE 'plpgsql';

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

CREATE OR REPLACE FUNCTION account_get (in_id int) RETURNS setof chart AS
$$
SELECT * from chart where id = $1 and charttype = 'A';
$$ LANGUAGE sql;

COMMENT ON FUNCTION account_get(in_id int) IS
$$Returns an entry from the chart view which matches the id requested, and which
is an account, not a heading.$$;

CREATE OR REPLACE FUNCTION account_heading_get (in_id int) RETURNS chart AS
$$
DECLARE
	account chart%ROWTYPE;
BEGIN
	SELECT * INTO account FROM chart WHERE id = in_id AND charttype = 'H';
	RETURN account;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION account_heading_get(in_id int) IS
$$Returns an entry from the chart view which matches the id requested, and which
is a heading, not an account.$$;

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
)
SELECT a.id, a.is_heading, a.accno, a.description, a.gifi_accno, 
       CASE WHEN sum(ac.amount) < 0 THEN sum(amount) * -1 ELSE null::numeric
        END,
       CASE WHEN sum(ac.amount) > 0 THEN sum(amount) ELSE null::numeric END,
       count(ac.*), l.link
  FROM (SELECT id,false as is_heading, accno, description, gifi_accno
          FROM account
         UNION
        SELECT id, true, accno, description, null::text 
          FROM account_heading) a

 LEFT JOIN ac ON ac.chart_id = a.id AND not a.is_heading
 LEFT JOIN l ON l.account_id = a.id AND NOT a.is_heading
  GROUP BY a.id, a.is_heading, a.accno, a.description, a.gifi_accno, l.link
  ORDER BY a.accno;

$$ LANGUAGE SQL;

COMMIT;
