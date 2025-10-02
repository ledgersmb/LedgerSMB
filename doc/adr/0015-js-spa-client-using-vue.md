# 0015 Creation of a heavier client in the browser using JavaScript and Vue

Date: During 1.10 development cycle

**Note**: Although talk of moving to Vue started a few years earlier, the development
cyle of 1.10 added the actual dependency on Vue.

## Status

Accepted

## Summary

Addresses the design decision to start incorporating Vue components into
the UI, eventually removing the use of Dojo, but keeping the Dojo look and
feel until after all components are converted.

## Context

The initial user interface used by LedgerSMB was static HTML. This type of
interface requires round-tripping user input to the server, to reflect UI
updates associated with actions performed by the user. Complicating factor
with this type of interface is that the server does not have the opportunity
to respond to user interactions. Instead, it receives the state resulting from
user interactions, needing to derive the users intent from the difference
between the original and the resulting state.

The problem of the server needing to second-guess what the user intended,
is aggravated by the fact that - in order to speed up data entry - the server
sends complete forms (instead of partial forms for which deriving intention
would be easier).

The use of Dojo Toolkit (see [ADR 0011](./0011-use-Dojo-Toolkit-for-active-UI.md)
has helped to improve the situation and react to some user interactions. Dojo
has helped the project explore the the impact of a client which is more directly
interacting with the user. On the other hand it has also shown that development
and testing of the client side code is as complex (or more) as developing server
side code. Faster and more robust development methods are required.

While faster, more robust, methods are required, this method needs to support
a "progressive" approach. The following patterns will need to be supported:

 - Server side generated UI must be presented as-is
 - Server side generated UI mixed with Dojo client interactions
 - Client side UI with API (webservice) based server interactions

In other words, a "progressive" approach is required in order to prevent a
"big bang" approach. Several libraries were subject to desk studies to assess
their fit with these goals:

 - Svelte
 - React
 - Vue

Additionally, a proof-of-concept implementation was done with Vue.

## Decision

1. The browser-based client will be implemented as a Single Page Application
   (SPA) JavaScript client in *Vue* - backed by webservice APIs - with a
   "progressive" approach migrating to that state.
2. The user interface will remain Dojo (version 1) based until either:
   1. The complete UI has been converted to Vue; or
   2. Another viable solution is drafted to move big bang to another look-and-feel

   The need to move big bang is to make sure the UI remains a single consistent
   experience.

## Consequences

1. New or rewritten screens need to be implemented using Vue
2. Integration between Vue and Dojo needs to be put into place
3. Infrastructure needs to be developed to create webservices "quickly" and securely

## Annotations

[ADR 0105 - Change UI from Dojo to Quasar](./0105-change-ui-from-dojo-to-quasar.md)
