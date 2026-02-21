
set client_min_messages = 'warning';

/*


  asset_report__generate_gl   - creates GL transaction upon approval of depreciation report
  asset_report__disposal_gl   - creates GL transaction upon approval of a disposal (sale/abandonment)
  asset_disposal__approve     - creates GL transaction upon approval of *partial* disposal (sale/abandonment)
  asset__import_from_disposal - creates new assets from partially disposed assets, upon approval
  asset_report__get_disposal  - returns a line per disposed asset in a disposal report with disposal details


  call tree:

    asset_report__approve
      report_class of
        '1': (depreciation)
          asset_report__generate_gl
        '2': (full disposal)
          asset_report__disposal_gl
            asset_report__get_disposal
        '4': (partial disposal)
          asset_disposal__approve
            asset__import_from_disposal

*/


BEGIN;

DROP FUNCTION IF EXISTS asset_dep__straight_line_base
                        (numeric, numeric, numeric, numeric, numeric)
     CASCADE;

CREATE OR REPLACE FUNCTION asset_dep__straight_line_base
(in_base_life numeric, in_used numeric, in_basis numeric, in_dep_to_date numeric)
returns numeric as $$
SELECT CASE WHEN in_used/in_base_life * in_basis < in_basis - in_dep_to_date
                 THEN in_used/in_base_life * in_basis
            ELSE in_basis - in_dep_to_date
            END;
$$ language sql;

COMMENT ON FUNCTION asset_dep__straight_line_base
(in_base_life numeric, in_used numeric, in_basis numeric,
 in_dep_to_date numeric) IS
$$ This function is a basic function which does the actual calculation for
straight line depreciation.$$;

CREATE OR REPLACE FUNCTION asset_dep__used_months
(in_last_dep date, in_dep_date date, in_usable_life numeric)
RETURNS numeric AS
$$
select CASE WHEN extract('MONTHS' FROM (date_trunc('day', in_dep_date) - date_trunc('day', in_last_dep)))
                 > in_usable_life
            THEN in_usable_life
            ELSE extract('MONTHS' FROM (date_trunc('day', in_dep_date) - date_trunc('day', in_last_dep)))::numeric
            END;
$$ language sql;

COMMENT ON FUNCTION asset_dep__used_months
(in_last_dep date, in_dep_date date, in_usable_life numeric) IS
$$ This checks the interval between the two dates, and if longer than the
usable life, returns the months in that interval.  Otherwise returns the
usable life.$$;


CREATE OR REPLACE FUNCTION asset_dep_get_usable_life_yr
(in_usable_life numeric, in_start_date date, in_dep_date date)
returns numeric as
$$
   SELECT CASE WHEN in_dep_date IS NULL
                    or get_fractional_year(in_start_date, in_dep_date) > in_usable_life
               then in_usable_life
               WHEN get_fractional_year(in_start_date, in_dep_date) < 0
               THEN 0
               ELSE get_fractional_year(in_start_date, in_dep_date)
          END;
$$ language sql;

COMMENT ON FUNCTION asset_dep_get_usable_life_yr
(in_usable_life numeric, in_start_date date, in_dep_date date) IS
$$If the interval is less than 0 then 0.  If the interval is greater than the
usable life, then the usable life.  Otherwise, return the interval as a
fractional year.$$;

CREATE OR REPLACE FUNCTION months_passed (in_start timestamp, in_end timestamp)
returns int as
$$

-- The addition of one day is so that it will return '1' when run on the end
-- day of consecutive months.

select (extract (months from age(in_end + '1 day', in_start + '1 day'))
       + extract (years from age(in_end, in_start)) * 12)::int;
$$ language sql;

COMMENT ON FUNCTION months_passed (in_start timestamp, in_end timestamp) IS
$$ Returns the number of months between in_start and in_end.$$;

CREATE OR REPLACE FUNCTION asset_dep_straight_line_yr_d
(in_asset_ids int[],  in_report_date date, in_report_id int)
RETURNS bool AS
$$
     INSERT INTO asset_report_line (asset_id, report_id, amount, department_id,
                                   warehouse_id)
     SELECT ai.id, in_report_id,
            asset_dep__straight_line_base(
                  ai.usable_life, -- years
                  get_fractional_year(coalesce(max(report_date),
                                               start_depreciation),
                                      in_report_date),
                  purchase_value - salvage_value,
                  coalesce(sum(l.amount), 0)),
            ai.department_id, ai.location_id
       FROM asset_item ai
  LEFT JOIN asset_report_line l ON (l.asset_id = ai.id and l.amount > 0)
  LEFT JOIN asset_report r ON (l.report_id = r.id)
      WHERE ai.id = ANY(in_asset_ids)
   GROUP BY ai.id, ai.start_depreciation, ai.purchase_date, ai.purchase_value,
            ai.salvage_value, ai.department_id, ai.location_id, ai.usable_life;

    UPDATE asset_report SET report_class = 1 WHERE id = in_report_id;

    select true;
$$ language sql;



CREATE OR REPLACE FUNCTION asset_dep_straight_line_yr_m
(in_asset_ids int[],  in_report_date date, in_report_id int)
RETURNS bool AS
$$
     INSERT INTO asset_report_line (asset_id, report_id, amount, department_id,
                                   warehouse_id)
     SELECT ai.id, in_report_id,
            asset_dep__straight_line_base(
                  ai.usable_life * 12, --months
                  months_passed(coalesce(max(report_date),
                                         start_depreciation),
                                in_report_date),
                  purchase_value - salvage_value,
                  coalesce(sum(l.amount), 0)),
            ai.department_id, ai.location_id
       FROM asset_item ai
  LEFT JOIN asset_report_line l ON (l.asset_id = ai.id and l.amount > 0)
  LEFT JOIN asset_report r ON (l.report_id = r.id)
      WHERE ai.id = ANY(in_asset_ids)
   GROUP BY ai.id, ai.start_depreciation, ai.purchase_date, ai.purchase_value,
            ai.salvage_value, ai.department_id, ai.location_id, ai.usable_life;

    UPDATE asset_report SET report_class = 1 WHERE id = in_report_id;

    select true;
$$ language sql;

COMMENT ON FUNCTION asset_dep_straight_line_yr_m
(in_asset_ids int[],  in_report_date date, in_report_id int) is
$$ Performs straight line depreciation on a set of selected assets, selecting
the depreciation values into a report.

Assumes the usable life is measured in years, and is depreciated eavenly every
month.$$;

