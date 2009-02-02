CREATE TABLE cr_report (
    id bigserial primary key not null,
    chart_id int not null references chart(id),
    our_total numeric default 0,
    approved boolean not null default 'f',
    end_date date not null default now()
);

CREATE TABLE cr_report_line (
    id bigserial primary key not null,
    report_id int NOT NULL,
    scn text not null, -- SCN is the check #
    their_balance numeric,
    our_balance numeric,
    errorcode INT,
    "user" int references entity(id) not null, -- why ois this not an entity reference?
    corrections INT NOT NULL DEFAULT 0,
    clear_time TIMESTAMP NOT NULL,
    insert_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    ledger_id int REFERENCES acc_trans(entry_id),
    voucher_id int REFERENCES voucher(id),
    overlook boolean not null default 'f',
    check (ledger_id is not null or voucher_id is not null)
);

CREATE TABLE cr_coa_to_account (
    chart_id int not null references chart(id),
    account text not null
);


CREATE TABLE cr_report_corrections (
    id serial primary key not null,
    correction_id int not null default 1,
    "entry" int references cr_report_line(id) not null,
    "user" int references entity(id) not null, -- why is this not an entity reference?
    reason text not null,
    insert_time timestamptz not null default now()
);

-- to correct OUR wrong amount.
CREATE OR REPLACE FUNCTION reconciliation__correct_ledger (in_report_id INT, in_id int, in_new_amount NUMERIC, reason TEXT) returns INT AS $$

    DECLARE
        new_code INT;
        current_row RECORD;
        l_row RECORD;
        in_user TEXT;
        full_reason TEXT;
    BEGIN
	in_user := current_user;
        
        select * into current_row from cr_report_line l where l.id = in_report_id and l.id = in_id;
        select * into l_row from acc_trans where entry_id = current_row.lid;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No such id % in this report.', in_scn;
        END IF;
        
        IF user <> current_row.user THEN
        
            IF current_row.our_balance <> in_new_amount AND in_new_amount = current_row.their_balance THEN
                update cr_report_line 
                set corrections = corrections + 1, 
                new_balance = in_new_amount,
                errorcode = 0
                where id = in_report_id and scn = in_scn;
                return 0;
                
                -- After that, it is required to update the general ledger.
                full_reason := "User % is filing a reconciliation correction on the general ledger, changing amount % to amount %. 
                Their reason given is: %", in_user, current_row.our_balance, in_new_amount, reason;
                perform reconciliation__update_ledger(current_row.lid, in_new_amount, full_reason);
            ELSIF current_row.our_balance = in_new_amount THEN
                -- This should be something, does it equal the original 
                -- balance? If so, there's no change.
                return current_row.errorcode;
            END IF;
        END IF;
        
        return current_row.errorcode;            
                    
    END;
$$ language 'plpgsql';

-- to correct an incorrect bank statement value.
CREATE OR REPLACE FUNCTION reconciliation__correct_bank_statement (in_report_id INT, in_id int, in_new_amount NUMERIC) returns INT AS $$

    DECLARE
        new_code INT;
        current_row RECORD;
        in_user TEXT;
    BEGIN
	in_user := current_user;

        select * into current_row from cr_report_line r 
	where r.id = in_id and r.report_id = in_report_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No such SCN % in this report.', in_scn;
        END IF;
        
        IF user <> current_row.user THEN
        
            IF current_row.their_balance <> in_new_amount AND in_new_amount = current_row.our_balance THEN
                update cr_report_line
                set corrections = corrections + 1, 
                new_balance = in_new_amount,
                errorcode = 0
                where id = in_report_id and scn = in_scn;
                return 0;
            
            ELSIF current_row.their_balance = in_new_amount THEN
                -- This should be something, does it equal the original 
                -- balance? If so, there's no change.
                return current_row.errorcode;         
            END IF;
        END IF;
        
        return current_row.errorcode;            
                    
    END;
