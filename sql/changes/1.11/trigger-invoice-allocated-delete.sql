
CREATE OR REPLACE FUNCTION trigger_invoice_prevent_allocation_delete() RETURNS TRIGGER
AS $$
BEGIN
  RETURN OLD;
END;
$$ language plpgsql;

CREATE TRIGGER trigger_invoice_prevent_allocation_delete
  BEFORE DELETE ON invoice
  FOR EACH ROW
    WHEN (OLD.allocated <> 0)
    EXECUTE FUNCTION trigger_invoice_prevent_allocation_delete();