CREATE OR REPLACE FUNCTION asset_dep_straight_line_month
(in_asset_ids int[],  in_report_date date, in_report_id int)
RETURNS bool AS
$$
     INSERT INTO asset_report_line (asset_id, report_id, amount, department_id,
                                   warehouse_id)
     SELECT ai.id, in_report_id,
            asset_dep__straight_line_base(
                  ai.usable_life, --months
                  months_passed(coalesce(max(report_date),
                                         start_depreciation),
                                in_report_date),
                  purchase_value - salvage_value,
                  coalesce(sum(l.amount), 0)),
            ai.department_id, ai.location_id
       FROM asset_item ai
  LEFT JOIN asset_report_line l ON (l.asset_id = ai.id and l.amount > 0)
  LEFT JOIN asset_report r ON (l.report_id = r.id)
      WHERE ai.id = ANY(in_asset_ids)
   GROUP BY ai.id, ai.start_depreciation, ai.purchase_date, ai.purchase_value,
            ai.salvage_value, ai.department_id, ai.location_id, ai.usable_life;

    UPDATE asset_report SET report_class = 1 WHERE id = in_report_id;

    select true;
$$ language sql;

COMMENT ON FUNCTION asset_dep_straight_line_month
(in_asset_ids int[],  in_report_date date, in_report_id int) IS
$$ Performs straight line depreciation, selecting depreciation amounts, etc.
into a report for further review and approval.  Usable life is in months, and
depreciation is an equal amount every month.$$;

CREATE OR REPLACE FUNCTION asset_report__generate_gl(in_report_id int, in_accum_account_id int)
RETURNS INT AS
$$
DECLARE
        t_report_dept record;
        t_dep_amount numeric;

Begin

  INSERT INTO transactions (id, reference, description, transdate,
                        approved, trans_type_code, table_name)
        SELECT nextval('id'), setting_increment('glnumber'),
               'Asset Report ' || asset_report.id,
                report_date,
                coalesce((select value::boolean from defaults
                           where setting_key = 'debug_fixed_assets'), true),
                'fa', 'asset_report'
        FROM asset_report
        JOIN asset_report_line
                ON (asset_report.id = asset_report_line.report_id)
        JOIN asset_item
                ON (asset_report_line.asset_id = asset_item.id)
        WHERE asset_report.id = in_report_id
        GROUP BY asset_report.id, asset_report.report_date;

  IF NOT FOUND THEN
    RAISE WARNING 'asset_report__generate_gl(): Nothing to generate -- report has no lines';
    RETURN in_report_id;
  END IF;

        INSERT INTO acc_trans (trans_id, chart_id, transdate, approved,
                              amount_bc, curr, amount_tc)
        SELECT currval('id'), a.exp_account_id, r.report_date, true, sum(amount) * -1,
               defaults_get_defaultcurrency(), sum(amount) * -1
        FROM asset_report r
        JOIN asset_report_line l ON (r.id = l.report_id)
        JOIN asset_item a ON (l.asset_id = a.id)
        WHERE r.id = in_report_id
        GROUP BY currval('id'), r.report_date, a.exp_account_id;

        INSERT INTO acc_trans (trans_id, chart_id, transdate, approved,
                               amount_bc, curr, amount_tc)
        SELECT currval('id'), a.dep_account_id, r.report_date, true, sum(amount),
               defaults_get_defaultcurrency(), sum(amount)
        FROM asset_report r
        JOIN asset_report_line l ON (r.id = l.report_id)
        JOIN asset_item a ON (l.asset_id = a.id)
        WHERE r.id = in_report_id
        GROUP BY currval('id'), a.dep_account_id, r.report_date, a.tag, a.description;

        UPDATE asset_report
           SET trans_id = currval('id')
         WHERE id = in_report_id;

        RETURN in_report_id;
END;
$$ language plpgsql;

COMMENT ON FUNCTION asset_report__generate_gl
(in_report_id int, in_accum_account_id int) IS
$$ Generates a GL transaction when the Asset report is approved.

Create approved transactions, unless the value of the setting_key
'debug_fixed_assets' evaluates to false
$$;

CREATE OR REPLACE FUNCTION asset_class__get (in_id int) RETURNS asset_class AS
$$
        SELECT * FROM asset_class WHERE id = in_id;
$$ language sql;

COMMENT ON FUNCTION asset_class__get (in_id int) IS
$$ returns the row from asset_class identified by in_id.$$;

CREATE OR REPLACE FUNCTION asset_class__list() RETURNS SETOF asset_class AS
$$
SELECT * FROM asset_class ORDER BY label;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION asset_class__list() is
$$ Returns an alphabetical list of asset classes.$$;

DROP TYPE IF EXISTS asset_class_result CASCADE;
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
        label text
);

CREATE OR REPLACE FUNCTION asset_class__search
(in_asset_account_id int, in_dep_account_id int,
in_method int, in_label text)
RETURNS SETOF asset_class_result AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT ac.id, ac.asset_account_id, aa.accno, aa.description,
                        ac.dep_account_id, ad.accno, ad.description,
                        m.method, ac.method,
                        ac.label
                FROM asset_class ac
                LEFT JOIN account aa ON (aa.id = ac.asset_account_id)
                LEFT JOIN account ad ON (ad.id = ac.dep_account_id)
                JOIN asset_dep_method m ON (ac.method = m.id)
                WHERE
                        ($1 is null
                                or $1 = ac.asset_account_id)
                        AND ($2 is null OR
                                $2 = ac.dep_account_id)
                        AND ($3 is null OR $3 = ac.method)
                        AND ($4 IS NULL OR ac.label LIKE
                                '%' || $4 || '%')
               ORDER BY label
$sql$
USING in_asset_account_id, in_dep_account_id, in_method, in_label;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION asset_class__search
(in_asset_account_id int, in_dep_account_id int,
in_method int, in_label text) IS
$$ Returns a list of matching asset classes.  The account id's are exact matches
as is the method, but the label is a partial match.  NULL's match all.$$;


CREATE OR REPLACE FUNCTION asset_class__get_dep_methods()
RETURNS SETOF asset_dep_method as $$
SELECT * FROM asset_dep_method ORDER BY method;
$$ LANGUAGE sql;

COMMENT ON FUNCTION asset_class__get_dep_methods() IS
$$ Returns a set of asset_dep_methods ordered by the method label.$$;

