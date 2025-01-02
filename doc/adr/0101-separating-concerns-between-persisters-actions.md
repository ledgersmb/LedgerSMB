# 0101 Separating concerns between workflow persisters and actions

Date: 2025-01-02

## Status

Draft

## Context

The `Workflow` state management library divides the concerns "performing actions"
and "storing resulting workflow state" between the `Workflow::Action` and the
`Workflow::Persister` respectively. Is the context of a passive storage backend
(such as a filesystem), the consequences are straight forward: the persister
serializes the context and stores it on disk. The rest happens in actions.

In LedgerSMB, the storage layer isn't just a passive component: it's a
PostgreSQL database server with stored procedures as active components. In case
of a passive storage, access to it is restricted to the persister. In case of
the active storage in LedgerSMB, this demarcation isn't as straight forward.

Consider period closing, for example: there are two actions (`close` and
`reopen`) which move the state of the workflow between states `CLOSED` and
`OPEN`. The persister stores the workflow state, which is the end date of the
closed period. Each workflow in `CLOSED` state should have an "accounting
snapshot" stored. No workflow in `OPEN` state can have an accounting snapshot:
the consequence of the `close` action hence should be the creation of a
snapshot. If the `close` action itself is to ensure the creation of the
snapshot, it needs access to the storage layer.

There are two options to deal with the active side of the storage layer:

1. Worklfow actions operate on the active side of the storage layer  
   i.e. workflow actions trigger stored procedures
2. Workflow persisters communicate with actions to make the persister
   perform the necessary actions  
   i.e. actions operate solely on workflow state, unable to access the
   persistence layer

The downside of (1) is that in its design, Workflow didn't account for
actions which need to access the database (storage) layer, requiring
customization of the workflow to support the pattern.

The downside of (2) is that it results in tight coupling between actions
and persisters: any new actions which require invocation of stored
procedures will need changes in the persister as well.


NOTE FOR DISCUSSION: Add explanation of why this is *not* the same problem
as the one resolved by the `extra_data` table in the `::ExtraData` persister.


## Decision

The persister needs to store the workflow state. This could be simply in the
`workflow_context` and `workflow` tables as well as in additional tables, as
long as the function of the persister is restricted to transformation of
existing values, which excludes invoking stored procedures.

Actions will be responsible for invocation of stored procedures and modification
of other tables' contents except for modification of workflow state tables.

NOTE FOR DISCUSSION: do actions need to directly access the database, or do we
use a Perl-internal APIs such as `LedgerSMB::Company`?

## Consequences

1. The `Workflow` class needs to be extended to become a `LedgerSMB::Workflow`
   which provides actions and conditions access to the database, e.g. through
   a `dbh` or `handle` accessor

## Annotations

