# 0021 Restricted list of PostgreSQL extensions

Date: Irrecoverable; since Pg 9.1

## Status

Accepted

## Context

The PostgreSQL database allows "extensions" to define new data types,
index types, operators and functions.  Extensions come in two classes

 1. Untrusted extensions
 2. Trusted extensions

The former category needs to be installed by a super user whereas the
latter category can be installed by database owners (i.e. non-super users).

PostgreSQL comes with a set of extensions out-of-the-box and many other
extensions are provided by third parties.

There are numerous cloud providers offering PostgreSQL hosting as a service;
most support only a limited set of extensions.  Many exclude untrusted
extensions completely and offer a limited set of pre-approved trusted
extensions.

## Decision

Considering that the target audience for LedgerSMB (Small/Medium Businesses)
needs software to be as simple to run as possible, given the above, the use
of extensions complicates the installation and maintenance process in ways
that are undesirable.

## Consequences

No extensions shall be used in LedgerSMB other than the ones mentioned in
the list below.

## Annotations

This ADR is supported by the fact that 1.10 shortly used moddatetime for
change-data-capture tracking.  This was at the time an untrusted extension
delivered with PostreSQL out-of-the-box.  Regardless it didn't take long
for upgrade problems to be reported after the 1.10.0 release.

See also

* [0104 Business logic in Perl (revised)](./0104-business-logic-in-perl.md)


## Extensions approved for LedgerSMB use

This list may be extended after the initial approval of this ADR after
appropriate discussion or through a pull request that remains open for
at least 72 hours.

 1. PL/pgSQL -- PostgreSQL PL/SQL extension language
 2. pg_trgm -- Trigram text similarity matching
 3. uuid-ossp -- UUID generator
 4. tablefunc
 5. pgcrypto -- cryptographic functions
 6. isn -- international standard (product) numbers

Note that there is no need to support the `hstore` extension, because
the built-in `jsonb` type provides a superset of functionality.