$$ language 'plpgsql';


CREATE OR REPLACE function reconciliation__correct_passthrough ( in_report_id int, in_id int ) returns INT AS $$

    DECLARE
        in_user TEXT;
        pending_entry cr_report_line;
    BEGIN
        in_user := current_user; 
        
        select * into pending_entry 
	from cr_report_line l where report_id = in_report_id and id = in_id;
        
        IF NOT FOUND THEN
            -- Raise an exception.
            RAISE EXCEPTION 'Cannot find entry.';
        ELSIF pending_entry.errorcode <> 4 THEN 
            -- Only error codes of 4 may be "passed through" safely.
            RAISE EXCEPTION 'Selected entry not permitted to be passed through.';
            
        ELSE
            -- Then we mark it passthroughable, and "approve" will overlook it.
            update cr_report_line set overlook = 't', errorcode = 0 
            where report_id = in_report_id and id = in_id;

            return 0;
        END IF;
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__correct_bank_charge (in_report_id int, in_id int) returns INT AS $$

    DECLARE
        in_user TEXT;
        pending_entry cr_report_line;
    BEGIN
    
        IF NOT FOUND THEN
             -- Raise an exception.
             RAISE EXCEPTION 'Cannot find entry with ID % in report %.', in_id, in_report_id;
         ELSIF pending_entry.errorcode <> 2 THEN 
             -- Only error codes of 2 may be "passed through" safely.
             RAISE EXCEPTION 'Attempt to retroactively add a non-bank-charge entry to the ledger.';
         
         ELSE
             -- Then we mark it passthroughable, and "approve" will overlook it.
             
             PERFORM create_entry (pending_entry.their_balance, 'payable', pending_entry.clear_time, 'Bank charge');
             
             update cr_report_line set errorcode = 0 
             where report_id = in_report_id and id = in_id;

             return 0;
         END IF;
    END;

$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__correct_unaccounted_charge (in_report_id int, in_id int, reason TEXT) RETURNS INT AS $$

    DECLARE
        in_user TEXT;
        pending_entry cr_report_line;
        note TEXT;
    BEGIN
	in_user := session_user;
    
        IF NOT FOUND THEN
             -- Raise an exception.
             RAISE EXCEPTION 'Cannot find entry with ID % in report %.', in_id, in_report_id;
         ELSIF pending_entry.errorcode <> 3 THEN 
             -- Only error codes of 3 may be "passed through" safely.
             RAISE EXCEPTION 'Not an unaccounted charge; cannot be retroactively added to the ledger.';
         
         ELSE
             -- Then we mark it passthroughable, and "approve" will overlook it.
             
             note := 'Retroactive addition of an unaccounted entry, of value %. 
             Being added by user % with the following explanation: %', pending_entry.their_balance, in_user, in_reason;
             
             select create_entry (pending_entry.their_balance, 'payable', pending_entry.clear_time,note);
             
             update cr_report_line set errorcode = 0 
             where report_id = in_report_id and id = in_id;

             return in_id;
         END IF;
    END;
$$ language 'plpgsql';

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
    BEGIN
        in_user := current_user;
        select * into current_row from cr_report_line 
        where report_id = in_report_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Fatal Error: Pending report % not found', in_report_id;
        END IF;
        
        IF current_row.user = in_user THEN
            RAISE EXCEPTION 'Fatal Error: User % cannot self-approve report!', in_user;
        END IF;
        
        SELECT INTO total_errors count(*) from cr_report_line 
        where report_id = in_report_id and errorcode <> 0;
        
        IF total_errors <> 0 THEN
            RAISE EXCEPTION 'Fatal Error: Cannot approve while % uncorrected errors remain.', total_errors;
        END IF;
        
        -- so far, so good. Different user, and no errors remain. Therefore, 
        -- we can move it to completed reports.
        --
        -- User may not be necessary - I would think it better to use the 
        -- in_user, to note who approved the report, than the user who
        -- filed it. This may require clunkier syntax..
        
        -- 
        
        update cr_report set approved = 't', clear_time = now() 
	where id = in_report_id;
        
        return 1;        
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__new_report_id (in_chart_id int, 

in_total numeric, in_end_date date) returns INT as $$

    INSERT INTO cr_report(chart_id, our_total, end_date) values ($1, $2, $3);
    SELECT currval('cr_report_id_seq')::int;

