CREATE TABLE reports (
    id bigserial primary key not null,
    report_id int NOT NULL,
    account text not null,
    scn text not null, -- SCN is the check #
    their_balance numeric,
    our_balance numeric,
    errorcode INT,
    user int references entity(id) not null, -- why ois this not an entity reference?
    corrections INT NOT NULL DEFAULT 0
    clear_time TIMESTAMP NOT NULL,
    insert_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    ledger_id int REFERENCES acc_trans(entry_id),
    overlook boolean not null default 'f',
    approved boolean not null default 'f'
);

CREATE TABLE coa_to_account (
    chart_id int not null references chart(id),
    account text not null CHECK (account ~ '[0-9]{7}(xxx)')
);


CREATE TABLE report_corrections (
    id serial primary key not null,
    correction_id int not null default 1,
    entry references reports(id) not null,
    user references entity(id) not null, -- why is this not an entity reference?
    reason text not null,
    insert_time timestamptz not null default now()
);

-- to correct OUR wrong amount.
CREATE OR REPLACE FUNCTION reconciliation__correct_ledger (in_report_id INT, in_id int, in_new_amount NUMERIC, reason TEXT) returns INT AS $$

    DECLARE
        new_code INT;
        current_row RECORD;
        l_row acc_trans;
        in_user TEXT;
        full_reason TEXT;
    BEGIN
        select into in_user from current_user;
        
        select into current_row from reports where reports.id = in_report_id and reports.id = in_id;
        select into l_row from acc_trans where entry_id = current_row.lid;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No such id % in this report.', in_scn;
        END IF;
        
        IF user <> current_row.user THEN
        
            IF current_row.our_balance <> in_new_amount AND in_new_amount = current_row.their_balance THEN
                update reports pr
                set pr.corrections = reports.corrections + 1, 
                pr.new_balance = in_new_amount,
                error_code = 0
                where id = in_report_id and scn = in_scn;
                return 0;
                
                -- After that, it is required to update the general ledger.
                full_reason := "User % is filing a reconciliation correction on the general ledger, changing amount % to amount %. 
                Their reason given is: %", in_user, current_row.our_balance, in_new_amount, reason;
                perform select reconciliation__update_ledger(current_row.lid, in_new_amount, full_reason)
            ELSE IF current_row.our_balance = in_new_amount THEN
                -- This should be something, does it equal the original 
                -- balance? If so, there's no change.
                return current_row.error_code;
            END IF;
        END IF;
        
        return current_row.error_code;            
                    
    END;
$$ language 'plpgsql';

-- to correct an incorrect bank statement value.
CREATE OR REPLACE FUNCTION reconciliation__correct_bank_statement (in_report_id INT, in_id int, in_new_amount NUMERIC) returns INT AS $$

    DECLARE
        new_code INT;
        current_row RECORD;
        in_user TEXT;
    BEGIN
        select into in_user from current_user;
        select into current_row from reports where reports.id = in_id and reports.report_id = in_report_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No such SCN % in this report.', in_scn;
        END IF;
        
        IF user <> current_row.user THEN
        
            IF current_row.their_balance <> in_new_amount AND in_new_amount = current_row.our_balance THEN
                update reports pr
                set pr.corrections = reports.corrections + 1, 
                pr.new_balance = in_new_amount,
                error_code = 0
                where id = in_report_id and scn = in_scn;
                return 0;
            
            ELSE IF current_row.their_balance = in_new_amount THEN
                -- This should be something, does it equal the original 
                -- balance? If so, there's no change.
                return current_row.error_code;         
            END IF;
        END IF;
        
        return current_row.error_code;            
                    
    END;
$$ language 'plpgsql';


CREATE OR REPLACE reconciliation__correct_passthrough ( in_report_id int, in_id int ) returns INT AS $$

    DECLARE
        in_user TEXT;
        pending_entry reports;
    BEGIN
        select into in_user from current_user;
        
        select into pending_entry from reports where report_id = in_report_id and id = in_id;
        
        IF NOT FOUND THEN
            -- Raise an exception.
            RAISE EXCEPTION "Cannot find entry.";
        ELSE IF pending_entry.errorcode <> 4 THEN 
            -- Only error codes of 4 may be "passed through" safely.
            RAISE EXCEPTION "Selected entry not permitted to be passed through.";
            
        ELSE
            -- Then we mark it passthroughable, and "approve" will overlook it.
            update reports set overlook = 't', errorcode = 0 where report_id = in_report_id and id = in_id;
            return 0;
        END IF;
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__correct_bank_charge (in_report_id int, in_id int) returns INT AS $$

    DECLARE
        in_user TEXT;
        pending_entry reports;
    BEGIN
    
        IF NOT FOUND THEN
             -- Raise an exception.
             RAISE EXCEPTION "Cannot find entry with ID % in report %.", in_id, in_report_id;
         ELSE IF pending_entry.errorcode <> 2 THEN 
             -- Only error codes of 2 may be "passed through" safely.
             RAISE EXCEPTION "Attempt to retroactively add a non-bank-charge entry to the ledger.";
         
         ELSE
             -- Then we mark it passthroughable, and "approve" will overlook it.
             
             select create_entry (pending_entry.their_balance, 'payable', pending_entry.clear_date, 'Bank charge');
             
             update reports set errorcode = 0 where report_id = in_report_id and id = in_id;
             return 0;
         END IF;
    END;

