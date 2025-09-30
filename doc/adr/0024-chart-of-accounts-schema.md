# 0024 Central CoANode table defining accounts and headings

Date: 2020-01-12

## Status

Accepted

## Summary

Addresses the design decision for the `account` and `account_heading` 
tables in LedgerSMB, specifically whether to move to inheritance across tables 
or use the current methods like triggers to maintain referential integrity.

## Context

Issue #861 complains there's no guarantee in the schema which prevents
accounts and headings being assigned the same `accno`.  The schema proposed
below (taken from the wiki), seems to prevent that.  This is however not the
case, because `UNIQUE` constraints and primary key constraints are not carried
over from the inherited to the inheriting table.

```sql
CREATE TABLE coa_node (
    id serial NOT NULL UNIQUE,
    parent int,
    number text PRIMARY KEY,
    description text NOT NULL
);
CREATE TABLE account_heading (like coa_node INCLUDING ALL) INHERITS (coa_node);
CREATE TABLE account (
     like coa_node INCLUDING ALL,
     contra bool default false,
     gifi
) INHERITS (coa_node);
ALTER TABLE coa_node ADD CHECK NOINHERIT (FALSE);
ALTER TABLE account ALTER COLUMN parent set not null;

-- translations
CREATE TABLE coa_translation (
     coa_id int,
     language_code text,
     description text,
     PRIMARY KEY (coa_id, language_code)
);

CREATE TABLE account_heading_translation (
   LIKE coa_translation INCLUDING ALL,
   FOREIGN KEY (coa_id) REFERENCES account_heading (id)
) INHERITS (coa_translation);

CREATE TABLE account_translation (
   LIKE coa_translation INCLUDING ALL,
   FOREIGN KEY (coa_id) REFERENCES account (id)
) INHERITS (coa_translation);

ALTER TABLE coa_translation ADD CHECK NOINHERIT (FALSE);
```

By changing the above, where the commonality will be stored in the `coa_node`
table directly, adding additional fields to an `account` table which links
back to the `coa_node` for the common fields, like:

```sql
CREATE TABLE coa_node (
    id serial NOT NULL UNIQUE,
    parent int,
    number text PRIMARY KEY,
    description text NOT NULL
);
CREATE TABLE account (
     id bigint not null references coa_node(id),
     contra bool default false,
     gifi
);
```

This is, however, worse than the problem being addressed: by adding a record
to the `account` table for an existing `coa_node` record, the heading is
transformed from a heading to an account from one moment to another.

Additionally, there's no way to guarantee that accounts are the leafs in
the account hierarchy tree in this schema.

## Decision

The downsides of the proposed schema outweigh those of the current schema, so
there will be no change to the current schema setup with the `account` and
`account_heading` tables.

## Consequences

 1. The proposed schema nor its revised variant will be implemented (and
    thus removed from the wiki)
 2. The downsides from the existing schema will need to be mitigated through
    other mechanisms, e.g. using triggers

## Annotations

