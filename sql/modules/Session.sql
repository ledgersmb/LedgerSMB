CREATE OR REPLACE FUNCTION form_check(in_session_id int, in_form_id int)
RETURNS BOOL AS
$$
SELECT count(*) = 1 FROM open_forms
 WHERE session_id = $1 and id = $2;
$$ language sql;

CREATE OR REPLACE FUNCTION form_close(in_session_id int, in_form_id int)
RETURNS BOOL AS
$$
DECLARE form_test bool;
BEGIN
	form_test := form_check(in_session_id, in_form_id);

	IF form_test is true THEN 
		DELETE FROM open_forms 
		WHERE session_id = in_session_id AND id = in_form_id;

		RETURN TRUE;

	ELSE RETURN FALSE;
	END IF;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION check_expiration() RETURNS bool AS
$$
DECLARE test_result BOOL;
	expires_in interval;
	notify_again interval;
BEGIN
	expires_in := user__check_my_expiration();

	SELECT expires_in < notify_password INTO test_result
	FROM users WHERE username = SESSION_USER;

	IF test_result THEN 
		IF expires_in < '1 week' THEN
			notify_again := '1 hour';
		ELSE
			notify_again := '1 day';
		END IF;

		UPDATE users 
		SET notify_password = expires_in - notify_again
		WHERE username = SESSION_USER;
	END IF;
	RETURN test_result;
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER; -- run by public, but no input from user.

CREATE OR REPLACE FUNCTION form_open(in_session_id int)
RETURNS INT AS
$$
BEGIN
	INSERT INTO open_forms (session_id) VALUES (in_session_id);
	RETURN currval('open_forms_id_seq');
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION session_check(in_session_id int, in_token text) 
RETURNS session AS
$$
DECLARE out_row session%ROWTYPE;
BEGIN
	DELETE FROM session
	 WHERE last_used < now() - coalesce((SELECT value FROM defaults
                                    WHERE setting_key = 'timeout')::interval,
	                            '90 minutes'::interval);
        UPDATE session 
           SET last_used = now()
         WHERE session_id = in_session_id
               AND token = in_token
               AND last_used > now() - (SELECT value FROM defaults
				WHERE setting_key = 'timeout')::interval
	       AND users_id = (select id from users 
			where username = SESSION_USER);
	IF FOUND THEN
		SELECT * INTO out_row FROM session WHERE session_id = in_session_id;
	ELSE
		DELETE FROM SESSION 
		WHERE users_id IN (select id from users
                        where username = SESSION_USER); 
		-- the above query also releases all discretionary locks by the
                -- session

		IF NOT FOUND THEN
			PERFORM id FROM users WHERE username = SESSION_USER;
			IF NOT FOUND THEN
				RAISE EXCEPTION 'User Not Known';
			END IF;
			
		END IF;
		INSERT INTO session(users_id, token, last_used, transaction_id)
		SELECT id, md5(random()::text), now(), 0 
		  FROM users WHERE username = SESSION_USER;
		-- TODO-- remove transaction_id field from session table

		SELECT * INTO out_row FROM session 
		 WHERE session_id = currval('session_session_id_seq');
	END IF;
	RETURN out_row;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION session_check(int, text) IS 
$$ Return code is 0 for failure, 1 for success. $$;

CREATE OR REPLACE FUNCTION unlock_all() RETURNS BOOL AS
$$
BEGIN
    UPDATE transactions SET locked_by = NULL 
    where locked_by IN 
          (select session_id from session WHERE users_id = 
                  (SELECT id FROM users WHERE username = SESSION_USER));

    RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION unlock(in_id int) RETURNS BOOL AS $$
BEGIN
    UPDATE transactions SET locked_by = NULL WHERE id = in_id 
           AND locked_by IN (SELECT session_id FROM session WHERE users_id =
		(SELECT id FROM users WHERE username = SESSION_USER));
    RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;
