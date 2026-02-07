# 0108 Transactions are a representation of a resource

Date: 2025-11-15

## Status

Accepted

## Summary

Addresses the considerations regarding journal lines resulting from e.g.
manufacturing lots and fixed assets as to whether they are separate
resources or can be combined into a single resource.

## Context

In [ADR 0017](./0017-state-machines-for-resource-state-management.md) the
decision is documented to manage resources with state machines. That decision
considers state machines which are independent of all other state in the
system; eg., orders, e-mails and recurrence patterns.

In some cases, data of a resource - e.g. asset reports - leads to a transaction.
Since resources have their state managed by workflows and (GL) transactions are
resources, the question at hand is how the (GL) transactions relate to the
resources of which they are a consequence.

Currently, some resources register their transactions as part of their resource
(AR and AP) while others register their transactions as what could be considered
separate resources (GL transactions): e.g. overpayments, fixed asset reports and
year-end closings.

There are two options:

 1. The transactions resulting from resources such as asset reports
    are separate resources
 2. The transactions resulting from resources such as asset reports
    are different representations of the same resource

The consequence of option (1) is that there are two separate resources with
closely related and mutually dependent states: when the asset report is
approved, the related transaction needs to be approved. When the transaction
is reversed, so should the asset report.

The consequence of option (2) is that the transaction data is considered to be
part of the resource of which it is a representation. That is, the transaction
that represent the value change in a fixed asset is part of the fixed asset's
depreciation report. In this design, there is no need to align the transaction
resource with the depreciation report resource.

## Decision

Considering the complexity resulting from the choice of either option,
it looks like option (1) is by far the most complex to implement as well as
to keep consistency across the application.

The decision is therefor to adopt option (2):
 1. Transactions are representations of a resource
 2. GL transactions are a separate category of resources

## Consequences

The consequence of decision (1) are:

 1. Managing the state of a transaction is part of the workflow of
    the resource of which it is a representation
 2. Actions to manage transaction state will be used universally
    across workflows

The consequence of decisions (1) and (2) together are:

 1. When a transaction is a GL transaction, it cannot be a fixed asset,
    year-end closing or other transaction at the same time
 2. The `transactions` table will be used to store transactions
 3. Common fields between the `ar`, `ap` and `gl` table should be
    considered for the `transactions` table (`description`, ...)
 2. Resources which are currently generating GL transactions should stop
    doing so and instead generate plain transactions:
    1. fixed assets (`asset_report` table)
    2. overpayments (`payment` table)
    3. year-end closing (`yearend` table)
    4. manufacturing (`mfg_lot` table -- completely lacking reference
       to its associated transaction at this time)
 3. The resources mentioned above should link to the `transactions` table
    (instead of to the `gl` table, if they are now)
 4. The `gl` table has a place in the system for GL transactions
 5. Non-GL transactions need to move out of the GL table, having the `tablename`
    entry in the `transactions` table adjusted to the type of table they really
    refer to (e.g. asset_report)

In addition to the consequences for application and database logic listed,
there are consequences for the user interface as well:

 1. Each resource must facilitate a generic 'transaction' view next to its
    current resource-specific view (possibly except GL transactions where
    both views could be the same)
 2. The GL transaction view (with its current GL transaction buttons) cannot
    be used to present non-GL transactions
 3. Search results from "General Journal > Search" should link to views
    presenting the associated resource in "transaction view" (preferably
    allowing to switch to other representations)


## Annotations

[ADR 0017](./0017-state-machines-for-resource-state-management.md) describes
the decision to manage resources with state machines.