CREATE OR REPLACE FUNCTION asset_class__save
(in_id int, in_asset_account_id int, in_dep_account_id int,
in_method int, in_label text, in_unit_label text)
RETURNS asset_class AS
$$
DECLARE ret_val asset_class;
BEGIN
        UPDATE asset_class
        SET asset_account_id = in_asset_account_id,
                dep_account_id = in_dep_account_id,
                method = in_method,
                label = in_label
        WHERE id = in_id;

        IF FOUND THEN
                SELECT * INTO ret_val FROM asset_class where id = in_id;
                RETURN ret_val;
        END IF;

        INSERT INTO asset_class (asset_account_id, dep_account_id, method,
                label)
        VALUES (in_asset_account_id, in_dep_account_id, in_method,
                in_label);

        SELECT * INTO ret_val FROM asset_class
        WHERE id = currval('asset_class_id_seq');

        RETURN ret_val;
END;
$$ language plpgsql;

COMMENT ON FUNCTION asset_class__save
(in_id int, in_asset_account_id int, in_dep_account_id int,
in_method int, in_label text, in_unit_label text) IS
$$ Saves this data as an asset_class record.  If in_id is NULL or is not found
in the table, inserts a new row.  Returns the row saved.$$;

CREATE OR REPLACE FUNCTION asset__get (in_id int, in_tag text)
RETURNS asset_item AS
$$
        SELECT * from asset_item WHERE id = in_id OR in_tag = tag
        ORDER BY id desc limit 1;
$$ language sql;

COMMENT ON FUNCTION asset__get (in_id int, in_tag text) IS
$$ Retrieves a given asset either by id or tag.  Both are complete matches.

Note that the behavior is undefined if both id and tag are provided.$$;

CREATE OR REPLACE FUNCTION asset__search
(in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric)
RETURNS SETOF asset_item AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
                SELECT * FROM asset_item
                WHERE ($1 is null
                        or asset_class_id = $1)
                        AND ($2 is null or description
                                LIKE '%' || $2 || '%')
                        and ($3 is null or tag like '%'||$3||'%')
                        AND ($4 is null
                                or purchase_date = $4)
                        AND ($5 is null
                                or $5 = purchase_value)
                        AND ($6 is null
                                or $6 = usable_life)
                        AND ($7 is null
                                OR $7 = salvage_value)
$sql$
USING in_asset_class, in_description, in_tag, in_purchase_date,
 in_purchase_value, in_usable_life, in_salvage_value;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION asset__search
(in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric) IS
$$Searches for assets.  Nulls match all records.  Asset class is exact,
as is purchase date, purchase value, and salvage value. Tag and description
are partial matches.$$;


CREATE OR REPLACE FUNCTION asset_class__get_asset_accounts()
RETURNS SETOF account AS $$
SELECT * FROM account
WHERE id IN
        (select account_id from account_link where description = 'Fixed_Asset')
ORDER BY accno;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION asset_class__get_asset_accounts()
IS
$$ Returns a list of fixed asset accounts, ordered by account number$$;

CREATE OR REPLACE FUNCTION asset_class__get_dep_accounts()
RETURNS SETOF account AS $$
SELECT * FROM account
WHERE id IN
        (select account_id from account_link where description = 'Asset_Dep')
ORDER BY accno;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION asset_class__get_dep_accounts() IS
$$ Returns a list of asset depreciation accounts, ordered by account number$$;

DROP FUNCTION IF EXISTS asset__save
(in_id int, in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric,
in_start_depreciation date, in_warehouse_id int,
in_department_id int, in_invoice_id int,
in_asset_account_id int, in_dep_account_id int, in_exp_account_id int);

CREATE OR REPLACE FUNCTION asset__save
(in_id int, in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric,
in_start_depreciation date, in_warehouse_id int,
in_department_id int, in_invoice_id int,
in_asset_account_id int, in_dep_account_id int, in_exp_account_id int,
in_obsolete_by int)
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
                location_id = in_warehouse_id,
                department_id = in_department_id,
                invoice_id = in_invoice_id,
                salvage_value = in_salvage_value,
                asset_account_id = in_asset_account_id,
                exp_account_id = in_exp_account_id,
                start_depreciation =
                         coalesce(in_start_depreciation, in_purchase_date),
                dep_account_id = in_dep_account_id,
                obsolete_by = in_obsolete_by
        WHERE id = in_id;
        IF FOUND THEN
                SELECT * INTO ret_val FROM asset_item WHERE id = in_id;
                return ret_val;
        END IF;

        INSERT INTO asset_item (asset_class_id, description, tag, purchase_date,
                purchase_value, usable_life, salvage_value, department_id,
                location_id, invoice_id, asset_account_id, dep_account_id,
                start_depreciation, exp_account_id, obsolete_by)
        VALUES (in_asset_class, in_description, in_tag, in_purchase_date,
                in_purchase_value, in_usable_life, in_salvage_value,
                in_department_id, in_warehouse_id, in_invoice_id,
                in_asset_account_id, in_dep_account_id,
                coalesce(in_start_depreciation, in_purchase_date),
                in_exp_account_id, in_obsolete_by);

        SELECT * INTO ret_val FROM asset_item
        WHERE id = currval('asset_item_id_seq');
        RETURN ret_val;
END;
$$ language plpgsql;

COMMENT ON FUNCTION asset__save
(in_id int, in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric,
in_start_depreciation date, in_warehouse_id int,
in_department_id int, in_invoice_id int,
in_asset_account_id int, in_dep_account_id int, in_exp_account_id int,
in_obsolete_by int) IS
$$ Saves the asset with the information provided.  If the id is provided,
overwrites the record with the id.  Otherwise, or if that record is not found,
inserts.  Returns the row inserted or updated.
$$;

CREATE OR REPLACE FUNCTION asset_item__search
(in_id int, in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric,
in_start_depreciation date, in_warehouse_id int,
in_department_id int, in_invoice_id int,
in_asset_account_id int, in_dep_account_id int)
returns setof asset_item as
$$
BEGIN
RETURN QUERY EXECUTE $sql$
         SELECT * FROM asset_item
          WHERE (id = $1 or $1 is null)
                and (asset_class_id = $2 or $2 is null)
                and (description like '%'||$3||'%'
                     or $3 is null)
                and (tag like '%' || $4 || '%' or $4 is null)
                and (purchase_value = $6
                    or $6 is null)
                and ($5 = purchase_date
                    or $5 is null)
                and (start_depreciation = $9
                    or $9 is null)
                and ($10 = location_id OR $10 is null)
                and (department_id = $11
                    or $11 is null)
                and ($12 = invoice_id OR $12 IS NULL)
                and (asset_account_id = $13
                    or $13 is null)
                and (dep_account_id = $14
                    or $14 is null)
