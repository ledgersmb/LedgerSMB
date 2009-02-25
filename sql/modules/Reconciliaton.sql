CREATE TABLE cr_report (
    id bigserial primary key not null,
    chart_id int not null references chart(id),
    their_total numeric not null,
    approved boolean not null default 'f',
    submitted boolean not null default 'f',
    end_date date not null default now()
);

create table cr_approval (
    report_id bigint references cr_report(id) primary key,
    approved_by int references entity(id) not null,
    approved_at timestamptz default now() not null
);

CREATE TABLE cr_report_line (
    id bigserial primary key not null,
    report_id int NOT NULL references cr_report(id),
    scn text, -- SCN is the check #
    their_balance numeric,
    our_balance numeric,
    errorcode INT,
    "user" int references entity(id) not null, -- why ois this not an entity reference?
    clear_time date,
    insert_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    post_date date,
    ledger_id int REFERENCES acc_trans(entry_id),
    voucher_id int REFERENCES voucher(id),
    overlook boolean not null default 'f',
    cleared boolean not null default 'f',
    check (ledger_id is not null or voucher_id is not null)
);

CREATE TABLE cr_coa_to_account (
    chart_id int not null references chart(id),
    account text not null
);

CREATE OR REPLACE FUNCTION reconciliation__submit_set(
	in_report_id int, in_line_ids int[]) RETURNS bool AS
$$
BEGIN
	UPDATE cr_report set submitted = true where id = in_report_id;

	UPDATE cr_report_line SET cleared = true
	WHERE report_id = in_report_id AND id = ANY(in_line_ids);

	RETURN FOUND;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION reconciliation__get_cleared_balance(in_chart_id int)
RETURNS numeric AS
$$
	select CASE WHEN c.category = 'A' THEN sum(ac.amount) * -1 ELSE
		sum(ac.amount) END
	FROM chart c
	JOIN acc_trans ac ON (ac.chart_id = c.id)
	WHERE c.id = $1 AND ac.cleared is true
		GROUP BY c.id, c.category;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION reconciliation__report_approve (in_report_id INT) returns INT as $$
    
    -- Does some basic checks before allowing the approval to go through; 
    -- moves the approval to "cr_report_line", I guess, or some other "final" table.
    --
    -- Pending may just be a single flag in the database to mark that it is
    -- not finalized. Will need to discuss with Chris.
    
    DECLARE
        current_row RECORD;
        completed cr_report_line;
        total_errors INT;
        in_user TEXT;
	ac_entries int[];
    BEGIN
        in_user := current_user;
        
        -- so far, so good. Different user, and no errors remain. Therefore, 
        -- we can move it to completed reports.
        --
        -- User may not be necessary - I would think it better to use the 
        -- in_user, to note who approved the report, than the user who
        -- filed it. This may require clunkier syntax..
        
        -- 
	ac_entries := '{}';
        update cr_report set approved = 't'
	where id = in_report_id;

	FOR current_row IN 
		SELECT compound_array(entries) AS entries FROM (
			select as_array(ac.entry_id) as entries
		FROM acc_trans ac
		JOIN transactions t on (ac.trans_id = t.id)
		JOIN (select id, entity_credit_account::text as ref, 'ar' as table FROM ar
			UNION
		      select id, entity_credit_account::text, 'ap' as table FROM ap
			UNION
		      select id, reference, 'gl' as table FROM gl) gl
			ON (gl.table = t.table_name AND gl.id = t.id)
		LEFT JOIN cr_report_line rl ON (rl.report_id = in_report_id
			AND ((rl.ledger_id = ac.entry_id 
				AND ac.voucher_id IS NULL) 
				OR (rl.voucher_id = ac.voucher_id)))
		WHERE ac.cleared IS FALSE
			AND ac.chart_id = (select chart_id from cr_report where id = in_report_id)
		GROUP BY gl.ref, ac.source, ac.transdate,
			ac.memo, ac.voucher_id, gl.table
		HAVING count(rl.report_id) > 0) a
	LOOP
		ac_entries := ac_entries || current_row.entries;
	END LOOP;

	UPDATE acc_trans SET cleared = TRUE 
	where entry_id = any(ac_entries);
        
        return 1;        
    END;

$$ language 'plpgsql' security definer;

CREATE OR REPLACE FUNCTION reconciliation__new_report_id (in_chart_id int, 

in_total numeric, in_end_date date) returns INT as $$

    INSERT INTO cr_report(chart_id, their_total, end_date) values ($1, $2, $3);
    SELECT currval('cr_report_id_seq')::int;

