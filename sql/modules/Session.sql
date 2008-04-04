CREATE OR REPLACE FUNCTION form_close(in_session_id int, in_form_id int)
RETURNS BOOL AS
$$
BEGIN
	SELECT * FROM open_forms 
	WHERE session_id = in_session_id AND id = in_form_id;

	IF FOUND THEN 
		DELETE FROM open_forms 
		WHERE session_id = in_session_id AND id = in_form_id;

		RETURN TRUE;

	ELSE RETURN FALSE;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION form_open(in_session_id int)
RETURNS INT AS
$$
BEGIN
	INSERT INTO open_forms (session_id) VALUES (in_session_id);
	RETURN currval('form_id_seq');
END;
$$ LANGUAGE PLPGSQL

CREATE OR REPLACE FUNCTION session_check(in_session_id int, in_token text) 
RETURNS session AS
$$
DECLARE out_row session%ROWTYPE;
BEGIN
        UPDATE session 
           SET last_used = now()
         WHERE session_id = in_session_id
               AND token = in_token
               AND last_used > now() - (SELECT value FROM defaults
				WHERE setting_key = 'timeout')::interval
	       AND users_id = (select id from users 
			where username = SESSION_USER);
	IF FOUND THEN
		SELECT * INTO out_row WHERE session_id = in_session_id;
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