$sql$
USING in_id, in_asset_class, in_description, in_tag,
in_purchase_date, in_purchase_value, in_usable_life, in_salvage_value,
in_start_depreciation, in_warehouse_id, in_department_id, in_invoice_id,
in_asset_account_id, in_dep_account_id;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION asset_item__search
(in_id int, in_asset_class int, in_description text, in_tag text,
in_purchase_date date, in_purchase_value numeric,
in_usable_life numeric, in_salvage_value numeric,
in_start_depreciation date, in_warehouse_id int,
in_department_id int, in_invoice_id int,
in_asset_account_id int, in_dep_account_id int) IS
$$ Returns a list of matching asset items.  Nulls match all records.
Tag and description allow for partial match.  All other matches are exact.$$;

CREATE OR REPLACE FUNCTION asset_class__get_dep_method (in_asset_class int)
RETURNS asset_dep_method AS $$
SELECT * from asset_dep_method
WHERE id = (select method from asset_class where id = in_asset_class);
$$ language sql;

COMMENT ON FUNCTION asset_class__get_dep_method (in_asset_class int) IS
$$Returns the depreciation method associated with the asset class.$$;

CREATE OR REPLACE FUNCTION asset_report__save
(in_id int, in_report_date date, in_report_class int, in_asset_class int,
in_submit bool)
          RETURNS asset_report AS
$$
DECLARE
        ret_val asset_report;
        item record;
        method_text text;
BEGIN
        UPDATE asset_report
        set asset_class = in_asset_class,
                report_class = in_report_class,
                report_date = in_report_date,
                submitted = (in_submit or submitted)
        WHERE id = in_id;

        IF FOUND THEN
                SELECT * INTO ret_val FROM asset_report WHERE id = in_id;
        ELSE
                INSERT INTO asset_report(report_class, asset_class, report_date,
                        submitted)
                values (in_report_class, in_asset_class, in_report_date,
                        coalesce(in_submit, true));

                SELECT * INTO ret_val FROM asset_report
                WHERE id = currval('asset_report_id_seq');

        END IF;
        RETURN ret_val;

END;
$$ language plpgsql;

COMMENT ON FUNCTION asset_report__save
(in_id int, in_report_date date, in_report_class int, in_asset_class int,
in_submit bool) IS
$$ Creates or updates an asset report with the information presented.  Note that
approval values are not set here, and that one cannot unsubmit a report though
this function.$$;

CREATE OR REPLACE FUNCTION asset_report__dispose
(in_id int, in_asset_id int, in_amount numeric, in_dm int,
in_percent_disposed numeric)
returns bool AS
$$
BEGIN
    INSERT
      INTO asset_report_line (report_id, asset_id, amount)
    values (in_id, in_asset_id, in_amount);

    INSERT
      INTO asset_rl_to_disposal_method
           (report_id, asset_id, disposal_method_id, percent_disposed)
    VALUES (in_id, in_asset_id, in_dm, in_percent_disposed);

    RETURN TRUE;
    END;
$$ language PLPGSQL;

COMMENT ON FUNCTION asset_report__dispose
(in_id int, in_asset_id int, in_amount numeric, in_dm int,
in_percent_disposed numeric) IS
$$ Disposes of an asset.  in_dm is the disposal method id.$$;

DROP TYPE IF EXISTS asset_disposal_report_line CASCADE;
CREATE TYPE asset_disposal_report_line
AS (
  id int,
  tag text,
  description text,
  start_dep date,
  disposed_on date,
  dm char(1),
  purchase_value numeric,
  accum_depreciation numeric,
  disposal_amt numeric,
  adj_basis numeric,
  gain_loss numeric
);

CREATE OR REPLACE FUNCTION asset_report__get_disposal (in_id int)
returns setof asset_disposal_report_line AS
$$
   SELECT ai.id, ai.tag, ai.description, ai.start_depreciation, r.report_date,
          dm.short_label, ai.purchase_value,
          sum (CASE WHEN pr.report_class in (1,3) THEN prl.amount ELSE 0 END)
          as accum_dep,
          l.amount,
          ai.purchase_value - sum(CASE WHEN pr.report_class in (1,3)
                                       THEN prl.amount
                                       ELSE 0
                                   END) as adjusted_basis,
          l.amount - ai.purchase_value + sum(CASE WHEN pr.report_class in (1,3)
                                                  THEN prl.amount
                                                  ELSE 0
                                              END) as gain_loss
     FROM asset_item ai
     JOIN asset_report_line l   ON (l.report_id = in_id AND ai.id = l.asset_id)
     JOIN asset_report r        ON (l.report_id = r.id)
LEFT JOIN asset_rl_to_disposal_method adm
                             USING (report_id, asset_id)
     JOIN asset_disposal_method dm
                                ON (adm.disposal_method_id = dm.id)
LEFT JOIN asset_report_line prl ON (prl.report_id <> in_id
                                   AND ai.id = prl.asset_id)
LEFT JOIN asset_report pr       ON (prl.report_id = pr.id)
 GROUP BY ai.id, ai.tag, ai.description, ai.start_depreciation, r.report_date,
          ai.purchase_value, l.amount, dm.short_label
 ORDER BY ai.id, ai.tag;
$$ language sql;

COMMENT ON FUNCTION asset_report__get_disposal (in_id int) IS
$$ Returns a set of lines of disposed assets in a disposal report, specified
by the report id.$$;

DROP TYPE IF EXISTS asset_nbv_line CASCADE;

CREATE TYPE asset_nbv_line AS (
    id int,
    tag text,
    description text,
    begin_depreciation date,
    method text,
    remaining_life numeric,
    basis numeric,
    salvage_value numeric,
    through_date date,
    accum_depreciation numeric,
    net_book_value numeric
);


CREATE OR REPLACE FUNCTION asset_nbv_report ()
returns setof asset_nbv_line AS
$$
BEGIN
RETURN QUERY EXECUTE $sql$
   SELECT ai.id, ai.tag, ai.description, ai.start_depreciation,
          adm.short_name, ai.usable_life
           - months_passed(ai.start_depreciation,
                                  coalesce(max(r.report_date),
                                    ai.start_depreciation))/(case when adm.unit_label='in years' then 12 else 1 end),
          ai.purchase_value - ai.salvage_value, ai.salvage_value, max(r.report_date),
          sum(rl.amount), ai.purchase_value - coalesce(sum(rl.amount), 0)
     FROM asset_item ai
     JOIN asset_class ac ON (ai.asset_class_id = ac.id)
     JOIN asset_dep_method adm ON (adm.id = ac.method)
