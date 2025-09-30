# 0020 Time in the database (PostgreSQL timestamp type)

Date: Irrecoverable, but likely during 1.3 timeframe

## Status

Accepted

## Summary

Addresses the design decision to use TIMESTAMP WITHOUT TIME ZONE for all
database timestamps.

## Context

PostgreSQL has two data types for storing timestamps:

 1. TIMESTAMP WITH TIME ZONE; and
 2. TIMESTAMP [WITHOUT TIME ZONE]

These types tend to cause confusion among developers.

PostgreSQL stores *all* timestamps in UTC in the database.  That is, it
stores `TIMESTAMP WITH TIME ZONE` *without time zone and in UTC time*.  Upon
retrieval, the time zone of the server is used to calculate the "local" time
for the `WITH TIME ZONE` data type.

In the context of the LedgerSMB web application, the server local time is
irrelevant: users may be in a different time zone than the server or even
in different zones from each other.  It's therefore important to present
times at a scale most meaningful to the current user.

## Decision

The server component, including the database, will be timezone agnostic,
running entirely in UTC time.

## Consequences

 1. The database schema will use the `TIMESTAMP WITHOUT TIME ZONE` - or just
    `TIMESTAMP` data type
 2. Time stamps must be converted to UTC on the server component boundaries
 3. When no time zone is specified, the time stamp is assumed to be UTC

## Annotations

Although the above line of reasoning is what determines the implementation as per
the date of writing this ADR, the writing of the ADR itself triggered discussion
which came to the conclusion a design with `TIMESTAMP WITH TIME ZONE`, even though
it stores its data in UTC just as the `WITHOUT TIME ZONE` design, takes time zones
provided with input data into account -- the current schema will **drop** time zone
information in case data is accidentally not normalized to UTC.
To make sure the database output keeps working as expected, the database client should
set the time zone upon creating a connection using `SET TIME ZONE TO "Etc/UTC";`.  This
will cause all output dates to have a time zone component `+00`.
