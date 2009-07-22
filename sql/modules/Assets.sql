CREATE OR REPLACE FUNCTION asset_dep__straight_line
(in_report_id int, in_asset_id int)
returns numeric as $$
DECLARE 
	annual_amount numeric;
	depreciation_interval interval;
	depreciation_years numeric;
	retval numeric;
	value_left numeric;
	depreciation_amount numeric;
BEGIN
	SELECT (purchase_amount - salvage_amount) / usable_life::numeric  
	INTO annual_amount 
	FROM asset_item 
	WHERE id = in_asset_id;

	SELECT purchase_amount - salvage_amount - sum(amount) 
	INTO value_left
	FROM asset_item i 
	JOIN asset_report_line l ON (i.id = l.asset_id)
	GROUP BY puchase_amount, salvage_amount;

	SELECT (select report_date FROM asset_report where id = in_id) - 
		CASE WHEN report_date > purchase_date THEN report_date
	             ELSE purchase_date END
	INTO depreciation_interval
	FROM asset_item i 
	LEFT JOIN asset_report_line l ON (i.id = l.asset_id)
	LEFT JOIN asset_report r ON (l.report_id = r.id)
	WHERE r.approved IS NULL OR r.approved IS TRUE
	ORDER BY r.report_date limit 1;

	depreciation_years := extract('years' from depreciation_interval);
	depreciation_years := depreciation_years + 
                              extract('months' from depreciation_interval) / 12;
	depreciation_years := depreciation_yers +
                              extract('days' from depreciation_interval) / 365;

	depreciation_amount := annual_amount * depreciation_years;

	INSERT INTO asset_report_line (asset_id, report_id, amount)
	VALUES (in_asst_id, in_report_id, depreciation_amount);
	RETURN NULL;
end;	
$$ language plpgsql;

CREATE OR REPLACE FUNCTION asset_class__get (in_id int) RETURNS asset_class AS
$$
DECLARE ret_val asset_class;
BEGIN 
	SELECT * INTO ret_val FROM asset_class WHERE id = in_id;
	RETURN ret_val;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION asset_class__list() RETURNS SETOF asset_class AS
$$
SELECT * FROM asset_class ORDER BY label;
$$ LANGUAGE SQL;

CREATE TYPE asset_class_result AS (
	id int,
	asset_account_id int,
	asset_accno text,
	asset_description text,
	dep_account_id int,
	dep_accno text,
	dep_description text,
	method text, 
	method_id int, 
	life_unit text, 
	life_unit_id int, 
	label text
);

CREATE OR REPLACE FUNCTION asset_class__search
(in_asset_account_id int, in_dep_account_id int, 
in_method int, in_life_unit int, in_label text)
RETURNS SETOF asset_class_result AS
$$
DECLARE out_var asset_class_result;
BEGIN
	FOR out_var IN
		SELECT ac.id, ac.asset_account_id, aa.accno, aa.description, 
			ad.accno, ad.description, m.label, ac.method_id,
			lu.label, ac.life_unit_id, ac.label
		FROM asset_class ac
		JOIN account aa ON (aa.id = ac.asset_account_id)
		JOIN account ad ON (ad.id = ac.dep_account_id)
		JOIN asset_dep_method m ON (ac.method_id = m.id)
		JOIN asset_life_unit lu ON (ac.life_unit_id = lu.id)
		WHERE 
			(in_asset_account_id is null 
				or in_asset_account_id = ac.asset_account_id)
			AND (in_dep_account_id is null OR
				in_dep_account_id = ac.dep_account_id)
			AND (in_method is null OR in_method = ac.method_id)
			AND (in_life_unit is null 
				OR in_life_unit = ac.life_unit_id)
			AND (in_label IS NULL OR ac.label LIKE 
				'%' || in_label || '%')
	LOOP
		RETURN NEXT out_var;
	END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION asset_class__save
(in_id int, in_asset_account_id int, in_dep_account_id int, 
in_method int, in_life_unit int, in_label text)
RETURNS asset_class AS
$$
DECLARE ret_val asset_class;
BEGIN
	UPDATE asset_class 
	SET asset_account_id = in_asset_account_id,
		dep_account_id = in_dep_account_id,
		method = in_method,
		label = in_label,
		life_unit = in_life_unit
	WHERE id = in_id;

	IF FOUND THEN
		SELECT * INTO ret_val FROM asset_class where id = in_id;
		RETURN ret_val;
	END IF;

	INSERT INTO asset_class (asset_account_id, dep_account_id, method,
		life_unit, label)
	VALUES (in_asset_account_id, in_dep_account_id, in_method, 
		in_life_unit, label);

	SELECT * INTO ret_val FROM asset_class 
	WHERE id = currval('asset_class_id_seq');

	RETURN ret_val;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION asset__get (in_id int, in_tag text)