$$ language 'sql';

create or replace function reconciliation__add_entry(
    in_report_id INT, 
    in_scn TEXT, 
    in_user TEXT, 
    in_date TIMESTAMP,
    in_amount numeric
) RETURNS INT AS $$
    
    DECLARE
	in_account int;
        la RECORD;
        t_errorcode INT;
        our_value NUMERIC;
        lid INT;
	in_count int;
	t_scn TEXT;
    BEGIN
	IF in_scn = '' THEN 
		t_scn := NULL;
	ELSE 
		t_scn := in_scn;
	END IF;
	IF t_scn IS NOT NULL THEN
		SELECT count(*) INTO in_count FROM cr_report_line
		WHERE in_scn = scn AND report_id = in_report_id 
			AND their_balance = 0;

		IF in_count = 0 THEN
			INSERT INTO cr_report_line
			(report_id, scn, their_balance, our_balance, clear_time)
			VALUES 
			(in_report_id, t_scn, in_amount, 0, in_date);
		ELSIF in_count = 1 THEN
			UPDATE cr_report_line
			SET their_balance = in_amount, clear_time = in_date
			WHERE n_scn = scn AND report_id = in_report_id
				AND their_balance = 0;
		ELSE 
			SELECT count(*) INTO in_count FROM cr_report_line
			WHERE in_scn = scn AND report_id = in_report_id
				AND our_value = in_amount and their_balance = 0;

			IF in_count = 0 THEN -- no match among many of values
				SELECT id INTO lid FROM cr_report_line
                        	WHERE in_scn = scn AND report_id = in_report_id
				ORDER BY our_balance ASC limit 1;

				UPDATE cr_report_line
                                SET their_balance = in_amount
                                WHERE id = lid;

			ELSIF in_count = 1 THEN -- EXECT MATCH
				UPDATE cr_report_line
				SET their_balance = in_amount, 
					clear_time = in_date
				WHERE in_scn = scn AND report_id = in_report_id
                                	AND our_value = in_amount 
					AND their_balance = 0;
			ELSE -- More than one match
				SELECT id INTO lid FROM cr_report_line
                        	WHERE in_scn = scn AND report_id = in_report_id
                                	AND our_value = in_amount
				ORDER BY id ASC limit 1;

				UPDATE cr_report_line
                                SET their_balance = in_amount,
					clear_time = in_date
                                WHERE id = lid;
				
			END IF;
		END IF;
	ELSE -- scn IS NULL, check on amount instead
		SELECT count(*) INTO in_count FROM cr_report_line
		WHERE report_id = in_report_id AND amount = in_amount
			AND their_balance = 0;

		IF in_count = 0 THEN -- no match
			INSERT INTO cr_report_line
			(report_id, scn, their_balance, our_balance, clear_time)
			VALUES 
			(in_report_id, t_scn, in_amount, 0, in_date);
		ELSIF in_count = 1 THEN -- perfect match
			UPDATE cr_report_line SET their_balance = in_amount,
					clear_time = in_date
			WHERE report_id = in_report_id AND amount = in_amount
                        	AND their_balance = 0;
		ELSE -- more than one match
			SELECT min(id) INTO lid FROM cr_report_line
			WHERE report_id = in_report_id AND amount = in_amount
                        	AND their_balance = 0;

			UPDATE cr_report_line SET their_balance = in_amount,
					clear_time = in_date
			WHERE id = lid;
			
		END IF;
	END IF;
        return 1; 
        
    END;    
$$ language 'plpgsql';

comment on function reconciliation__add_entry(
    in_report_id INT,
    in_scn TEXT,
    in_user TEXT,
    in_date TIMESTAMP,
    in_amount numeric
)  IS
$$ This function is very sensitive to ordering of inputs.  NULL or empty in_scn values MUST be submitted after meaningful scns.  It is also highly recommended 
that within each category, one submits in order of amount.  We should therefore
wrap it in another function which can operate on a set.  Implementation TODO.$$;

