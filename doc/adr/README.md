
# Architecture Decision Records (ADRs)

The files in this directory are numbered sequentially
and in chronological order.  The files numbered 0000
through 0100 are historical reconstructions based on
the recollection of individual developers.

## Purpose

Quoting [an article by the 18F US government agency](https://18f.gsa.gov/2021/07/06/architecture_decision_records_helpful_now_invaluable_later/),
ADRs address a need not covered by other materials:

* People need to know how software has changed over time

But they have other benefits too (quoting from the same
article), writing ADRs:

* Helps you identify knowledge gaps
* Forces you to clarify assumptions
* May uncover options you haven’t considered
* Leads teams to consensus
* Prevents knowledge hoarding
* Allows you to step back from the day-to-day and think
  of changes on a broader scale

And reading ADRs:

* Gets new maintainers up to speed more quickly
* Frees teams from relying on one person for critical
  knowledge
* Shows maintainers if a change they’d like to do has
  been considered previously
* Can be shown as justification to stakeholders

## ADRs for LedgerSMB

Within the LedgerSMB project, we want to keep track of
the most important decisions affecting the project
development direction and code base structure.

ADRs look like a perfect addition to the toolset of the
project to keep track of these.  The toolset currently
includes GitHub issues and discussions as well as Git
history and mailing list archives.  Most of these allow
some level of reconstruction of the general directions
and the considerations, but none are intended to capture
the line of reasoning -- hence the need for ADRs.

### Naming

The name of the file to store an ADR needs to hint at the
decision that's documented in the file.  If the ADR is
about selection of PostgreSQL as the only supported
database, `0001-use-postgresql-databases-only.md` will
be a good descriptive name.

As mentioned earlier: The numbers are assigned in
chronological order.

### Template

```plain
# <4-digit-number> TOPIC OF ADR

Date: YYYY-MM-DD

## Status

<One of: Draft | Accepted >

## Context

<Description of what functional requirements
 drive the making of the decision at hand>

## Decision

<Description of the actual decision taken>

## Consequences

<Listing of consequences known at the time of
 decision-taking>.

## Annotations

<comments/remarks regarding this ADR after it has been enacted>

```


# TODO list for ADRs to be written

* Move to Vue
* Use of custom web elements to transition UI
* Use of custom web elements to phase out AMD parser
  (if we do); and the use of the shim on Safari
* Move to customizable business processes in Perl
  (thus not in the database!)
* Explicit rejection of JSONAPI as REST layer
  (because it's not REST)
* Explicit rejection of Dancer (because its API
  modules don't "do" REST or don't add much value
  over doing raw PSGI)
* Use of state machines for front-end functionality
* Use of state machines to manage resource (e.g.
  accounting document) life cycle