RETURNS asset_item AS
$$
DECLARE ret_val asset_item;
BEGIN
	SELECT * into ret_val from asset_item WHERE id = in_id and in_tag = tag;
	return ret_val;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION asset__search
(in_asset_class int, in_description text, in_tag text, 
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric)
RETURNS SETOF asset_item AS $$
DECLARE out_val asset_item;
BEGIN
	FOR out_val IN
		SELECT * FROM asset_item
		WHERE (in_asset_class is null 
			or asset_class_id = in_asset_class)
			AND (in_description is null or description 
				LIKE '%' || in_description || '%')
			and (in_tag is not null or tag like '%'||in_tag||'%')
			AND (in_purchase_date is null 
				or purchase_date = in_purchase_date)
			AND (in_purchase_value is null
				or in_purchase_value = purchase_value)
			AND (in_usable_life is null
				or in_usable_life = usable_life)
			AND (in_salvage_value is null
				OR in_salvage_value = salvage_value)
	LOOP
		RETURN NEXT out_val;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION asset_class__get_asset_accounts()
RETURNS SETOF account AS $$
SELECT * FROM account 
WHERE id IN 
	(select account_id from account_link where description = 'Fixed_Asset')
ORDER BY accno;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION asset_class__get_dep_accounts()
RETURNS SETOF account AS $$
SELECT * FROM account 
WHERE id IN 
	(select account_id from account_link where description = 'Asset_Dep')
ORDER BY accno;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION asset_class__get_life_units()
RETURNS SETOF asset_life_unit AS $$
	SELECT * FROM asset_life_unit;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION asset__save
(in_id int, in_asset_class int, in_description text, in_tag text, 
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric)
returns asset_item AS
$$
DECLARE ret_val asset_item;
BEGIN
	UPDATE asset_item
	SET asset_class_id = in_asset_class,
		description = in_description,
		tag = in_tag,
		purchase_date = in_purchase_date,
		purchase_value = in_purchase_value,
		usable_life = in_usable_life,
		salvage_value = in_salvage_value
	WHERE id = in_id;
	IF FOUND THEN
		SELECT * INTO ret_val WHERE id = in_id;
		return ret_val;
	END IF;

	INSERT INTO asset_item (asset_class_id, description, tag, purchase_date,
		purchase_value, usable_life, salvage_value)
	VALUES (in_asset_class, in_description, in_tag, in_purchase_date,
		in_purchase_value, in_usable_life, in_salvage_value);

	SELECT * INTO ret_val FROM asset_item 
	WHERE id = currval('asset_item_id_seq');
	RETURN ret_val;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION asset_report__save
(in_id int, in_asset_class int, in_report_date date, in_report_class int,
in_submit bool, in_asset_items int[])
RETURNS asset_report AS
$$
DECLARE 
	ret_val asset_report;
	item record;
	method_sproc text;
BEGIN
	DELETE FROM asset_item where report_id = in_id;

	UPDATE asset_report 
	set asset_class = in_asset_class,
		report_class = in_report_class,
		report_date = in_report_date,
		submitted = (in_submitted or submitted)
	WHERE id = in_id;

	IF FOUND THEN
		SELECT * INTO ret_val FROM asset_report WHERE id = in_id;
	ELSE 
		INSERT INTO asset_report(report_class, asset_class, report_date,
			submitted)
		values (in_report_class, in_asset_class, in_report_date, 
			in_submitted);

		SELECT * INTO ret_val FROM asset_report 
		WHERE id = currval('asset_report_id_seq');
	END IF;

	SELECT sproc INTO method_text FROM asset_dep_method 
	WHERE id = (select method FROM asset_class 
		where id = ret_val.asset_class);

	FOR item IN 
		SELECT in_asset_items[generate_series] AS id
		FROM generate_series(array_lower(in_asset_items, 1), 
			array_upper(in_asset_items, 1))
	LOOP
		EXECUTE $E$PERFORM $E$ || quote_ident(method_text) || $E$($E$ ||
			quote_literal(ret_val.id) || $E$, $E$ || 
			quote_literal(item.id) ||$E$)
		$E$; 
	END LOOP;
	-- TODO:  ADD GL lines at this point
	RETURN ret_val;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION asset_report__approve
(in_id int)
RETURNS asset_report AS
$$
DECLARE ret_val asset_report;
BEGIN
	UPDATE gl SET approved = true 
	where id = (select gl_id from asset_report where id = in_id);

	UPDATE asset_report SET approved = TRUE
	where id = in_id;

	SELECT * INTO ret_val FROM asset_report WHERE id = in_id;

	RETURN ret_val;
end;
$$ language plpgsql;
revoke execute on function asset_report__approve(int) from public;