LEFT JOIN (select arl.*
             from asset_report_line arl
             join asset_report ar on arl.report_id = ar.id
            where approved_at is not null) rl ON (ai.id = rl.asset_id)
LEFT JOIN asset_report r on (rl.report_id = r.id)
    WHERE r.id IS NULL OR r.approved_at IS NOT NULL
 GROUP BY ai.id, ai.tag, ai.description, ai.start_depreciation, ai.purchase_date,
          adm.short_name, adm.unit_label, ai.usable_life, ai.purchase_value, salvage_value
   HAVING (NOT 2 = ANY(array_agg(r.report_class)))
          AND (NOT 4 = ANY(array_agg(r.report_class)))
          OR max(r.report_class) IS NULL
 ORDER BY ai.id, ai.tag, ai.description
$sql$;
END
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION asset_nbv_report () IS
$$ Returns the current net book value report.$$;

DROP TYPE IF EXISTS partial_disposal_line CASCADE;
CREATE TYPE partial_disposal_line AS (
  id int,
  tag text,
  description text,
  start_dep date,
  purchase_value numeric,
  disposal_date date,
  percent_disposed numeric,
  disposed_acquired_value numeric,
  percent_remaining numeric,
  remaining_aquired_value numeric
);

CREATE OR REPLACE FUNCTION asset_report_partial_disposal_details(in_id int)
RETURNS SETOF PARTIAL_DISPOSAL_LINE AS
$$
SELECT ai.id, ai.tag, ai.description, ai.start_depreciation, ai.purchase_value,
       ar.report_date, arld.percent_disposed,
       (arld.percent_disposed / 100) * ai.purchase_value,
       100 - arld.percent_disposed,
       ((100 - arld.percent_disposed)/100) * ai.purchase_value
  FROM asset_item ai
  JOIN asset_report_line l ON (ai.id = l.asset_id)
  JOIN asset_report ar ON (ar.id = l.report_id)
  JOIN asset_rl_to_disposal_method arld
       ON  ((arld.report_id, arld.asset_id) = (l.report_id, l.asset_id))
 WHERE ar.id = in_id;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION asset_report_partial_disposal_details(in_id int) IS
$$ Returns the partial disposal details for a partial disposal report.$$;

DROP FUNCTION IF EXISTS asset_report__approve(int, int, int, int);

CREATE OR REPLACE FUNCTION asset_report__approve
(in_id int, in_expense_acct int, in_gain_acct int, in_loss_acct int, in_cash_acct int)
RETURNS asset_report AS
$$
DECLARE ret_val asset_report;
BEGIN
        UPDATE asset_report
           SET approved_at = now(),
               approved_by = person__get_my_entity_id()
         where id = in_id;
        SELECT * INTO ret_val FROM asset_report WHERE id = in_id;
        if ret_val.dont_approve is not true then
                if ret_val.report_class = 1 THEN
                    PERFORM asset_report__generate_gl(in_id, in_expense_acct);
                ELSIF ret_val.report_class = 2 THEN
                    PERFORM asset_report__disposal_gl(
                                 in_id, in_gain_acct, in_loss_acct, in_cash_acct);
                ELSIF ret_val.report_class = 4 THEN
                    PERFORM asset_disposal__approve(in_id, in_gain_acct, in_loss_acct, (select asset_account_id from asset_class
                                                                                         where id = ret_val.asset_class)
                                                   );
                ELSE RAISE EXCEPTION 'Invalid report class';
                END IF;
        end if;
        SELECT * INTO ret_val FROM asset_report WHERE id = in_id;
        RETURN ret_val;
end;
$$ language plpgsql;
revoke execute on function asset_report__approve(int, int, int, int, int) from public;

COMMENT ON function asset_report__approve(int, int, int, int, int) is
$$ This function approves an asset report (whether depreciation or disposal).
Also generates relevant GL drafts for review and posting.$$;

DROP FUNCTION IF EXISTS asset_report__disposal_gl(int, int, int);

CREATE OR REPLACE FUNCTION asset_report__disposal_gl
(in_id int, in_gain_acct int, in_loss_acct int, in_cash_acct int)
RETURNS bool AS
$$
  INSERT INTO transactions (
    id, reference,
    description,
    transdate, approved, trans_type_code, table_name)
  SELECT nextval('id'), setting_increment('glnumber'),
        'Asset Report ' || asset_report.id,
        report_date, false, 'fd', 'asset_report'
    FROM asset_report
  WHERE asset_report.id = in_id;

  UPDATE asset_report
     SET trans_id = currval('id')
   WHERE id = in_id;

  -- Clear cumulative depreciation account
  INSERT
    INTO acc_trans (chart_id, trans_id, amount_bc, curr, amount_tc,
                    approved, transdate)
  SELECT a.dep_account_id, currval('id')::int, sum(r.accum_depreciation) * -1,
         defaults_get_defaultcurrency(), sum(r.accum_depreciation) * -1,
         TRUE, r.disposed_on
    FROM asset_report__get_disposal(in_id) r
    JOIN asset_item a ON (r.id = a.id)
   GROUP BY a.dep_account_id, r.disposed_on
  HAVING sum(r.accum_depreciation) <> 0;

  -- Add cash from sale(=disposal)
  INSERT
    INTO acc_trans (chart_id, trans_id, amount_bc, curr, amount_tc,
                    approved, transdate)
  SELECT in_cash_acct, currval('id')::int, sum(r.disposal_amt) * -1,
         defaults_get_defaultcurrency(), sum(r.disposal_amt) * -1,
         TRUE, r.disposed_on
    FROM asset_report__get_disposal(in_id) r
    JOIN asset_item ai ON (r.id = ai.id)
   GROUP BY r.disposed_on
  HAVING sum(r.disposal_amt) <> 0;

  -- GAIN is negative since it is a debit
  INSERT
    INTO acc_trans (chart_id, trans_id, amount_bc, curr, amount_tc,
                    approved, transdate)
  SELECT case when sum(r.gain_loss) > 0 THEN in_loss_acct else in_gain_acct end,
         currval('id')::int, sum(r.gain_loss), defaults_get_defaultcurrency(),
         sum(r.gain_loss),
         TRUE, r.disposed_on
    FROM asset_report__get_disposal(in_id) r
    JOIN asset_item ai ON (r.id = ai.id)
   GROUP BY r.disposed_on;

  -- Clear asset from asset account
  INSERT
    INTO acc_trans (chart_id, trans_id, amount_bc, curr, amount_tc,
                    approved, transdate)
  SELECT a.asset_account_id, currval('id')::int, sum(r.purchase_value),
         defaults_get_defaultcurrency(), sum(r.purchase_value),
         TRUE, r.disposed_on
    FROM asset_report__get_disposal(in_id) r
    JOIN asset_item a ON (r.id = a.id)
   GROUP BY a.asset_account_id, r.disposed_on
  HAVING sum(r.purchase_value) <> 0;


  SELECT TRUE;
