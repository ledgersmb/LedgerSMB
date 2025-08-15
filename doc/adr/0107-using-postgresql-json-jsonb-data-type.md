# 0107 Using PostgreSQL's JSONB data type

Date: 2025-08-15

## Status

Draft

## Context

PostgreSQL has added the JSON data type in version 9.2 and the JSONB data type
in version 9.4. These data types provide schemaless, non-relational storage.
Before offering JSON(B), it offered the `hstore` data type: a key/value store
embedded in a single field. The JSON(B) data types are much richer, because the
keys and values in an `hstore` can only be strings. In ADR
[#0021](./0021-restricted-list-of-postgresql-extensions.md) the decision was
taken not to use the `hstore` data type, in favor of using the JSON/JSONB types.

### JSON vs JSONB

JSONB is the improved version of JSON, with more efficient storage and (better)
checks on validity of the data being stored and more advanced indexing. All
modern implementations use (or should use) JSONB.

### JSONB (schemaless) vs relational

Although ADR [#0021](./0021-restricted-list-of-postgresql-extensions.md) does
favor JSONB over `hstore`, it doesn't address the question of when and why to
use schemaless storage.

While it's possible to use JSONB data as "records" using the `JSON_TABLE` and
`jsonb_to_recordset` functionalities, doing so looses many of the advantages
of using a relational database such as indexing and data consistency. These
are properties that the LedgerSMB team has worked hard on since 2006 to *add*
to the software; no ADR should reduce the importance of that.

There are however, cases where users want to add data to LedgerSMB that is
neither foreseen nor necessary for the execution of its primary function. To
that extent, there is no consistency requirement within the application nor
any means for the application to verify consistency. Since the structure of
this additional data is - by definition - not known beforehand, it's not
possible to incorporate in its schema.

## Decision

1. The JSON data type is not to be used in LedgerSMB; all JSON data must
   be stored in the JSONB data type.
2. All data that is used to perform an application functions in LedgerSMB
   (that is: anything beyond storage, retrieval and presentation), *must*
   be part of the relational schema - i.e. must not be stored as JSONB.
3. Data which does not perform an application function for which the schema
   *can* be determined at design time - such as translations and file
   attachments - *should* be part of the relational schema - i.e. should not
   be stored as JSONB.
4. Data which does not perform an application function and for which a schema
   *can not* be determined at design time - such as user-defined information
   with respect on parts or entities, should be stored as JSONB.

## Consequences

Since none of `hstore`, `json` and `jsonb` are currently in use in the schema
and since the decision indicates that file attachments and translations are to
be part of the relational schema (which they currently are), there are no
consequences of this decision on the existing code base.

## Annotations

