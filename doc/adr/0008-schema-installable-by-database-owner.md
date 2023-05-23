# 0008 Database schema should be installable by database owner

Date: Unknown

## Status

Accepted

## Context

Some PostgreSQL features require super user rights to install (e.g.
non-trusted extensions).  Especially shared hosting providers don't
allow super user access, instead providing (non-super user) database
owner access.

Combined with the goal to have a simple installation procedure and
the target user group which is likely to want to use hosted services,
it follows that needing super user rights is a problem.

## Decision

The installation and running of LedgerSMB must be possible without
super user rights.  The most elevated rights required to install and
run the software must be (non-super user) database owner.

## Consequences

- No use of PostgreSQL non-trusted extensions.
- Special care must be taken when checking permissions, such as
  when [changing user access rights](https://github.com/ehuelsmann/LedgerSMB/blob/ca16f284a8380e6596f466e467e67483d95e3e05/sql/modules/admin.sql#L141-L146)
