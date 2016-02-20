
CREATE TRIGGER loop_detection AFTER INSERT OR UPDATE ON account_heading
FOR EACH ROW EXECUTE PROCEDURE account_heading__check_tree();
