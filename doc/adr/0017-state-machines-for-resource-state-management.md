# 0017 State machines for resource state management

Date: During 1.9 development cycle

## Status

Accepted

## Summary

Addresses the design decision to use state machines for managing resources like 
invoices, orders, e-mails, document templates, recurrence patterns, etc.

## Context

The application consists of many, wildly different, types of resources, such
as invoices, orders, e-mails, document templates, recurrence patterns, etc.
Each of these resources has a set of attributes which together imply the state
of the resource *and* the allowable actions to be invoked on it.  As a result,
the developer needs a high level of knowledge of the resource, its implied state
and the allowable invocable actions to keep the application state consistent.

By making both the state of the resource and the invocable actions (state
transitions) explicit, the application provides documentation to less
experienced developers.  Modelling state machines challenges developers to
step out of the context of the code they are writing, considering more broadly
the impact of any planned changes.  Additionally, the application gains built-in
controls to assure its internal state to remain consistent.

Even more: if the state machine allows for introspection, allowing the
developer to query the available list of invocable actions, the state machine
could be used to guide the user through the process (without hard-coding it into
the client).


## Decision

Considering that LedgerSMB is an accounting application and that accounting needs
the most stringent controls on consistency of the internal state available, state
machines will be used to keep track of internal resources such as invoices,
gl transactions and e-mails.

## Consequences

1. A state machine engine must be selected
2. Existing resources must be enhanced with state machines
   and their implied state must be reverse-engineered
3. New resources must not be introduced without state machines
4. A design needs to be created mapping available state machine
   actions to web-API responses and requests to trigger actions

## Annotations

[ADR 0018](./0018-resource-state-machine-engine-with-dependency-injection.md)
describes the decision requested by Consequence #1.
