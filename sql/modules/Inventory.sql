BEGIN;

CREATE OR REPLACE FUNCTION inventory_get_item_at_day
(in_transdate date, in_partnumber text)
RETURNS parts AS
$$
DECLARE out_row RECORD;
	t_parts_id int;
        int_outrow RECORD;
BEGIN
	SELECT id INTO t_parts_id
	FROM parts
	WHERE (partnumber like in_partnumber|| ' %'
		or partnumber = in_partnumber)
		and obsolete is not true
		and assembly is not true;

        SELECT * INTO out_row FROM parts WHERE id = t_parts_id;

        WITH RECURSIVE c AS (
             SELECT 1::numeric as multiplier, t_parts_id  as part_used,
                    t_parts_id as current_part_id
             UNION ALL
             SELECT c.multiplier * a.qty, t_parts_id as part_used,
                    a.parts_id as current_part_id
               FROM assembly a
               JOIN c ON c.current_part_id = a.id
        )
        SELECT  sum(coalesce(c.multiplier, 1) * i.qty) * -1
                AS onhand
	INTO int_outrow
        FROM parts p
	LEFT JOIN c ON c.part_used = t_parts_id
        JOIN invoice i ON (i.parts_id = p.id OR i.parts_id = c.current_part_id)
	JOIN (select id, transdate from ar
		UNION select id, transdate from ap) a ON (i.trans_id = a.id)

        WHERE (p.partnumber = in_partnumber
		or p.partnumber like in_partnumber || ' %')
		AND a.transdate <= in_transdate
                AND assembly IS FALSE AND obsolete IS NOT TRUE
        GROUP BY p.id, p.partnumber, p.description, p.unit, p.listprice,
                p.sellprice, p.lastcost, p.priceupdate, p.weight,
                p.onhand, p.notes, p.makemodel, p.assembly, p.alternate,
                p.rop, p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
                p.bin, p.obsolete, p.bom, p.image, p.microfiche, p.partsgroup_id,
                p.avgcost;

        out_row.onhand := int_outrow.onhand;
	RETURN out_row;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION product (numeric, numeric) RETURNS numeric AS
$$
SELECT $1 * $2;
$$ language sql;

DROP AGGREGATE IF EXISTS product(numeric);

CREATE AGGREGATE product(
	basetype = numeric,
	sfunc = product,
	stype = numeric
);

CREATE OR REPLACE FUNCTION inventory_create_report(in_transdate date) RETURNS int
AS
$$
	INSERT INTO inventory_report(transdate) values (in_transdate)
        RETURNING id;
$$ language sql;

CREATE OR REPLACE FUNCTION inventory_report__add_line
(in_report_id int, in_parts_id int, in_onhand int, in_counted int)
RETURNS int AS
$$
	INSERT INTO inventory_report_line(adjust_id, parts_id, expected, counted)
	VALUES (in_report_id, in_parts_id, in_onhand, in_counted)
        RETURNING adjust_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION inventory__get_item_by_partnumber(in_partnumber text)
RETURNS parts LANGUAGE SQL AS
$$
SELECT * FROM parts WHERE obsolete is not true AND partnumber = $1;
$$;

CREATE OR REPLACE FUNCTION inventory__get_item_by_id(in_id int)
RETURNS parts LANGUAGE SQL AS
$$
SELECT * FROM parts WHERE id = $1;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
