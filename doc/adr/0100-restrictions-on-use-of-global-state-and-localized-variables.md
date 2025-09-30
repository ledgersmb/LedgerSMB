# 0100 Restrictions on use of global state and local-ized values

Date: 2023-12-28

## Status

Accepted

## Summary

Addresses the design decision regarding reducing the use of global state
to situations where no other choice is available, the deprecation of 
`LedgerSMB::App_State`, the use of `local` to limit Perl built in variables
and the appropriate layer for state to be stored.

## Context

Global state is the prevalent design in 'old code'[^1]; this means that
variables are either declared as `our` variables (or not declared at all,
which is the same thing when 'strict' and 'warnings' are turned off).
Originally, there was *no* use of `my` (local) variables.  This design
often causes unexpected and breaking side-effects.

In more recent code, global state is used to store per-request values such
as the database connection object, a user (preference) object and other
per-request state.  The globally available user preferences are used in
Moose type coercion, converting strings (containing user-formatted
amounts and dates) to their respective internal PGNumber and PGDate
representations.  This causes tight coupling between almost every part
of the application and the outermost request-handling.

Both designs pose a problem for re-usability of the code in the codebase.
The former because it's unclear from the code what is expected of callers
in terms of setting up a sufficient environment to obtain the desired
result.  The latter because it requires setting up an environment which
includes user settings in order to be able to invoke the functionality.

Recent developments highlight the need for re-usability in the LedgerSMB
code base: both the creation of `ledgersmb-admin` as well as the creation
of API entry points - without re-implementing functionality - need it.

Global state *does* have a place for some purposes: although it *could* be
useful to specify configuration such as the workflows and the document
"formatters" or API "routes" (URL entry points) on a per-request or
per-session basis (mainly in mass hosting situations), the resulting code
base would become much more complex -- for relatively little gain as mass
hosting falls outside the target audience for LedgerSMB.

[^1]: Code inherited from the SQL Ledger project at the time of the fork

## Decision

 1. Global state is to be avoided as much as possible, passing required
    state from callers to callees, so that the innermost functionality
    can be used as library function to support the existing web UI
    functionality as well as `ledgersmb-admin` and API entry points.
 2. The outer-most layers are responsible for converting external
    number/date/currency/timestamp representations to their internal
    formats
 3. Internal code (not immediately and apparently outward facing) must
    assume data is being presented in internal formats (i.e.
    PGNumber/PGDate/PGTimestamp)

## Consequences

 1. The outer-most layers must stop passing data from `$form` or `$request`
    'as-is' to the next layer; instead taking responsibility for explicit
    data type conversion
 2. `LedgerSMB::App_State` needs to be removed
 3. `LedgerSMB::MooseTypes` `coerce`-support needs to be removed
 4. Routines for parsing user input need to be used everywhere where user
    input is expected
 5. Routines for formatting user readable output need to be used everywhere
    where output is expected to be generated according to user preferences
 6. `local` should be used to limit the scope of impact on Perl built-in
    variables such as `$@` and `%ENV` as well as per-request (global)
    variable assignment to ensure automatic state cleanup

The "domain specific language" (DSL) used to specify API entry points is a
good example of the exception to rule (1) as it simplifies the code base:
while the entry points are loaded, the router keeps a global configuration
to collect the routes being specified.  This global state is restricted to
the start-up phase of the application thereby not hiding side-effects during
execution.

## Annotations

