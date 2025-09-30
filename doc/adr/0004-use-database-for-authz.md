# 0004 Use database as authorization provider

Date: Early in the 1.3 release cycle

## Status

Accepted

## Summary

Addresses the design decision to use fine grained access rights in the
the form of PostgreSQL roles for authorization in the LedgerSMB application.

## Context

Most webapps manage authorizations at the web-boundaries, at the time
requests come in, with little to no protection on any of the other layers.

At the time of this decision, access to various functionalities was controlled
by menu-item availability.  However, no enforcement of access restrictions was
implemented.  That is to say that once a user had knowledge of the URLs
to trigger specific functionality *and* the availability of a valid login
account, any functionality could be triggered.

## Decision

Access rights on database and database object level (e.g. tables and views)
will be used as an (additional) level of access control.

## Consequences

- Database connections cannot be made with a single, all-encompassing login
  account; instead, accounts with authorizations specific for the current
  user will need to be assigned exactly the intended access rights and be
  used to log into the application
- Fine-grained access rights need to be extended on database and database
  object level, managing CRUD rights on tables, columns and rows
- By consequence, Row Level Security, column grants and views will need to
  be used to provide users with exactly the right data access (and no more
  than that).  Views are a helpful tool to achieve this, because they run
  as the owner, not as the session user, which allows `sudo` type privilege
  escalation with strictly defined scope
- These fine-grained access rights are assigned to PostgreSQL roles on a
  per-applicative function granularity; e.g. creation/changing/deletion
  of a new GL account each have their own role
- These fine-grained roles are assigned to user accounts as per the first
  bullet to determine the access rights of a single user
