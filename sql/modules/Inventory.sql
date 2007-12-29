CREATE OR REPLACE FUNCTION inventory_get_item_at_day
(in_transdate date, in_partnumber text)
RETURNS parts AS
$$
DECLARE out_row parts%ROWTYPE;
BEGIN
        SELECT p.id, p.partnumber, p.description, p.unit, p.listprice, 
		p.sellprice, p.lastcost, p.priceupdate, p.weight, 
                p.onhand - sum(coalesce(i.qty, 0))
                AS onhand, p.notes, p.makemodel, p.assembly, p.alternate, 
		p.rop, p.inventory_accno_id, p.income_accno_id, p.expense_accno_id,
		p.bin, p.obsolete, p.bom, p.image, p.microfiche, p.partsgroup_id, 
		p.project_id, p.avgcost
	INTO out_row;
        FROM parts p
        LEFT JOIN invoice i ON (i.parts_id = p.id
                AND i.trans_id IN 
                        (select id FROM ar WHERE transdate > in_trans_date
                        UNION 
                        SELECT id FROM ap WHERE transdate > in_trans_date))
        WHERE p.partnumber = in_partnumber
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
$$ LANGUAGE plpgsql;
