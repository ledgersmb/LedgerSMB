-- VERSION 1.3.0

CREATE OR REPLACE FUNCTION account__get_from_accno(in_accno text)
returns account as
$$
     select * from account where accno = $1;
$$ language sql;

COMMENT ON FUNCTION account__get_from_accno(in_accno text) IS
$$ Returns the account where the accno field matches (excatly) the 
in_accno provided.$$;

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

CREATE OR REPLACE FUNCTION account_save 
(in_id int, in_accno text, in_description text, in_category char(1), 
in_gifi_accno text, in_heading int, in_contra bool, in_tax bool,
in_link text[])
RETURNS int AS $$
DECLARE 
	t_heading_id int;
	t_link record;
	t_id int;
BEGIN
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
                tax = in_tax
	WHERE id = in_id;

	IF FOUND THEN
		t_id := in_id;
	ELSE
		INSERT INTO account (accno, description, category, gifi_accno,
			heading, contra, tax)
		VALUES (in_accno, in_description, in_category, in_gifi_accno,
			t_heading_id, in_contra, in_tax);

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

COMMENT ON FUNCTION account_save
(in_id int, in_accno text, in_description text, in_category char(1),
in_gifi_accno text, in_heading int, in_contra bool, in_tax bool,
in_link text[]) IS
$$ This deletes existing account_link entries, where the 
account_link.description is not designated as a custom one in the 
account_link_description table.

If no account heading is provided, the account heading which has an accno field
closest to but prior (by collation order) is used.

Then it saves the account information, and rebuilds the account_link records 
based on the in_link array.
$$;

CREATE OR REPLACE FUNCTION account_heading_list()
RETURNS SETOF account_heading AS
$$
SELECT * FROM account_heading order by accno;
$$ language sql;

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
 account_save(new.id, new.accno, new.description, new.category,
  new.gifi_accno, NULL,
  CASE WHEN new.contra IS NULL THEN FALSE ELSE new.contra END,
  CASE WHEN new.tax IS NULL THEN FALSE ELSE new.tax END,
  string_to_array(new.link, ':'))
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

CREATE OR REPLACE FUNCTION account__save_tax
(in_chart_id int, in_validto date, in_rate numeric, in_taxnumber text, 
in_pass int, in_taxmodule_id int, in_old_validto date)
returns bool as
$$
BEGIN
	UPDATE tax SET validto = in_validto,
               rate = in_rate,
               taxnumber = in_taxnumber,
               pass = in_pass,
               taxmodule_id = in_taxmodule_id
         WHERE chart_id = in_chart_id and validto = in_old_validto;

         IF FOUND THEN
             return true;
         END IF;

         INSERT INTO tax(chart_id, validto, rate, taxnumber, pass, taxmodule_id)
         VALUES (in_chart_id, in_validto, in_rate, in_taxnumber, in_pass,
                 in_taxmodule_id);

         RETURN TRUE;

END;
$$ language plpgsql;

COMMENT ON FUNCTION account__save_tax
(in_chart_id int, in_validto date, in_rate numeric, in_taxnumber text,
in_pass int, in_taxmodule_id int, in_old_validto date) IS
$$ This saves tax rates.$$; 
