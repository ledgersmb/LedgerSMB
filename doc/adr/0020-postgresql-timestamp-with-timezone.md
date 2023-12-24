# 0020 Time in the database (PostgreSQL timestamp type)

Date: Unknown

## Status

Accepted

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
running entirely in UTC time

## Consequences

 1. The database schema will use the `TIMESTAMP WITHOUT TIME ZONE` - or just
    `TIMESTAMP` data type
 2. Time stamps must be converted to UTC on the server component boundaries
 3. When no time zone is specified, the time stamp is assumed to be UTC

## Annotations
