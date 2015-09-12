BEGIN;

CREATE OR REPLACE FUNCTION form_check(in_session_id int, in_form_id int)
RETURNS BOOL AS
$$
SELECT count(*) = 1
  FROM open_forms f
  JOIN "session" s USING (session_id)
  JOIN users u ON (s.users_id = u.id)
 WHERE f.session_id = $1 and f.id = $2 and u.username = SESSION_USER;
$$ language sql SECURITY DEFINER;

COMMENT ON FUNCTION form_check(in_session_id int, in_form_id int) IS
$$ This checks to see if an open form (record in open_forms) exists with
the form_id and session_id provided.  Returns true if exists, false if not.$$;

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
$$ language plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION form_close(in_session_id int, in_form_id int) IS
$$ Closes out the form by deleting it from the open_forms table.

Returns true if found, false if not.
$$;

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

COMMENT ON FUNCTION check_expiration() IS
$$ This checks whether the user needs to be notified of a pending expiration of
his/her password.  Returns true if needed, false if not.

The function also records the next time when the notification will again need to
be displayed. $$;

CREATE OR REPLACE FUNCTION form_open(in_session_id int)
RETURNS INT AS
$$
DECLARE usertest bool;
BEGIN
        SELECT count(*) = 1 INTO usertest FROM session
         WHERE session_id = in_session_id
               AND users_id IN (select id from users
                                WHERE username = SESSION_USER);

        IF usertest is not true THEN
            RAISE EXCEPTION 'Invalid session';
        END IF;

	INSERT INTO open_forms (session_id) VALUES (in_session_id);
	RETURN currval('open_forms_id_seq');
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

COMMENT ON FUNCTION form_open(in_session_id int) IS
$$ This opens a form, and returns the id of the form opened.$$;

CREATE OR REPLACE FUNCTION session_check(in_session_id int, in_token text)
RETURNS session AS
$$
DECLARE out_row session%ROWTYPE;
BEGIN
	DELETE FROM session
	 WHERE last_used < now() - coalesce((SELECT value FROM defaults
                                    WHERE setting_key = 'session_timeout')::interval,
	                            '90 minutes'::interval);
        UPDATE session
           SET last_used = now()
         WHERE session_id = in_session_id
               AND token = in_token
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

               PERFORM *
                  FROM defaults
                 WHERE setting_key = 'never_logout' and value = '0';

                IF NOT FOUND THEN
                    RAISE NOTICE 'auto logout';
                    RETURN NULL;
                ELSE
                    INSERT INTO session (users_id, token)
                    SELECT id, md5(random()::text)
                      FROM users
                     WHERE username = SESSION_USER;

                    SELECT * INTO out_row FROM SESSION
                     WHERE users_id = (select id from users
                                             where username = SESSION_USER);
                    RETURN out_row;
               END IF;
	END IF;
	RETURN out_row;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION session_check(int, text) IS
$$ Returns a session row.  If no session exists, it returns null$$;

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

COMMENT ON FUNCTION unlock_all() IS
$$Releases all pessimistic locks against transactions.  These locks are again
only advisory, and the application may choose to handle them or not.

Returns true if any transactions were unlocked, false otherwise.$$;

CREATE OR REPLACE FUNCTION unlock(in_id int) RETURNS BOOL AS $$
BEGIN
    UPDATE transactions SET locked_by = NULL WHERE id = in_id
           AND locked_by IN (SELECT session_id FROM session WHERE users_id =
		(SELECT id FROM users WHERE username = SESSION_USER));
    RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

COMMENT ON FUNCTION unlock(in_id int) IS
$$Releases a pessimistic locks against a transaction, if that transaciton, as
identified by in_id exists, and if  it is locked by the current session.
These locks are again only advisory, and the application may choose to handle
them or not.

Returns true if the transaction was unlocked by this routine, false
otherwise.$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