$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__correct_unaccounted_charge (in_report_id int, in_id int, reason TEXT) RETURNS INT AS $$

    DECLARE
        in_user TEXT;
        pending_entry reports;
        note TEXT;
    BEGIN
    
        IF NOT FOUND THEN
             -- Raise an exception.
             RAISE EXCEPTION "Cannot find entry with ID % in report %.", in_id, in_report_id;
         ELSE IF pending_entry.errorcode <> 3 THEN 
             -- Only error codes of 3 may be "passed through" safely.
             RAISE EXCEPTION "Not an unaccounted charge; cannot be retroactively added to the ledger.";
         
         ELSE
             -- Then we mark it passthroughable, and "approve" will overlook it.
             
             note := 'Retroactive addition of an unaccounted entry, of value %. 
             Being added by user % with the following explanation: %', pending_entry.their_balance, in_user, in_reason;
             
             select create_entry (pending_entry.their_balance, 'payable', pending_entry.clear_date,note);
             
             update reports set errorcode = 0 where report_id = in_report_id and id = in_id;
             return in_id;
         END IF;
    END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__report_approve (in_report_id INT) returns INT as $$
    
    -- Does some basic checks before allowing the approval to go through; 
    -- moves the approval to "reports", I guess, or some other "final" table.
    --
    -- Pending may just be a single flag in the database to mark that it is
    -- not finalized. Will need to discuss with Chris.
    
    DECLARE
        current_row RECORD;
        completed reports;
        total_errors INT;
        in_user TEXT;
    BEGIN
        
        select into in_user current_user;
        select into current_row distinct on user * from reports where report_id = in_report_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION "Fatal Error: Pending report % not found", in_report_id;
        END IF;
        
        IF current_row.user = in_user THEN
            RAISE EXCEPTION "Fatal Error: User % cannot self-approve report!", in_user;
        END IF;
        
        SELECT INTO total_errors count(*) from reports where report_id = in_report_id and error_code <> 0;
        
        IF total_errors <> 0 THEN
            RAISE EXCEPTION "Fatal Error: Cannot approve while % uncorrected errors remain.", total_errors;
        END IF;
        
        -- so far, so good. Different user, and no errors remain. Therefore, we can move it to completed reports.
        --
        -- User may not be necessary - I would think it better to use the 
        -- in_user, to note who approved the report, than the user who
        -- filed it. This may require clunkier syntax..
        
        -- 
        
        update reports set approved = 't', clear_time = now() where report_id = in_report_id;
        
        return 1;        
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__new_report_id () returns INT as $$

    SELECT nextval('pending_report_report_id_seq');

$$ language 'sql';

create or replace function reconciliation__add_entry(
    in_report_id INT, 
    in_scn INT, 
    in_amount numeric, 
    in_account INT, 
    in_user TEXT, 
    in_date TIMESTAMP
) RETURNS INT AS $$
    
    DELCARE
        la RECORD;
        errorcode INT;
        our_value NUMERIC;
        lid INT;
    BEGIN
    
        SELECT INTO la FROM acc_trans gl 
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
                errorcode := 2; 
                our_value := 0;
            ELSE
                -- Okay, now this is bad.
                -- They have a cheque/sourced charge that we don't. 
                -- REsolution action is going to be
                errorcode := 3;
                our_value := 0;
            END IF;
            
        ELSE if la.amount <> in_amount THEN
        
            errorcode := 1;
            our_value := la.amount;
            lid := la.entry_id;
            
        ELSE
            -- it reconciles. No problem.
            
            errorcode := 0;
            our_value := la.amount;
            lid := la.entry_id;
            
        END IF;
        
        INSERT INTO reports (
                report_id,
                scn,
                their_balance,
                our_balance,
                error_code, 
                user,
                clear_time,
                ledger_id
            ) 
            VALUES (
                in_report_id,
                in_scn,
                in_amount,
                gl.amount,
                errorcode,
                in_user,
                in_date,
                lid
            );
            
        -- success, basically. This could very likely be collapsed to
        -- do the compare check here, instead of in the Perl app. Save us a DB
        -- call.
        return 1; 
        
    END;    