$$ language sql;

COMMENT ON  FUNCTION asset_report__disposal_gl
(in_id int, in_gain_acct int, in_loss_acct int, in_cash_acct int) IS
$$ Generates GL transactions for ful disposal reports.$$;


CREATE OR REPLACE FUNCTION asset_item__add_note(in_id int, in_subject text, in_note text)
RETURNS asset_note AS
$$
INSERT INTO asset_note (ref_key, subject, note)
  values (in_id, in_subject, in_note)
RETURNING *;
$$ language sql;

COMMENT ON FUNCTION asset_item__add_note(in_id int, in_subject text,
in_note text) IS $$ Adds a note to an asset item$$;

CREATE OR REPLACE FUNCTION asset_report__get_expense_accts()
RETURNS SETOF account
AS $$
    SELECT * FROM account__get_by_link_desc('asset_expense');
$$ language sql;

COMMENT ON FUNCTION asset_report__get_expense_accts() IS
$$ Lists all asset expense reports.$$;

CREATE OR REPLACE FUNCTION asset_report__get_gain_accts()
RETURNS SETOF account
AS $$
    SELECT * FROM account__get_by_link_desc('asset_gain');
$$ language sql;

COMMENT ON FUNCTION asset_report__get_gain_accts() IS
$$ Returns a list of gain accounts for asset depreciation and disposal reports.
$$;

CREATE OR REPLACE FUNCTION asset_report__get_loss_accts()
RETURNS SETOF account
AS $$
    SELECT * FROM account__get_by_link_desc('asset_loss');
$$ language sql;

CREATE OR REPLACE FUNCTION asset_report__get_cash_accts()
RETURNS SETOF account
AS $$
  SELECT * FROM account where not obsolete;
$$ language sql;

COMMENT ON FUNCTION asset_report__get_loss_accts() IS
$$ Returns a list of loss accounts for asset depreciation and disposal reports.
$$;

CREATE OR REPLACE FUNCTION asset_report__get(in_id int)
RETURNS asset_report
AS
$$
select * from asset_report where id = in_id;
$$ language sql;

COMMENT ON FUNCTION asset_report__get(in_id int) IS
$$ Returns the asset_report line identified by id.$$;

DROP TYPE IF EXISTS asset_report_line_result CASCADE;
CREATE TYPE asset_report_line_result AS(
     tag text,
     start_depreciation date,
     purchase_value numeric,
     method_short_name text,
     usable_life numeric,
     basis numeric,
     prior_through date,
     prior_dep numeric,
     dep_this_time numeric,
     dep_ytd numeric,
     dep_total numeric,
     description text,
     purchase_date date
);

CREATE OR REPLACE FUNCTION asset_report__get_lines(in_id int)
RETURNS SETOF asset_report_line_result
as $$
   select ai.tag, ai.start_depreciation, ai.purchase_value, m.short_name,
          ai.usable_life,
          ai.purchase_value - ai.salvage_value, max(pr.report_date),
          sum(case when pr.report_date < r.report_date then prl.amount
                   else 0
                end),
          rl.amount,
          sum (case when extract(year from pr.report_date)
                         = extract(year from r.report_date)
                         AND pr.report_date < r.report_date
                    then prl.amount
                    else 0
                end),
          sum(prl.amount),
          ai.description, ai.purchase_date
     FROM asset_item ai
     JOIN asset_class c ON (ai.asset_class_id = c.id)
     JOIN asset_dep_method m ON (c.method = m.id)
     JOIN asset_report_line rl ON (rl.asset_id = ai.id)
     JOIN asset_report r ON (rl.report_id = r.id)
LEFT JOIN asset_report_line prl ON (prl.asset_id = ai.id)
LEFT JOIN asset_report pr ON (prl.report_id = pr.id)
    WHERE rl.report_id = in_id
 GROUP BY ai.tag, ai.start_depreciation, ai.purchase_value, m.short_name,
          ai.usable_life, ai.salvage_value, r.report_date, rl.amount,
          ai.description, ai.purchase_date;
$$ language sql;

COMMENT ON FUNCTION asset_report__get_lines(in_id int) IS
$$ Returns the lines of an asset depreciation report.$$;

DROP TYPE IF EXISTS asset_report_result CASCADE;
CREATE TYPE asset_report_result AS (
        id int,
        report_date date,
        gl_id bigint,
        asset_class bigint,
        report_class int,
        entered_by bigint,
        approved_by bigint,
        entered_at timestamp,
        approved_at timestamp,
        depreciated_qty numeric,
        dont_approve bool,
        submitted bool,
        total numeric
);

CREATE OR REPLACE FUNCTION asset_report__search
(in_start_date date, in_end_date date, in_asset_class int, in_approved bool,
 in_entered_by int)
returns setof asset_report_result AS $$

  SELECT r.id, r.report_date, r.trans_id, r.asset_class, r.report_class,
         r.entered_by, r.approved_by, r.entered_at, r.approved_at,
         r.depreciated_qty, r.dont_approve, r.submitted, sum(l.amount)
    FROM asset_report r
    JOIN asset_report_line l ON (l.report_id = r.id)
   where (in_start_date is null or in_start_date <= report_date)
         and (in_end_date is null or in_end_date >= report_date)
         and (in_asset_class is null or in_asset_class = asset_class)
         and (in_approved is null
              or (in_approved is true and approved_by is not null)
              or (in_approved is false and approved_by is null))
         and (in_entered_by is null or in_entered_by = entered_by)
GROUP BY r.id, r.report_date, r.trans_id, r.asset_class, r.report_class,
         r.entered_by, r.approved_by, r.entered_at, r.approved_at,
         r.depreciated_qty, r.dont_approve, r.submitted;
$$ language sql;

