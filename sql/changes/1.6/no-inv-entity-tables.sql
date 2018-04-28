

ALTER TABLE inventory_report
    ADD COLUMN trans_id int REFERENCES gl(id)
    USING nextval('id');

COMMENT ON COLUMN inventory_report.trans_id IS
$$Indicates the associated transaction representing the financial
facts associated with the inventory adjustment. (NULL until the report
is approved)$$;



-- Migrate existing data

INSERT INTO gl (id, description, transdate, reference, approved,
                trans_type_code)
   SELECT trans_id, 'Transaction due to approval of inventory adjustment',
          transdate, 'invadj-' || id, true, 'ia'
     FROM inventory_report;

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

  PERFORM * FROM defaults WHERE setting_key = 'inv-entity-retain';

  IF FOUND THEN
  BEGIN

     -- Mark the existing AR and AP transactions as "deprecated"

     UPDATE ap
        SET intnotes = 'This invoice was part of an inventory adjustment.
As of LedgerSMB 1.6.0, inventory adjustments no longer require invoices,
but are generated as General Ledger transactions instead. The journal lines
belonging to this invoice have been moved to a gl transaction with
reference invadj-' || () || E'\n\n' || coalesce(intnotes, '')
      WHERE EXISTS (SELECT 1 FROM inventory_report ir
                     WHERE trans.id = ir.ap_trans_id);
     UPDATE ar
        SET intnotes = 'This invoice was part of an inventory adjustment.
As of LedgerSMB 1.6.0, inventory adjustments no longer require invoices,
but are generated as General Ledger transactions instead. The journal lines
belonging to this invoice have been moved to a gl transaction with
reference invadj-' || () || E'\n\n' || coalesce(intnotes, '')
      WHERE EXISTS (SELECT 1 FROM inventory_report ir
                     WHERE trans.id = ir.ar_trans_id);

  END
  ELSE
  BEGIN

     PERFORM 1 FROM inventory_report
       WHERE EXISTS (select 1 from defaults
                      where setting_key = 'inv-entity-remove');

     IF FOUND THEN
     BEGIN
          DELETE FROM ap WHERE EXISTS (SELECT 1 FROM inventory_report ir
                                        WHERE trans.id = ir.ap_trans_id);
          DELETE FROM ar WHERE EXISTS (SELECT 1 FROM inventory_report ir
                                        WHERE trans.id = ir.ar_trans_id);
     END;
  END;

$$ language 'plpgsql';

-- After moving existing data,
-- remove the deprecated columns


 ALTER TABLE inventory_report
   DROP COLUMN ar_trans_id,
   DROP COLUMN ap_trans_id;

DELETE FROM defaults WHERE setting_key = 'inv-entity-retain';
DELETE FROM defaults WHERE setting_key = 'inv-entity-retain';