$$ language 'plpgsql';

create or replace function reconciliation__pending_transactions (in_month DATE) RETURNS setof acc_trans as $$
    
    DECLARE
        gl_row acc_trans;
    BEGIN
        FOR gl_row IN
            select gl.* from acc_trans gl, reports pr 
            where gl.cleared = 'f' 
            and date_trunc('month',gl.transdate) <= date_trunc('month', in_month)
            and gl.entry_id <> pr.ledger_id -- there's no entries in the reports for this
        LOOP
            RETURN NEXT gl_row;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reconciliation__report (in_report_id INT) RETURNS setof reports as $$

    DECLARE
        row reports;
    BEGIN    
        FOR row IN select * from reports where report_id = in_report_id LOOP
        
            RETURN NEXT row;
        
        END LOOP;    
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__get_total (in_report_id INT) returns setof reports AS $$

    DECLARE
        row reports;
    BEGIN
    
        SELECT INTO row FROM reports 
        WHERE ledger_id IS NULL 
        and report_id = in_report_id 
        AND scn = -1;
        
        IF NOT FOUND THEN -- I think this is a fairly major error condition
            RAISE EXCEPTION "No Bank Total found.";
        ELSE
            return row;
        END IF;
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__corrections (in_report_id INT, in_id INT) returns setof report_corrections AS $$

    DECLARE
        corr report_corrections;
    BEGIN
    
        SELECT INTO corr FROM report_corrections WHERE report_id = in_report_id AND id = in_id LIMIT 1;
        IF NOT FOUND THEN
            RAISE EXCEPTION "No corrections for selected entry.";
        ELSE
            FOR corr IN select * from report_corrections WHERE report_id = in_report_id AND id = in_id LOOP
                RETURN NEXT corr;
            END LOOP;
        END IF;
    END;

$$ language 'plplsql';

CREATE OR REPLACE FUNCTION reconciliation__single_entry (in_report_id INT, in_id INT) returns setof reports AS $$

    DECLARE
        row reports;
    BEGIN
    
        SELECT INTO row FROM reports WHERE report_id = in_report_id and id = in_id LIMIT 1; 
        -- if there's more than one, that's a Bad Thing
        
        IF NOT FOUND THEN
            RAISE EXCEPTION "Could not find selected report entry";
        ELSE
            RETURN row;
        END IF;
    END;

$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION reconciliation__search (
    in_date_begin DATE, 
    in_date_end DATE, 
    in_account TEXT,
    in_status TEXT
) RETURNS setof reports AS $$

    DECLARE
        row reports;
        statement text;
        where_stmt text;
        v_status BOOLEAN;
        v_accum NUMERIC;
    BEGIN
        
        if in_status = "pending" then
            v_status = 'ft'::bool;
        ELSIF in_status = "approved" THEN
        
            v_status = 't'::bool;
        END IF;
        
        IF in_date_begin IS NOT NULL
            or in_date_end IS NOT NULL
            or in_account IS NOT NULL
            or v_status IS NOT NULL
        THEN
            statement = "select pr.* from reports pr ";
            statement = statement + "join acc_trans at on pr.ledger_id = at.entry_id ";
            
            IF in_account IS NOT NULL THEN
                
                statement = statement + "join chart c on at.chart_id = c.id ";
                where_stmt = "c.accno =~ " + quote_literal(in_account) + " AND ";
            END IF;
            
            IF in_date_begin IS NOT NULL THEN
                where_stmt = where_stmt + "insert_time >= " + quote_literal(in_date_begin) + " AND ";
            END IF;
            
            IF in_date_end IS NOT NULL THEN
                where_stmt = where_stmt + "insert_time <= " + quote_literal(in_date_end) + " AND ";
            END IF;
            
            IF in_status IS NOT NULL THEN
                
                if v_status == 't'::bool THEN
                    where_stmt = where_stmt + " approved = 't'::bool AND ";
                ELSIF v_status == 'f'::bool THEN
                    where_stmt = where_stmt + " approved = 'f'::bool AND ";
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
    id int
);

create or replace function reconciliation__get_accounts () returns setof recon_accounts as $$
    SELECT 
        coa.accno || ' ' || coa.description as name,
        coa.id as id
    FROM chart coa, coa_to_account cta
    WHERE cta.chart_id = coa.id;
$$ language sql;