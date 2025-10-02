# 0002 Ensure database consistency through procedural API

Date: Early in the 1.3 release cycle

## Status

Accepted

## Summary

Addresses the design decision for assuring database consistency
independently of any application accessing the database.

## Context

For an accounting application, it's of the utmost importance to ensure
the contents of the database is correct and compliant with the invariants
that the application programmer assumed.

The code base has many locations at which the database is being accessed.
Additionally, it's envisioned that people want to access the database
through other means than the web application front end.  These means may
include applications developed in other languages than Perl, especially
given its decline in popularity at the time (between 2006-2010).

Additional complexity on the database side to fulfill its role in
enforcement of consistency is that the consistency requirement is spread
over multiple rows. E.g. the requirement of transactions being balanced
affects (small) groups of journal lines. Validating the groups of journal
line rows in triggers is highly inefficient, because triggers will be
evaluating the set-requirement for each modified line (searching the total
set to find the other lines). Or - when evaluated on a statement level - need
to evaluate *all* lines...

A procedural interface using stored procedures can operate on entire
transactions or other groups of data that need group-consistency before
(atomically and) efficiently modifying the content in the database tables.

## Decision

Consistency and correctness will need to be guarded on the database side;
not on the web application side of the application.  Especially the
assumption that other languages will be involved in database accesses in
the future, invalidates writing an access module in Perl as an option to
solve the consistency problem.

In order to realize the consistency checks in an efficient manner, the
database needs to provide an API using stored procedures for modifying
data to which group-consistency applies, such as the journal lines in
a ledger transaction being modified.

## Consequences

- Unlike in many webapps, the database is not just a data storage medium,
  but an active component
- The webapp should not trust the database to be doing its work correctly,
  meaning it should apply any checks for known data consistency requirements
- The database may not assume the client having done its work correctly,
  meaning it should actively check all consistency requirements (the client
  could be an application other than the regular client, e.g. a Python app)
