# 0006 Perl uses Template::Toolkit to process templates

Date: Early in the 1.3 release cycle

## Status

Accepted

## Summary

Address the design decision regarding which template toolkit will
be used to generate UI.

## Context

The code base is one huge mix of business logic and HTML to be
sent as the HTTP response.  This makes the business logic neigh
impossible to debug and makes maintenance of the code a serious
challenge.

In [ADR 0005](./0005-business-logic-in-database-and-UI-in-Perl.md), it
was decided that the Perl layer is to generate UI to be rendered in
the browser.  This means a solution is required to clean up the code
base -- separating code and presentation.

The code base has its own templating "engine", which is currently used
to render invoices and other output documents.  This component isn't
sophisticated enough to deal with the estimated complexity required to
handle a full-fledged UI.

At the time of this decision, various templating engines were available
of which [Template::Toolkit](http://template-toolkit.org/) was the
de-facto standard.

## Decision

Template::Toolkit will be used to render the UI at the Perl level;
**no** HTML will be included at the Perl code level.

Additionally, since Template::Toolkit will become a dependency of
LedgerSMB, the output documents (invoices, etc.) will be rendered with
it as well.

## Consequences

- The Perl code concerns itself only with passing data to and from the
  database, handing the results off to Template::Toolkit to render UI
  and output documents.
