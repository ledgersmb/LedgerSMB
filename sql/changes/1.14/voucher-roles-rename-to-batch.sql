
create function pg_temp.rename_role(old_name text, new_name text)
  returns void language plpgsql as
$$DECLARE
  prefix text;
  old_rolname text;
  new_rolname text;
BEGIN
  select coalesce((select value from defaults where setting_key = 'role_prefix'),
                  'lsmb_' || current_database() || '__')
    into prefix;
  old_rolname := (prefix || old_name);
  new_rolname := (prefix || new_name);

  perform *
     from pg_roles
    where rolname = old_rolname;

  if found then
    perform *
       from pg_roles
      where rolname = new_rolname;

    if found then
      raise exception 'Unable to rename role % to %; target role exists', old_rolname, new_rolname;
    end if;

    execute format('alter role %I rename to %I', old_rolname, new_rolname);
  end if;

  return;
END;
$$;


select pg_temp.rename_role(old_rolname, new_rolname)
from (values
  ('ap_voucher_all',                'purchases_batch_all'),
  ('ap_transaction_create_voucher', 'purchase_transaction_create_batch'),
  ('ap_invoice_create_voucher',     'purchase_invoice_create_batch'),
  ('ar_voucher_all',                'sales_batch_all'),
  ('ar_transaction_create_voucher', 'sales_transaction_create_batch'),
  ('ar_invoice_create_voucher',     'sales_invoice_create_batch'),
  ('gl_voucher_create',             'gl_batch_create'),
  ('voucher_delete',                'batch_delete')
) as v(old_rolname, new_rolname);


update menu_acl
   set role_name = left(role_name, length(role_name) - length(v.old_rolename)) || v.new_rolename
  from (values
    ('ap_voucher_all',                'purchases_batch_all'),
    ('ap_transaction_create_voucher', 'purchase_transaction_create_batch'),
    ('ap_invoice_create_voucher',     'purchase_invoice_create_batch'),
    ('ar_voucher_all',                'sales_batch_all'),
    ('ar_transaction_create_voucher', 'sales_transaction_create_batch'),
    ('ar_invoice_create_voucher',     'sales_invoice_create_batch'),
    ('gl_voucher_create',             'gl_batch_create'),
    ('voucher_delete',                'batch_delete')
  ) as v(old_rolename, new_rolename)
 where right(menu_acl.role_name, length(v.old_rolename) + 1) = '_' || v.old_rolename;
