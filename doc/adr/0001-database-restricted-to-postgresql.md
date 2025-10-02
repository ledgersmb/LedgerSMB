# 0001 Only support PostgreSQL at the database layer

Date: Early in the 1.3 release cycle

## Status

Accepted

## Summary

Addresses the design decision to use PostgreSQL instead of other 
relational database systems.

## Context

Many relational database management systems (RDBMSes) are available
in the market, some of which Open Source.  At the time of this
decision, two main contestants were around in open source:

* MySQL
* PostgreSQL

and a large number of contestants were available through commercial
channels:

* DB2
* Oracle
* ... many others

When comparing MySQL with PostgreSQL at the time, MySQL had problematic
ACID (Atomicity, Consistency, Isolation, Durability), integrating these
properties on a naive design. PostgreSQL had been designed with these
properties in mind from the start *and* had great extensibility to offer
through customizable aggregations, triggers, extensive rule system and
many more features.

Although SQL is a standard, many features are partially available or
slightly differently implemented across database vendors/implementations,
making it hard to write truly platform agnostic SQL code.

## Decision

We strictly target the PostgreSQL database for our online transaction
processing (OLTP).

## Consequences

- Every developer has access to the database software (it's freely available
  on almost every *nix distribution and Windows)
- Having a single SQL platform limits the variation of SQL engines that need
  to be targeted, reducing complexity and margin for error
- PostgreSQL specific features such as the use of PL/pgSQL, custom aggregates
  and NOTIFY/LISTEN can be used.
