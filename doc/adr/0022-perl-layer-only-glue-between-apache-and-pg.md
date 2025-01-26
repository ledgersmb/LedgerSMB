# 0022 Perl layer is only glue between Apache and PostgreSQL

Date: During 1.3 development (2007)

## Status

Accepted

## Context

The existing code base mixes User Interface rendering (HTML composition)
with business logic (tax calculations, inventory management, etc.) and
state persistence (updating database tables).  This "design" typically
dates back to the early days of the web when computers weren't as
powerful and compute resources were expensive.

PostgreSQL is a powerfull database system which offers much more than
just state persistence; it can be extended in many ways, the simplest
of which is by the creation of stored functions through the PL/pgSQL
language.

Apache 2 is a powerfull web server perfectly suited to execute the CGI
application that is LedgerSMB: reviewed by many because of its net-wide
use and flexible in its configuration.

The early-web-days "design" is showing its age as most web applications
have moved on to depend on libraries for many of the functions they need
such as HTML composition.  LedgerSMB needs to clean up its code base in
order to become long-term maintainable and needs to make a move similar
to all the other web applications have.

## Decision

LedgerSMB will separate the responsibilities of

 1. Web request serving (responsibility Apache 2)
 2. HTML composition (responsibility: Perl through Template::Toolkit)
 3. Business logic, e.g. bank reconciliation, fixed assets depreciation,
    etc. (responsibility: PostgreSQL through PL/pgSQL)

## Consequences

 1. LedgerSMB will depend on the Template::Toolkit template engine
    for HTML composition
 2. The Perl layer will do nothing more than marshall request data
    to PostgreSQL in the input processing phase of the request handling
 3. The Perl layer will use the PostgreSQL response, do minimal
    post-processing and drive template expansion, using the expanded
    template as the response to the web request

## Annotations

See

* [0104 Business logic in Perl (revised)](./0104-business-logic-in-perl.md)