COMMENT ON FUNCTION asset_report__search
(in_start_date date, in_end_date date, in_asset_class int, in_approved bool,
 in_entered_by int) IS
$$ Searches for asset reports.  Nulls match all rows.  Approved, asset class,
and entered_by are exact matches.  Start_date and end_date define the beginning
and end of the search date. $$;

CREATE OR REPLACE FUNCTION asset_report__generate
(in_depreciation bool, in_asset_class int, in_report_date date)
RETURNS SETOF asset_item AS
$$
   SELECT ai.*
     FROM asset_item ai
     JOIN asset_class ac ON (ai.asset_class_id = ac.id)
LEFT JOIN asset_report_line arl ON (arl.asset_id = ai.id)
LEFT JOIN asset_report ar ON (arl.report_id = ar.id)
    WHERE ai.start_depreciation <= in_report_date AND ac.id = in_asset_class
          AND obsolete_by IS NULL
 GROUP BY ai.id, ai.tag, ai.description, ai.purchase_value, ai.usable_life,
          ai.purchase_date, ai.location_id, ai.invoice_id, ai.asset_account_id,
          ai.dep_account_id, ai.asset_class_id, ai.start_depreciation,
          ai.salvage_value, ai.department_id, ai.exp_account_id, ai.obsolete_by
   HAVING (count(ar.report_class) = 0 OR
          (2 <> ALL(array_agg(ar.report_class))
          and 4 <> ALL(array_agg(ar.report_class))))
          AND ((ai.purchase_value - coalesce(sum(arl.amount), 0)
               > ai.salvage_value) and ai.obsolete_by is null)
               OR in_depreciation is not true;
$$ language sql;

COMMENT ON FUNCTION asset_report__generate
(in_depreciation bool, in_asset_class int, in_report_date date) IS
$$ Generates lines to select/deselect for the asset report (depreciation or
disposal).$$;

CREATE OR REPLACE FUNCTION asset_report__begin_import
(in_asset_class int, in_report_date date)
returns asset_report as
$$
INSERT INTO asset_report (asset_class, report_date, entered_at, entered_by,
            report_class, dont_approve)
     VALUES (in_asset_class, in_report_date, now(), person__get_my_entity_id(),
            3, true);

SELECT * FROM asset_report where id = currval('asset_report_id_seq');

$$ language sql;

COMMENT ON FUNCTION asset_report__begin_import
(in_asset_class int, in_report_date date) IS
$$Creates the outline of an asset import report$$;

CREATE OR REPLACE FUNCTION asset_report__import(
        in_description text,
        in_tag text,
        in_purchase_value numeric,
        in_salvage_value numeric,
        in_usable_life numeric,
        in_purchase_date date,
        in_start_depreciation date,
        in_location_id int,
        in_department_id int,
        in_asset_account_id int,
        in_dep_account_id int,
        in_exp_account_id int,
        in_asset_class_id int,
        in_invoice_id int,
        in_dep_report_id int,
        in_accum_dep numeric,
        in_obsolete_other bool
)
RETURNS bool AS
$$

INSERT
  INTO asset_report_line
       (report_id, asset_id, amount, department_id, warehouse_id)
select in_dep_report_id, id, in_accum_dep, department_id, location_id
  from asset__save
       (NULL, in_asset_class_id, in_description, in_tag, in_purchase_date, in_purchase_value, in_usable_life, coalesce(in_salvage_value, 0), in_start_depreciation, in_location_id, in_department_id, in_invoice_id, in_asset_account_id,
        in_dep_account_id, in_exp_account_id, (select min(id) from asset_item where tag = in_tag));
      -- use 'min(id)' because the first record in the series will be deprecated
      -- by by another one; chances are nil that it's actually deprecat*ing* one

UPDATE asset_item
   SET obsolete_by = currval('asset_item_id_seq')
 WHERE tag = in_tag and in_obsolete_other is true
       and id = (select min(id) from asset_item where tag = in_tag);

UPDATE asset_item
   SET obsolete_by = NULL
 WHERE tag = in_tag and in_obsolete_other is true
       and id = currval('asset_item_id_seq');

SELECT true;
$$ language sql;

COMMENT ON FUNCTION asset_report__import(
        in_description text,
        in_tag text,
        in_purchase_value numeric,
        in_salvage_value numeric,
        in_usable_life numeric,
        in_purchase_date date,
        in_start_depreciation date,
        in_location_id int,
        in_department_id int,
        in_asset_account_id int,
        in_dep_account_id int,
        in_exp_account_id int,
        in_asset_class_id int,
        in_invoice_id int,
        in_dep_report_id int,
        in_accum_dep numeric,
        in_obsolete_other bool
) IS
$$ Imports an asset with the supplied information.  If in_obsolete_other is
false, this creates a new depreciable asset.  If it is true, it sets up the
other asset as obsolete.  This is the way partial disposal reports are handled.
$$;

CREATE OR REPLACE FUNCTION asset_report__begin_disposal
(in_asset_class int, in_report_date date, in_report_class int)
returns asset_report as $$
DECLARE retval asset_report;

begin

INSERT INTO asset_report (asset_class, report_date, entered_at, entered_by,
            report_class)
     VALUES (in_asset_class, in_report_date, now(), person__get_my_entity_id(),
            in_report_class);

SELECT * INTO retval FROM asset_report where id = currval('asset_report_id_seq');

return retval;

end;

$$ language plpgsql;

COMMENT ON FUNCTION asset_report__begin_disposal
(in_asset_class int, in_report_date date, in_report_class int) IS
$$ Creates the asset report record for the asset disposal report.$$;

create or replace function asset_report__record_approve(in_id int)
returns asset_report
as $$
UPDATE asset_report
   set approved_by = person__get_my_entity_id(),
       approved_at = now()
 where id = in_id;

select * from asset_report where id = in_id;

$$ language sql;

COMMENT ON FUNCTION asset_report__record_approve(in_id int) IS
$$Marks the asset_report record approved.  Not generally recommended to call
directly.$$;


CREATE OR REPLACE FUNCTION asset_report__get_disposal_methods()
RETURNS SETOF asset_disposal_method as
$$
SELECT * FROM asset_disposal_method order by label;
$$ language sql;

COMMENT ON FUNCTION asset_report__get_disposal_methods() IS
$$ Returns a list of asset_disposal_method items ordered by label.$$;

CREATE OR REPLACE FUNCTION asset_disposal__approve
(in_id int, in_gain_acct int, in_loss_acct int, in_asset_acct int)
returns asset_report
as $$
DECLARE
   retval asset_report;
   iter record;
   t_disposed_percent numeric;
