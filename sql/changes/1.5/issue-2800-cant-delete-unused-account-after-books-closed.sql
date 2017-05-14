CREATE OR REPLACE FUNCTION account__delete(in_id int)
RETURNS BOOL AS
$$
BEGIN
    /* We only allow deletion of unused accounts.
       Any account_checkpoint rows remaining will cause the final
       DELETE FROM account to fail and this operation to be rolled back.
     */
    DELETE FROM account_checkpoint
    WHERE account_id = in_id
    AND amount = 0
    AND debits = 0
    AND credits = 0;

    DELETE FROM tax WHERE chart_id = in_id;
    DELETE FROM account_link WHERE account_id = in_id;
    DELETE FROM account WHERE id = in_id;
    RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

