# 0016 State machines for UI state management

Date: During 1.10 development cycle

## Status

Accepted

## Summary

Addresses the design decision to use state machines robot3 (XState) for
UI state management.

## Context

Modern (JavaScript-based) User Interfaces have many components and lots of
concurrent actions going on.  Due to the combination and number of possible
actions being triggered, the integration between components has become
increasingly complex over the years -- especially when considering
asynchronicity and error handling.  See the post ['Modeling UI state using
a finite state machine'](https://xiaoyunyang.github.io/post/modeling-ui-state-using-a-finite-state-machine/)
for an extensive treatment of the topic.

The JavaScript/front-end development community has increasingly been using
[state machines](https://en.wikipedia.org/wiki/Finite-state_machine) and
[state charts](https://en.wikipedia.org/wiki/UML_state_machine) to solve this
issue of complexity.

[XState](https://stately.ai/docs/xstate) is the - by far - largest state
machine engine in the JavaScript ecosystem, featuring over 1 million downloads
per week (ref: 2023-12-02).  It implements the *state chart* state machine
type.  XState however is an extensive library with an extensive 'DSL' to
describe state machines.  There are many alternatives implementing state charts
or state machines that are less extensive.  One such example is
[robot3](https://thisrobot.life/) which is extremely small, supports sub-state
machines and features integration for React, PReact and Lit.  Its DSL is
similarly small and thereby easy to read.  None of the integrations are of
interest for LedgerSMB, but they indicate interest from a wider community.

Considering that with its move to Vue, LedgerSMB is going in the same
direction as other projects -- featuring a rich (JavaScript-based) client
application -- the project similarly needs a way to control the expected
complexity.

Note that - as pointed out by [Alex Russell in his post called 'The market
for lemons'](https://infrequently.org/2023/02/the-market-for-lemons/) - the
client can be rich, but should be lightweight in order, sticking as close
as possible to web standards. (In his [footnote
[1]](https://infrequently.org/2023/02/the-market-for-lemons/#fn-alex-approved-1),
he explains that he considers Vue to fall into that category as well.)

## Decision

The web-based client application will use state machines to make state
management as well as state transition explicit.  Similar to UI composition
with components, will different parts of the UI be governed by their own state
machines.

The state machine library used by the project will be robot3, which uses XState
as an example, but chooses to be as lean as possible in its implementation.

## Consequences

1. Any view or component will come with a state machine to describe and manage
   its internal state and the allowed transitions
2. Components don't change their own state: in response to events (their own or
   events from subcomponents) they invoke state transitions in the component's
   state machine
3. Components listen to state changes in the state machine in order to modify
   their presentation -- potentially triggering state changes to subcomponents,
   which modify their presentation by consequence

## Annotations
