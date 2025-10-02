# 0018 Resource state machine engine with dependency injection

Date: During 1.9 development cycle

## Status

Accepted

## Summary

Addresses the design decisions regarding state machine usage in the Perl layer
using the perl pod WorkFlow, the modification of database state using its 
procedural API, and the need for dependency injection in the state machine.

## Context

ADR [0017 State machines for resource state
management](./0017-state-machines-for-resource-state-management.md) identifies
the need to select a state machine engine for managing state of internal
resources such as invoices, transactions and e-mails.

Considering that the resource state management functionally embeds a business
process (e.g. transaction approval as part of separation of duties), users are
likely to want to customize state machines.  Examples include requiring more
approvers (than the single approver supported out of the box) or introduction
of intermediate steps when sending e-mail (such as adding a legal disclaimer
footer).

Taking the requirement for customizability so far as to require that ultimately
new functionality can be added to the application using new state transitions
(actions) or by replacing actions on existing state transitions, the mechanism
to configure these state machines should be highly flexible -- with the option
to extend the application in ways that were not foreseen at development time.

Based on the design of the application, there are two layers in which the
engine can be placed: the database layer or the application layer (Perl).  It
should be noted that if the engine were positioned in the database layer, the
functionality that can be supported is restricted by the execution environment
of the database -- which is highly restricted and won't e.g. be able to send
e-mail or trigger web services without help from its callers.

The design pattern of ["dependency
injection"](https://en.wikipedia.org/wiki/Dependency_injection) is a powerful
means to add functionality to an application at configuration time by taking
advantage of predefined extension points and interfaces.  This pattern could
serve to fulfill the above requirements.  In the Perl ecosystem, the
[Workflow](https://metacpan.org/pod/Workflow) distribution provides a highly
configurable state machine engine applying dependency injection to configure
all of its 'moving parts' (actions, conditions, state serialization, etc.).

## Decision

1. Resource state management will be implemented using state machines.  The
   selected engine will support the highest degree of customization through
   dependency injection.
2. The level of customization required means that the state machine engine
   will be implemented in the Perl (server) layer of the application.
3. To meet these criteria [Workflow](https://metacpan.org/pod/Workflow) has
   been selected as the state machine engine.

## Consequences

1. In combination with [ADR 0002](), this ADR implies that modification of
   *database* state needs to happen through the procedural database API.
2. A design needs to be created supporting easy customization of state
   machines (further: workflows).

## Annotations

See

* [0104 Business logic in Perl (revised)](./0104-business-logic-in-perl.md)