create or replace function reconciliation__pending_transactions (in_end_date DATE, in_chart_id int, in_report_id int) RETURNS int as $$
    
    DECLARE
        gl_row RECORD;
    BEGIN
		INSERT INTO cr_report_line (report_id, scn, their_balance, 
			our_balance, "user", voucher_id, ledger_id, post_date)
		SELECT in_report_id, case when gl.table = 'gl' then gl.ref else ac.source end, 0, sum(amount) * -1 AS amount,
				(select entity_id from users 
				where username = CURRENT_USER),
			ac.voucher_id, min(ac.entry_id), ac.transdate
		FROM acc_trans ac
		JOIN transactions t on (ac.trans_id = t.id)
		JOIN (select id, entity_credit_account::text as ref, 'ar' as table FROM ar
			UNION
		      select id, entity_credit_account::text, 'ap' as table FROM ap
			UNION
		      select id, reference, 'gl' as table FROM gl) gl
			ON (gl.table = t.table_name AND gl.id = t.id)
		LEFT JOIN cr_report_line rl ON (rl.report_id = in_report_id
			AND ((rl.ledger_id = ac.trans_id 
				AND ac.voucher_id IS NULL) 
				OR (rl.voucher_id = ac.voucher_id)))
		WHERE ac.cleared IS FALSE
			AND ac.chart_id = in_chart_id
			AND ac.transdate <= in_end_date
		GROUP BY gl.ref, ac.source, ac.transdate,
			ac.memo, ac.voucher_id, gl.table
		HAVING count(rl.id) = 0;
    RETURN in_report_id;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reconciliation__report_details (in_report_id INT) RETURNS setof cr_report_line as $$

    DECLARE
        row cr_report_line;
    BEGIN    
        FOR row IN 
		select * from cr_report_line where report_id = in_report_id 
		order by post_date
	LOOP
        
            RETURN NEXT row;
        
        END LOOP;    
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__report_summary (in_report_id INT) RETURNS cr_report as $$

    DECLARE
        row cr_report;
    BEGIN    
        select * into row from cr_report where id = in_report_id;
        
        RETURN row;
        
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__get_total (in_report_id INT) returns setof cr_report AS $$

    DECLARE
        row cr_report;
    BEGIN
    
        SELECT * INTO row FROM cr_report 
        where id = in_report_id 
        AND scn = -1;
        
        IF NOT FOUND THEN -- I think this is a fairly major error condition
            RAISE EXCEPTION 'Bad report id.';
        ELSE
            return next row;
        END IF;
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__search
(in_date_from date, in_date_to date, 
	in_balance_from numeric, in_balance_to numeric, 
	in_chart_id int, in_submitted bool, in_approved bool) 
returns setof cr_report AS
$$
DECLARE report cr_report;
BEGIN
	FOR report IN
		SELECT * FROM cr_report
		WHERE 
			(in_date_from IS NULL OR in_date_from <= end_date) and
			(in_date_to IS NULL OR in_date_to >= end_date) AND
			(in_balance_from IS NULL 
				or in_balance_from <= their_total ) AND
			(in_balance_to IS NULL 
				OR in_balance_to >= their_total) AND
			(in_chart_id IS NULL OR in_chart_id = chart_id) AND
			(in_submitted IS NULL or in_submitted = submitted) AND
			(in_approved IS NULL OR in_approved = approved)
		ORDER BY end_date, their_total
	LOOP
		RETURN NEXT report;
	END LOOP; 
END;
$$ language plpgsql;

create type recon_accounts as (
    name text,
    accno text,
    id int
);

create or replace function reconciliation__account_list () returns setof recon_accounts as $$
    SELECT 
        coa.accno || ' ' || coa.description as name,
        coa.accno, coa.id as id
    FROM chart coa, cr_coa_to_account cta
    WHERE cta.chart_id = coa.id
    ORDER BY coa.accno;
$$ language sql;

CREATE OR REPLACE FUNCTION reconciliation__get_current_balance
(in_account_id int, in_date date) returns numeric as
$$
DECLARE outval NUMERIC;
BEGIN
	SELECT CASE WHEN (select category FROM chart WHERE id = in_account_id)
			IN ('A', 'E') THEN sum(a.amount) * -1
		ELSE sum(a.amount) END
	FROM acc_trans a
	JOIN (
		SELECT id FROM ar
		WHERE approved is true
		UNION
		SELECT id FROM ap
		WHERE approved is true
		UNION
		SELECT id FROM gl
		WHERE approved is true
	) gl ON a.trans_id = gl.id
	WHERE a.approved IS TRUE 
		AND a.chart_id = in_account_id
		AND a.transdate <= in_date;

	RETURN outval;
END;
$$ language plpgsql;
