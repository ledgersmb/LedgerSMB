CREATE OR REPLACE FUNCTION inventory_get_item_at_day
(in_transdate date, in_partnumber text)
RETURNS parts AS
$$
DECLARE out_row parts%ROWTYPE;
	t_parts_id int;
BEGIN
	SELECT id INTO t_parts_id 
	FROM parts 
	WHERE (partnumber like in_partnumber|| ' %'
		or partnumber = in_partnumber)
		and obsolete is not true
		and assembly is not true;

        SELECT p.id, p.partnumber, p.description, p.unit, p.listprice, 
		p.sellprice, p.lastcost, p.priceupdate, p.weight, 
                sum(coalesce(c.multiplier, 1) * i.qty) * -1
                AS onhand, p.notes, p.makemodel, p.assembly, p.alternate, 
		p.rop, p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		p.bin, p.obsolete, p.bom, p.image, p.microfiche, p.partsgroup_id, 
		p.project_id
	INTO out_row
        FROM parts p
	LEFT JOIN (  SELECT product(qty) as multiplier, t_parts_id  as part_used
		FROM assembly a
		JOIN parts p ON (a.id = p.id and p.volume_break = true)
		JOIN (SELECT *, t_parts_id as part_used
                     FROM connectby('assembly', 'id', 'parts_id', 'id', 
			t_parts_id,
                                0, ',')
                        c(id integer, parent integer, "level" integer,
                                path text, list_order integer)
		) asm ON (asm.id = p.id)
	) c ON (c.part_used = t_parts_id)
        JOIN invoice i ON (i.parts_id = p.id OR i.parts_id = c.part_used)
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
                p.project_id, p.avgcost;

	RETURN out_row;
END;
$$ LANGUAGE PLPGSQL;

CREATE FUNCTION product (numeric, numeric) RETURNS numeric AS
$$
SELECT $1 * $2;
$$ language sql;

CREATE AGGREGATE product(
	base_type = numeric,
	sfunc = product,
	stype = numeric
);

CREATE OR REPLACE FUNCTION inventory_create_report(in_transdate date) RETURNS int
AS
$$
BEGIN
	INSERT INTO inventory_report(entry_date) values (in_transdate);
	RETURN currval('inventory_report_id_seq');
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION inventory_report__add_line
(in_report_id int, in_parts_id int, in_onhand int, in_counted int)
RETURNS int AS
$$
BEGIN
	INSERT INTO inventory_report_line(report_id, parts_id, onhand, counted)
	VALUES (in_report_id, in_parts_id, in_onhand, in_counted);

	RETURN currval('inventory_report_line_id_seq');
end;
$$ LANGUAGE plpgsql;
