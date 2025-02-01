# 0104 Business logic in Perl (revised)

Date: 2025-01-12

## Status

Draft

## Context

In [ADR 0005 Business logic in database and UI in
Perl](./0005-business-logic-in-database-and-UI-in-Perl.md) and [ADR 0022 Perl
layer is only glue between Apache and
PostgreSQL](./0022-perl-layer-only-glue-between-apache-and-pg.md), it was
decided that business logic is to be built in the database exclusively, with
the Perl layer restricted to generating the UI. With ADRs [0018 Resource
state machine engine with dependency
injection](./0018-resource-state-machine-engine-with-dependency-injection.md)
and [0019 Configuration using Dependency
Injection](0019-configuration-using-dependency-injection.md) first steps were
implicitly made moving away from this paradigm. There is nothing in PostgreSQL
that matches this type of flexibility (see [ADR
0021](0021-restricted-list-of-postgresql-extensions.md) for some difficulties
to consider).

These recent developments beg for clarity on the concerns to be fulfilled by
the active layer in PostgreSQL (PL/pgSQL) and the Perl layer.

## Decision

The active PostgreSQL layer will be responsible for actively managing the
consistency and correctness of the data stored by the passive PostgreSQL
layer.

The Perl layer will be responsible for executing the business logic.

## Consequences

The PL/pgSQL layer will communicate with the Perl layer through stored
function calls. The invocations into the PL/pgSQL layer need to be at a
granularity which allows it to determine the correctness and completeness
of data passed in the arguments and of the resulting database state.

For example: the Perl layer will need to provide an entire GL transaction
to be saved, in a single call. The called PL/pgSQL will then verify aspects
such as balancedness and minimally required reporting units.

## Annotations

