# 0003 Use database as authentication provider

Date: Early in the 1.3 release cycle

## Status

Accepted

## Summary

Addresses the design decision to use database roles as the 
authentication provider for the LedgerSMB application.

## Context

The security of password storage has been and remains a major point of
concern in IT in general and with web applications in particular:
passwords often used to be stored in clear text or would use other
insufficiently secure storage mechanisms.

LedgerSMB uses passwords in its authentication process and therefor is
potentially affected by these problems too; however, we have a strong
desire to avoid falling into these traps *and* leverage other (much more
heavily audited) open source solutions.

## Decision

Each user in a LedgerSMB company database will be associated with a
PostgreSQL database role with login rights.  The webapp will pass any
credentials received onto the database to authenticate the user.

## Consequences

- The webapp does not need to store any passwords itself, deferring
  this responsibility to PostgreSQL
- Whenever PostgreSQL is upgraded to more secure storage methods,
  the webapp automatically benefits from this upgrade
- Security audits of PostgreSQL are immediately inherited by our
  project -- most likely PostgreSQL attracts more eyes than LedgerSMB
  meaning much more thorough review than we could ever wish
- Usernames are roles; roles are global, meaning every username can
  only be expended to one person
- When a username is used across companies, all these companies share
  the same (unknown) password for this username
