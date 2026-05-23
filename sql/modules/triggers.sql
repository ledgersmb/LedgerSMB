

set client_min_messages = 'warning';


BEGIN;


CREATE OR REPLACE FUNCTION gl_audit_trail_append()
RETURNS TRIGGER AS
$$
DECLARE
   t_reference text;
   t_row RECORD;
   t_id int;
BEGIN

IF TG_OP = 'INSERT' then
   t_row := NEW;
ELSE
   t_row := OLD;
END IF;

IF TG_TABLE_NAME IN ('ar', 'ap') THEN
    t_reference := t_row.invnumber;
    t_id := t_row.trans_id;
ELSE
  select reference into t_reference
    from transactions
   where id = t_row.id;
  t_id := t_row.id;
END IF;

INSERT INTO audittrail (trans_id,tablename,reference, action, person_id)
values (t_id,TG_TABLE_NAME,t_reference, TG_OP, person__get_my_entity_id());

return null; -- AFTER TRIGGER ONLY, SAFE
END;
$$ language plpgsql security definer;


COMMENT ON FUNCTION gl_audit_trail_append() IS
$$ This provides centralized support for insertions into audittrail.
$$;


CREATE OR REPLACE FUNCTION prevent_closed_transactions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE t_end_date date;
BEGIN
SELECT max(end_date) into t_end_date FROM account_checkpoint;
IF new.transdate <= t_end_date THEN
    RAISE EXCEPTION 'Transaction entered into closed period.  Transdate: %',
                   new.transdate;
END IF;
RETURN new;
END;
$$;

CREATE OR REPLACE FUNCTION trigger_parts_short() RETURNS TRIGGER
AS
'
BEGIN
  IF NEW.onhand >= NEW.rop THEN
    NOTIFY parts_short;
  END IF;
  RETURN NEW;
END;
' LANGUAGE PLPGSQL;


create or replace function cdc_update_last_updated()
  returns trigger as
$$
BEGIN
  IF TG_OP <> 'DELETE' THEN
    NEW.last_updated := NOW();
  END IF;
  RETURN NEW;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION trigger_duplicate_account_accno()
  RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM * FROM account_heading
    WHERE accno = NEW.accno;

  IF FOUND THEN
    RAISE EXCEPTION '"accno" % in use as account heading', NEW.accno;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trigger_duplicate_account_accno() IS
  $$Checks that the 'accno' being set on an account is not already
  in use for an account heading.
  $$;

CREATE OR REPLACE FUNCTION trigger_duplicate_account_heading_accno()
  RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM * FROM account
    WHERE accno = NEW.accno;

  IF FOUND THEN
    RAISE EXCEPTION '"accno" % in use as account', NEW.accno;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trigger_duplicate_account_heading_accno() IS
  $$Checks that the 'accno' being set on an account heading is not already
  in use for an account.
  $$;

CREATE OR REPLACE FUNCTION trigger_workflow_user() RETURNS TRIGGER
AS $$
BEGIN
  IF TG_OP <> 'DELETE' THEN
    NEW.workflow_user = CURRENT_USER;
    NEW.workflow_entity_id = person__get_my_entity_id();
  END IF;
  RETURN NEW;
END;
$$ language plpgsql;

COMMENT ON FUNCTION trigger_workflow_user() IS
  $$Sets the name of workflow records to `CURRENT_USER` and the user id to
  the entity_id of the current user.
  $$;

CREATE OR REPLACE FUNCTION trigger_invoice_prevent_allocation_delete() RETURNS TRIGGER
AS $$
BEGIN
  IF OLD.allocated <> 0 THEN
    RAISE EXCEPTION 'Cannot DELETE "invoice" record id=%: non-zero "allocated" value', OLD.id;
  END IF;
  RETURN OLD;
END;
$$ language plpgsql;

COMMENT ON FUNCTION trigger_invoice_prevent_allocation_delete() IS
  $$Prevents deletion of the "invoice" record in case the "allocated" field is non-zero to
  maintain correct COGS assignment.
  $$;

create or replace function trigger_open_item_maintenance() returns trigger
as $$
begin
  if exists (select 1
               from account
              where new.chart_id = account.id
                and open_item_managed) then
    if new.open_item_id is null then
      if TG_OP = 'UPDATE' then
        raise exception 'Setting open_item_id to NULL not allowed on open item managed account';
      elsif exists (select 1
                      from account_link al
                     where account_id = new.chart_id
                       and description = ANY(ARRAY['AR', 'AP',
                                                   'AR_overpayment',
                                                   'AP_overpayment']::text[])) then
        raise exception 'AR/AP (overpayment) items need to be posted with open_item_id on the AR/AP (overpayment) accounts, which account % is not', new.chart_id;
      elseif exists (select 1
                       from account_link al
                      where account_id = new.chart_id) then
        raise exception 'Open item auto-generation only supported for plain GL accounts, which account % is not', new.chart_id;
      else
        insert into open_item (item_number, item_type, account_id, opening_entry_id)
        values (setting_increment('openitemnumber'), 'gl', new.chart_id, new.entry_id)
        returning id into new.open_item_id;

        raise warning 'Created open item % due to insert without open_item_id on open item maneged account', new.open_item_id;
      end if;
    else
      -- verify that the open item matches the line's chart_id
      if new.chart_id <> (select account_id
                            from open_item oi
                           where oi.id = new.open_item_id) then
        raise exception 'Open item % not associated with account %', new.open_item_id, new.chart_id;
      end if;
    end if;
  else
    if new.open_item_id is not null then
      raise exception 'Account % not open-item managed; providing open_item_id not allowed', new.chart_id;
    end if;
  end if;

  return new;
end;
  $$ language plpgsql;

comment on function trigger_open_item_maintenance() is
  $$Make sure to have item references on open item managed accounts.

  This function creates a new open item, if a posting is done without an open
  item reference - if the account is *not* an AR/AP account (assumption: it is a GL account).
  $$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';

COMMIT;
