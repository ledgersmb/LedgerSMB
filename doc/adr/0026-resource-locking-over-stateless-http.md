# 0026 Resource locking over stateless HTTP

Date: During 1.3 cycle (before 2013)

## Status

Accepted

## Summary

Addresses the design decision to use a `session` concept for each logged in
user which persists in the database.

## Context

LedgerSMB - being a multi-user (web) application - needs to protect some
of its resources (eg., transactions and batches) against concurrent
modification. Applications with direct database access or client/server
applications with persistent connections can use long-running database
connections with record locking to protect against concurrent modification.

As a web-application, LedgerSMB is a type of client/server application,
with only short-lived connections to the server (and in a load-balancing
scenario even "with short-lived connections to *a* server"). In LedgerSMB's
design, database connections are tied to the HTTP request/response cycle. As
a consequence, the connections don't last long enough to protect resources
from concurrent modification.

Since the traditional method of record locking does not help LedgerSMB to
protect against concurrent modification of resources, it needs a different
mechanism, which - like more traditional applications - is tied to the
logical duration of access. The logical duration of access would be the
period over which the user is working on the resource. The resource should
be freed after the user completes or given a period of inactivity.

## Decision

LedgerSMB will have a `session` concept for each user logged into the
application. This session persists in the database as long as the user
is logged in. Extended periods of inactivity will lead to the session
expiring and cleanup. The session will also be cleaned up when the user
logs out.

The session will be an anchor for other - session scoped - concepts,
including but not limited to locked transactions and batches.

## Consequences

1. There will be a `session` table with records for each logged in user
2. The table will have a clean up mechanism to remove expired sessions
3. Resources which need to be locked, will have a link to the session in
   which they are locked, signalling a "logical" lock
4. There needs to be a mechanism to clean up the links to expired sessions
   (eg. `ON DELETE SET NULL`)

## Annotations

