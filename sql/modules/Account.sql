-- VERSION 1.3.0

CREATE OR REPLACE FUNCTION account__get_from_accno(in_accno text)
returns account as
$$
     select * from account where accno = $1;
$$ language sql;

CREATE OR REPLACE FUNCTION account_get (in_id int) RETURNS chart AS
$$
DECLARE
	account chart%ROWTYPE;
BEGIN
	SELECT * INTO account FROM chart WHERE id = in_id;
	RETURN account;
END;
$$ LANGUAGE plpgsql;

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

CREATE OR REPLACE FUNCTION account_save 
(in_id int, in_accno text, in_description text, in_category char(1), 
in_gifi text, in_heading int, in_contra bool, in_link text[])
RETURNS int AS $$
DECLARE 
	t_summary_links TEXT[] = '{AR,AP,IC}';
	t_heading_id int;
	t_text record;
	t_id int;
BEGIN
	-- check to ensure summary accounts are exclusive
	FOR t_text IN 
		select t_summary_links[generate_series] AS val 
		FROM generate_series(array_lower(t_summary_links, 1), 
			array_upper(t_summary_links, 1))
	LOOP
		IF t_text.val = ANY (in_link) and array_upper(in_link, 1) > 1 THEN
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

	DELETE FROM account_link WHERE account_id = in_id;

	UPDATE account 
	SET accno = in_accno,
		description = in_description,
		category = in_category,
		gifi_accno = in_gifi,
		heading = t_heading_id,
		contra = in_contra
	WHERE id = in_id;

	IF FOUND THEN
		t_id := in_id;
	ELSE
		INSERT INTO account (accno, description, category, gifi_accno,
			heading, contra)
		VALUES (in_accno, in_description, in_category, in_gifi,
			t_heading_id, in_contra);

		t_id := currval('account_id_seq');
	END IF;

	FOR t_text IN 
		select in_link[generate_series] AS val
		FROM generate_series(array_lower(in_link, 1), 
			array_upper(in_link, 1))
	LOOP
		INSERT INTO account_link (account_id, description)
		VALUES (t_id, t_text.val);
	END LOOP;
	
	RETURN t_id;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION account_heading_list()
RETURNS SETOF account_heading AS
$$
SELECT * FROM account_heading order by accno;
$$ language sql;

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

CREATE RULE chart_i AS ON INSERT TO chart
DO INSTEAD
SELECT CASE WHEN new.charttype='H' THEN account_heading_save(new.id, new.accno, new.description, NULL)
ELSE account_save(new.id, new.accno, new.description, new.category, new.gifi_accno, NULL, CASE WHEN new.contra IS NULL THEN FALSE ELSE new.contra END, string_to_array(new.link, ':'))
END;
--