begin
-- this code is fairly opaque and needs more documentation that would be
-- otherwise optimal. This is mostly due to the fact that we have fairly
-- repetitive insert/select routines and the fact that the accounting
-- requirements are not immediately intuitive.  Inserts marked functionally along
-- with typical debit/credit designations.  Note debits are always negative.


retval := asset_report__record_approve(in_id);
if retval.report_class = 2 then
     t_disposed_percent := 100;
end if;


  INSERT INTO transactions (id, reference, description, approved, transdate, trans_type_code, table_name)
  select nextval('id'), 'Asset Report ' || in_id, 'Asset Disposal Report for ' || report_date,
         false, report_date, 'fd', 'asset_report'
    FROM asset_report where id = in_id;

  UPDATE asset_report
     SET trans_id = currval('id')
   WHERE id = in_id;

-- REMOVING ASSETS FROM ACCOUNT (Credit)
insert into acc_trans (trans_id, chart_id, amount_bc, curr, amount_tc,
                       approved, transdate)
SELECT currval('id'), a.asset_account_id,
       a.purchase_value
       * (coalesce(t_disposed_percent, m.percent_disposed)/100),
       defaults_get_defaultcurrency(),
       a.purchase_value
       * (coalesce(t_disposed_percent, m.percent_disposed)/100),
       true, r.report_date
 FROM  asset_item a
 JOIN  asset_report_line l ON (l.asset_id = a.id)
 JOIN  asset_report r ON (r.id = l.report_id)
 JOIN  asset_rl_to_disposal_method m
        ON (l.report_id = m.report_id and l.asset_id = m.asset_id)
 WHERE r.id = in_id;

-- REMOVING ACCUM DEP. (Debit)
INSERT into acc_trans (trans_id, chart_id, amount_bc, curr, amount_tc,
                       approved, transdate)
SELECT currval('id'), a.dep_account_id,
       sum(dl.amount) * -1
       * (coalesce(t_disposed_percent, m.percent_disposed)/100),
       defaults_get_defaultcurrency(),
       sum(dl.amount) * -1
       * (coalesce(t_disposed_percent, m.percent_disposed)/100),
       true, r.report_date
 FROM  asset_item a
 JOIN  asset_report_line l ON (l.asset_id = a.id)
 JOIN  asset_report r ON (r.id = l.report_id)
 JOIN  asset_report_line dl ON (l.asset_id = dl.asset_id)
 JOIN  asset_rl_to_disposal_method m
        ON (l.report_id = m.report_id and l.asset_id = m.asset_id)
 JOIN  asset_report dr ON (dl.report_id = dr.id
                           and dr.report_class = 1
                           and dr.approved_at is not null)
 WHERE r.id = in_id
group by a.dep_account_id, m.percent_disposed, r.report_date;

-- INSERT asset/proceeds (Debit, credit for negative values)
INSERT INTO acc_trans (trans_id, chart_id, amount_bc, curr, amount_tc,
                       approved, transdate)
SELECT currval('id'), in_asset_acct, coalesce(l.amount, 0) * -1,
       defaults_get_defaultcurrency(), coalesce(l.amount, 0) * -1,
       true, r.report_date
 FROM  asset_item a
 JOIN  asset_report_line l ON (l.asset_id = a.id)
 JOIN  asset_report r ON (r.id = l.report_id)
 JOIN  asset_rl_to_disposal_method m
        ON (l.report_id = m.report_id and l.asset_id = m.asset_id)
 WHERE r.id = in_id;

-- INSERT GAIN/LOSS (Credit for gain, debit for loss)
INSERT INTO acc_trans(trans_id, chart_id, amount_bc, curr, amount_tc,
                      approved, transdate)
select currval('id'),
            CASE WHEN sum(amount_bc) > 0 THEN in_loss_acct
            else in_gain_acct
        END,
        sum(amount_bc) * -1, defaults_get_defaultcurrency(),
        sum(amount_tc) * -1 , true,
        retval.report_date
  FROM acc_trans
  WHERE trans_id = currval('id');

IF retval.report_class = 4 then
   PERFORM asset__import_from_disposal(retval.id);
end if;

return retval;
end;
$$ language plpgsql;

COMMENT ON FUNCTION asset_disposal__approve
(in_id int, in_gain_acct int, in_loss_acct int, in_asset_acct int)
IS $$ This approves the asset_report for disposals, creating relevant GL drafts.

If the report is a partial disposal report, imports remaining percentages as new
asset items.$$;

CREATE OR REPLACE FUNCTION asset__import_from_disposal(in_id int)
RETURNS BOOL AS
$$
DECLARE t_report asset_report;
        t_import asset_report;
BEGIN

    SELECT * INTO t_report from asset_report where id = in_id;

    if t_report.report_class <> 4 THEN RETURN FALSE;
    END IF;

    SELECT *
      INTO t_import
      FROM  asset_report__begin_import
            (t_report.asset_class::int, t_report.report_date);

    PERFORM asset_report__import(
        ai.description,
        ai.tag,
        ai.purchase_value * ( 100 - rld.percent_disposed ) / 100,
        ai.salvage_value * ( 100 - rld.percent_disposed ) / 100,
        ai.usable_life,
        ai.purchase_date,
        ai.start_depreciation,
        ai.location_id,
        ai.department_id,
        ai.asset_account_id,
        ai.dep_account_id,
        ai.exp_account_id,
        ai.asset_class_id,
        ai.invoice_id,
        t_import.id,
        r.accum_depreciation * ( 100 - rld.percent_disposed ) / 100,
        TRUE)
    FROM asset_item ai
    JOIN asset_report__get_disposal(t_report.id) r  ON (ai.id = r.id)
    JOIN asset_report_line rl ON (rl.asset_id = ai.id AND rl.report_id = in_id)
    join asset_rl_to_disposal_method rld
         ON (rl.report_id = rld.report_id and ai.id = rld.asset_id)
   where (rld.percent_disposed is null or percent_disposed < 100)
         and ai.obsolete_by is null;
   RETURN TRUE;
END;
$$ language plpgsql;

COMMENT ON FUNCTION asset__import_from_disposal(in_id int) IS
$$ Imports items from partial disposal reports. This function should not be
called dirctly by programmers but rather through the other disposal approval
api's.$$; --'

-- needed to go here because dependent on other functions in other modules. --CT
alter table asset_report alter column entered_by
set default person__get_my_entity_id();

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
