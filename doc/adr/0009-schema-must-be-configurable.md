# 0009 Database schema must be configurable

Date: During 1.3 development

## Status

Accepted

## Summary

Addresses the design decision related to which database schemas the
LedgerSMB data can reside.

## Context

LedgerSMB aims to provide a good foundation to build other
business services on.  This inherently means that users will
want to combine data from the LedgerSMB database with their
own applications.

The simplest way for applications to share data with LedgerSMB,
since it runs in a single schema, is to run in a separate schema
in the same database as LedgerSMB; this prevents complicated
scenarios with data replication or 'foreign data wrapper' setups.

## Decision

Although the PUBLIC schema is the default to use with LedgerSMB,
any schema valid name may be used e.g. because PUBLIC is in use
for another application.

The PUBLIC schema remains the default, because that's the route
of the least surprise: users checking the database are connected
to PUBLIC on `psql` and listing the content of the schema to check
what's there - using \d - will show actual content.

## Consequences

- All Perl application code must take into account that the schema
  needs to be either explicitly prepended to identifiers, or, that
  the search path needs to be correct.
- Nothing in the logic may explicitly refer to a schema, instead
  depending on implicit references based on the search_path setting.
