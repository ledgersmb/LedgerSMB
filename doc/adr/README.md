
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

<One of: Proposed | Accepted | Rejected | Replaced by XXXX >

$$ Summary

Addresses the design decision(s) to/regarding <A short summary 
according to the guidelines provided below>

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

### Statuses

An ADR can be in one of 4 statuses with the following state diagram:

                     +----------+     +----------+
                   --| Accepted |-----| Replaced |
    ------------  /  +----------+     +----------+
    | Proposed |--
    ------------  \  +----------+
                   --| Rejected |
                     +----------+

The states have the following meaning:

 1. Proposed  
    The decision has not taken effect yet. It's under discussion.
    ADRs can by definition never be in this state for long.
 2. Accepted  
    The decision has taken effect. That means all new code needs to
    comply with this decision (or an ADR should be submitted to allow
    exception). Existing code should be transformed to comply with the
    decision as soon as practically feasible.
 3. Replaced  
    The decision used to be in force, but a newer, conflicting, decision
    has been put in force since, effectively overruling it.
 4. Rejected  
    The decision has been proposed, but was explicitly not accepted by the
    project. Its existence is retained for historical purposes.

As long as the ADR has a status "Proposed", it's text can be changed based
on discussion in the project, meaning that the statuses all relate to the
idea of the decision, not the current version of the text.

### Summary Guidelines

When writing the summary the following guidelines should be followed. 
The summary should:

1. start with “Addresses the design decision(s) to/regarding”,
   which helps form a consistent focus of the summary.
2. contain a clear definition of the scope and purpose of the ADR 
   with the sole purpose of guiding new coders to relevant ADRs.
3. appear immediately after the Status section.
4. be 300 characters or less.
5. include important keywords from the ADR in the prose (not as a list).

# TODO list for ADRs to be written

* Use of custom web elements to transition UI
* Use of custom web elements to phase out AMD parser
  (if we do); and the use of the shim on Safari
* Use of state transitions (actions) on Resource (document) state machines
  (=workflows) to check user authorization (instead of [or in addition to]
  data access limitations)
* Security model for database access, using principle of least privilege by
  authenticating each user separately
* Separation of concerns between client, webserver, Perl layer and database

