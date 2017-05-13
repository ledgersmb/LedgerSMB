
DO $$
BEGIN
   PERFORM * FROM inventory_report;
   IF FOUND THEN
      RAISE EXCEPTION 'Can''t upgrade non-empty ''inventory_report'' table; please contact the development team at https://vector.im/beta/#/room/#ledgersmb:matrix.org or ledger-smb-devel@lists.sf.net';
   END IF;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE inventory_report
    DROP COLUMN ar_trans_id,
    DROP COLUMN ap_trans_id,
    ADD COLUMN trans_id int REFERENCES gl(id);

COMMENT ON COLUMN inventory_report.trans_id IS
$$Indicates the associated transaction representing the financial
facts associated with the inventory adjustment. (NULL until the report
is approved)$$;
