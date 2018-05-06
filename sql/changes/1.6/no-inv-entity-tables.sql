

CREATE TEMPORARY TABLE _inv_report ON COMMIT DROP AS
   SELECT nextval('id') as trans_id,
          id, transdate, source, ar_trans_id, ap_trans_id
     FROM inventory_report;


INSERT INTO gl (id, description, transdate, reference, approved,
                trans_type_code)
   SELECT trans_id, 'Transaction due to approval of inventory adjustment',
          transdate, 'invadj-' || id, true, 'ia'
     FROM _inv_report;


ALTER TABLE inventory_report
    ADD COLUMN trans_id int REFERENCES gl(id);

COMMENT ON COLUMN inventory_report.trans_id IS
$$Indicates the associated transaction representing the financial
facts associated with the inventory adjustment. (NULL until the report
is approved)$$;



UPDATE inventory_report ir
   SET trans_id = (select trans_id from _inv_report _ir where _ir.id = ir.id);



-- Migrate existing data

UPDATE acc_trans ac
   SET trans_id = (SELECT trans_id
                     FROM inventory_report ir
                    WHERE ac.trans_id = ir.ap_trans_id)
 WHERE trans_id IN (SELECT ap_trans_id FROM inventory_report);
UPDATE acc_trans ac
   SET trans_id = (SELECT trans_id
                     FROM inventory_report ir
                    WHERE ac.trans_id = ir.ar_trans_id)
 WHERE trans_id IN (SELECT ar_trans_id FROM inventory_report);
UPDATE transactions trans
   SET table_name = 'gl'
 WHERE EXISTS (SELECT 1 FROM inventory_report ir
                WHERE trans.id = ir.ap_trans_id)
    OR EXISTS (SELECT 1 FROM inventory_report ir
                WHERE trans.id = ir.ar_trans_id);



DO $$
BEGIN
  PERFORM * FROM defaults WHERE setting_key = 'inv-entity-retain';

  IF FOUND THEN
     -- Mark the existing AR and AP transactions as "deprecated"

     UPDATE ap
        SET intnotes = 'This invoice was part of an inventory adjustment.
As of LedgerSMB 1.6.0, inventory adjustments no longer require invoices,
but are generated as General Ledger transactions instead. The journal lines
belonging to this invoice have been moved to a gl transaction with
reference invadj-' || (select id from inventory_report ir
                        where ap.id = ir.ap_trans_id)
                   || E'\n\n' || coalesce(intnotes, '')
      WHERE EXISTS (SELECT 1 FROM inventory_report ir
                     WHERE ap.id = ir.ap_trans_id);
     UPDATE ar
        SET intnotes = 'This invoice was part of an inventory adjustment.
As of LedgerSMB 1.6.0, inventory adjustments no longer require invoices,
but are generated as General Ledger transactions instead. The journal lines
belonging to this invoice have been moved to a gl transaction with
reference invadj-' || (select id from inventory_report ir
                        where ar.id = ir.ar_trans_id)
                   || E'\n\n' || coalesce(intnotes, '')
      WHERE EXISTS (SELECT 1 FROM inventory_report ir
                     WHERE ar.id = ir.ar_trans_id);

  ELSE

     PERFORM 1 FROM inventory_report
       WHERE EXISTS (select 1 from defaults
                      where setting_key = 'inv-entity-remove');

     IF FOUND THEN
          DELETE FROM ap WHERE EXISTS (SELECT 1 FROM inventory_report ir
                                        WHERE trans.id = ir.ap_trans_id);
          DELETE FROM ar WHERE EXISTS (SELECT 1 FROM inventory_report ir
                                        WHERE trans.id = ir.ar_trans_id);
     END IF;
  END IF;
END;
$$ language 'plpgsql';

-- After moving existing data,
-- remove the deprecated columns

 ALTER TABLE inventory_report
   DROP COLUMN ar_trans_id,
   DROP COLUMN ap_trans_id;

DELETE FROM defaults WHERE setting_key = 'inv-entity-retain';
DELETE FROM defaults WHERE setting_key = 'inv-entity-remove';
