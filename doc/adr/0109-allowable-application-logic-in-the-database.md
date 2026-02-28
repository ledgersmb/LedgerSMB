# 0109 Allowable application logic at the database level

Date: 2026-03-??

## Status

Draft

## Summary

Addresses the distribution of concerns over workflow actions, the persister,
the database active layer (PL/pgSQL) and the storage layer.

## Context

In [ADR 0104 (Business logic in Perl - revised)](./0104-business-logic-in-perl.md),
it was decided that the database active layer will be responsible for active management
of consistency and correctness of data stored. The Perl layer (workflow actions) will
be responsible for executing business logic.

This decision makes sense when considering functionalities such as reconciliation;
although this is implemented in the active database layer, the functionality needs
large amounts of freedom for customization -- data from banks and requirements of
users greatly vary.

While this is straightforward with reconciliations on one side of the spectrum and
transactions on the other (transactions need very little business logic),
inventory adjustments are in a more challenging category: when approved, COGS needs
to be calculated and a transaction representation of the inventory report posted.

There are two available scenarios for calculating COGS as part of the inventory
adjustment process: (a) as part of the active database layer when the report is
approved; or (b) as an action in the workflow which is triggered as part of the
approval process.

Option (a) has the following consequences:

* Triggering COGS calculation can be done in one of two ways
  1. Saving the report as "approved" triggers the COGS calculation; in one of two ways:
     1. The approval is committed using a database function which triggers COGS
     2. The approval is saved using an UPDATE statement where a BEFORE trigger creates
        the associated COGS (or cancels the transaction on error)
  2. The persister explicitly triggers the COGS calculation as part of the
     workflow update
* Round trips between the database and application are kept to a minimum
* Locking of data is easily added using standard database primitives, ensuring
  COGS calculation requirements (exact ordering and strict single use of parts)
* All data required for inventory update, COGS and transaction calculation
  is readily available
* COGS method that's coded in the database is available to users (currently
  only FIFO)
* Handling of an 'insufficient parts for FIFO allocation' error is cumbersome
  and needs to be coded into the database layer

Option (b) has the following consequences:

* The COGS calculation will not be triggered on the database level; it will
  be calculated explicitly in a transaction
* Not all data is readily available from the database, so more data needs to
  be read (eg, data on allocation of stock)
* Any COGS method that the user wants to create can be customized with
  regular mechanisms (ie., dependency injection)
* Locking needs to be added to workflows asata is generally read from the
  database without locking, which doesn't fit the COGS case where COGS
  *must* be allocated *exactly* once
* Handling of an 'insufficient parts for FIFO allocation' error can be dealt
  with in the application layer, possibly customized through dependency injection


__*Note*__: The same applies for COGS from invoices.


### Evaluating options (a) and (b)

Given the guardrails that the database should not contain business logic,
option (b) would be the logical choice.  However, the guardrails also say
that the database active layer is responsible for ensuring consistency of
the data in the database.  From this perspective, it should disallow
storing an approved inventory report without an associated COGS transaction.
But that's not all: it should *also* ensure that no part can be allocated
out-of-order (not FIFO) or that a part will be allocated multiple times. By
performing the allocation *in the database*, the database can guarantee
(except for its own bugs) that the data stored is consistent with the
approved inventory report.


## Decision

The above context description raises the question to what extent
business or application logic *can* be built into the database to
ensure consistency.

## Consequences




## Annotations