$$ language 'sql';

create or replace function reconciliation__add_entry(
    in_report_id INT, 
    in_scn TEXT, 
    in_chart_id int, 
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
    BEGIN
	in_account := in_chart_id;
    
        SELECT * INTO la FROM acc_trans gl 
        JOIN chart c on gl.chart_id = c.id
        JOIN ap ON gl.trans_id = ap.id
        JOIN coa_to_account cta on cta.chart_id = gl.chart_id
        WHERE gl.source ~ in_scn -- does it look like it?
        and cta.account = in_account 
        and gl.amount = in_amount
        AND gl.transdate = in_date;
        
        lid := NULL;
        IF NOT FOUND THEN
            -- they have it, we don't. This is Bad, and implies either a bank
            -- charge or an unaccounted cheque.
            
            if in_scn <> '' and in_scn IS NOT NULL THEN
            
                -- It's a bank charge. Approval action will probably be 
                -- adding it as an entry to the general ledger.
                t_errorcode := 2; 
                our_value := 0;
            ELSE
                -- Okay, now this is bad.
                -- They have a cheque/sourced charge that we don't. 
                -- REsolution action is going to be
                t_errorcode := 3;
                our_value := 0;
            END IF;
            
        ELSif la.amount <> in_amount THEN
        
            t_errorcode := 1;
            our_value := la.amount;
            lid := la.entry_id;
            
        ELSE
            -- it reconciles. No problem.
            
            t_errorcode := 0;
            our_value := la.amount;
            lid := la.entry_id;
            
        END IF;
        
        INSERT INTO cr_report_line (
                report_id,
                scn,
                their_balance,
                our_balance,
                errorcode, 
                "user",
                clear_time,
                ledger_id
            ) 
            VALUES (
                in_report_id,
                in_scn,
                in_amount,
                la.amount,
                t_errorcode,
                (select id from users where username = in_user),
                in_date,
                lid
            );
            
        -- success, basically. This could very likely be collapsed to
        -- do the compare check here, instead of in the Perl app. Save us a DB
        -- call.
        return 1; 
        
    END;    
$$ language 'plpgsql';

-- this needs help.....
create or replace function reconciliation__pending_transactions (in_end_date DATE, in_chart_id int, in_report_id int) RETURNS int as $$
    
    DECLARE
        gl_row RECORD;
    BEGIN
		INSERT INTO cr_report_line (report_id, scn, their_balance, 
			our_balance, "user", voucher_id, ledger_id)
		SELECT in_report_id, ac.source, 0, sum(amount) * -1 AS amount,
				(select entity_id from users 
				where username = CURRENT_USER),
			ac.voucher_id, min(ac.entry_id)
		FROM acc_trans ac
		JOIN transactions t on (ac.trans_id = t.id)
		JOIN (select id, entity_credit_account, 'ar' as table FROM ar
			UNION
		      select id, entity_credit_account, 'ap' as table FROM ap
			UNION
		      select id, NULL, 'gl' as table FROM gl) gl
			ON (gl.table = t.table_name AND gl.id = t.id)
		LEFT JOIN cr_report_line rl 
			ON (rl.ledger_id = ac.entry_id)
		WHERE ac.cleared IS FALSE
			AND ac.chart_id = in_chart_id
			AND ac.transdate <= in_end_date
		GROUP BY gl.entity_credit_account, ac.source, ac.transdate,
			ac.memo, ac.voucher_id
		HAVING count(rl.ledger_id) = 0;
    RETURN in_report_id;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reconciliation__report (in_report_id INT) RETURNS setof cr_report as $$

    DECLARE
        row cr_report;
    BEGIN    
        FOR row IN select * from cr_report where id = in_report_id LOOP
        
            RETURN NEXT row;
        
        END LOOP;    
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

CREATE OR REPLACE FUNCTION reconciliation__corrections (in_report_id INT, in_id INT) returns setof cr_report_corrections AS $$

    DECLARE
        corr cr_report_corrections;
    BEGIN
    
        SELECT * INTO corr FROM cr_report_corrections 
        WHERE report_id = in_report_id AND id = in_id LIMIT 1;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No corrections for selected entry.';
        ELSE

            FOR corr IN 
		select * from cr_report_corrections 
		WHERE report_id = in_report_id AND id = in_id 
            LOOP
                RETURN NEXT corr;
            END LOOP;
        END IF;
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__single_entry (in_id INT) returns cr_report_line AS $$

    DECLARE
        row cr_report_line;
    BEGIN
    
        SELECT * INTO row FROM cr_report_line WHERE id = in_id LIMIT 1; 
        -- if there's more than one, that's a Bad Thing
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Could not find selected report entry';
        END IF;

    RETURN row;
    END;

$$ language 'plpgsql';

-- TODO: Rewrite this function
CREATE OR REPLACE FUNCTION reconciliation__search (
    in_date_begin DATE, 
    in_date_end DATE, 
    in_account TEXT,
    in_status TEXT
) RETURNS setof cr_report AS $$

    DECLARE
        row reports;
        statement text;
        where_stmt text;
        v_status BOOLEAN;
        v_accum NUMERIC;
    BEGIN
        
        if in_status = "pending" then
            v_status = 'f'::bool;
        ELSIF in_status = "approved" THEN
        
            v_status = 't'::bool;
        END IF;
        
        IF in_date_begin IS NOT NULL
            or in_date_end IS NOT NULL
            or in_account IS NOT NULL
            or v_status IS NOT NULL
        THEN
            statement = 'select pr.* from reports pr ';
            statement = statement || $s$join acc_trans at on pr.ledger_id = at.entry_id $s$;
            
            IF in_account IS NOT NULL THEN
                
                statement = statement || $s$join chart c on at.chart_id = c.id $s$;
                where_stmt = $s$c.accno =~ $s$ || quote_literal(in_account) || $s$ AND $s$;
            END IF;
            
            IF in_date_begin IS NOT NULL THEN
                where_stmt = where_stmt || $s$insert_time >= $s$ || quote_literal(in_date_begin) || $s$ AND $s$;
            END IF;
            
            IF in_date_end IS NOT NULL THEN
                where_stmt = where_stmt || $s$insert_time <= $s$ || quote_literal(in_date_end) || $s$ AND $s$;
            END IF;
            
            IF in_status IS NOT NULL THEN
                
                if v_status == 't'::bool THEN
                    where_stmt = where_stmt || $s$ approved = 't'::bool AND $s$;
                ELSIF v_status == 'f'::bool THEN
                    where_stmt = where_stmt || $s$ approved = 'f'::bool AND $s$;
                END IF;
            
            END IF;
            
            FOR row in EXECUTE statement LOOP
                RETURN NEXT row;
            END LOOP;
        ELSE
        
            FOR row IN SELECT * FROM reports LOOP
                RETURN NEXT row;
            END LOOP;
        
        END IF;
    END;
$$ language 'plpgsql';

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
    WHERE cta.chart_id = coa.id;
$$ language sql;

CREATE OR REPLACE FUNCTION reconciliation__get_current_balance
(in_account_id int, in_date date) returns numeric as
$$
DECLARE outval NUMERIC;
BEGIN
	SELECT CASE WHEN (select category FROM chart WHERE id = in_account_id)
			IN ('A', 'E') THEN sum(a.amount) * -1
		ELSE sum(a.amount) END
	INTO out_val
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
