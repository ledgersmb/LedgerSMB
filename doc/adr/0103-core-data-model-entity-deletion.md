# 0103 Core data model entity deletion

Date: 2025-01-25

## Status

Draft

## Context

At some point in the history of the project, it was decided that supporting
the deletion of core data model elements, such as `entities` (ie., rows in
the `entity` table), credit accounts and other central concepts which are
referred to from many other tables, was not going to be supported due to
complexity: it's too hard to verify that the removal can be successful due
to the number of tables linking to these records. The required checks would
be fragile under change to the database schema.

There are regularly requests for deletion of unused data, such as entities
and credit accounts. Use cases include removal of (accidental) duplicates.

A solution has now been thought of which eliminates much of the original
complexity: by setting up the correct ON DELETE actions on REFERENCES
relationships to ensure desired cascading of deletion (or blocking),
such as contact data attached to credit accounts, PL/pgSQL procedures can
be used to test whether the record can be deleted or not. The scope of the
PL/pgSQL procedure is a (sub)transaction which gets cancelled upon unsuccessful
deletion. By catching this error using an EXCEPTION block, the outer
transaction won't be rolled back. This way, the following function can be
created, returning a boolean indicating whether the record *can* be deleted
or not:

```sql
create function can_delete_entity(in_id int) returns boolean as
$$
begin
  delete from entity where id = in_id;
  raise sqlstate 'P0004'; -- cause transaction abort
exception
   when foreign_key_violation then
     return false;
   when assert_failure then
     return true;
end;
$$ language plpgsql;
```

Using this procedure, database constraints ensuring referential integrity
are leveraged for the deletion check. There is no need to duplicate these
constraints in functions.

### Related concerns

Credit accounts (but not entities) have an end date. This end date can be
used to 'disable' the account: the accounts won't be listed as available
counterparties on dates after the end date. The end date performs a different
function than the deletion of records: it can be used to disable credit
accounts which cannot be deleted because they *are* used.

Similarly, the Obsolete checkmark on GL Accounts can be used to prevent
the account from being available for selection on new transactions.

## Decision

1. Deletion of GL accounts is desirable, because it enables the user to
   start from a pre-defined chart of accounts, removing those which are
   not relevant
2. Deletion of entities is desirable, because duplicates happen in real
   life; limiting the number of occurrences of an entity prevents the
   administration from becoming a mess
3. The earlier decision *not* to delete *unused* core data because of
   complexity concerns, does no longer apply
4. The relational constraints and their ON DELETE actions will be leveraged
   to ensure data consistency
5. The pattern with functions checking whether records can be deleted
   will be used when such status is required for, e.g., user interaction

## Consequences

The functions need to be implemented indicating whether the following data can
be deleted:

- GL Accounts
- GL Account headings

These currently exist, embedded in the function `report__coa()`.

Additionally, functions can be implemented to delete entities (persons,
companies) and entity credit accounts to fulfill the outstanding user need.

## Annotations
