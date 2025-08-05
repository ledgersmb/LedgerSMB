# 0105 Change UI from Dojo Toolkit to Quasar

Date: 2025-05-30

## Status

Accepted

## Context

In [ADR 0015](./0015-js-spa-client-using-vue.md), it was decided to implement
the browser-based client using Vue.  At this time, some code in the client has
been implemented using this new paradigm, but large parts of the client remain
"old style". Parts that *have* been migrated to Vue include

* The login page at "login.pl"
* The various pages for editing configuration lists (languages, countries,
  price groups, gifis, ...)
* The pages for CSV imports

There are several reasons to require a move away from Dojo (v1; also known as
Dojo Toolkit):

* Dojo Toolkit isn't maintained for a long time anymore
* Dojo's webpack plugin is only marginally maintained; we were lucky to have
  new releases when Webpack had major-version releases
* Both Vue and Dojo operate on the browser's DOM which means they can trip
  each other up (substantial work has been done to make them not collide,
  but new edge cases pop up every now and then)
* Dojo's promise implementation (Deferred) is 'thennable', but not compatible
  with the promise implementation of modern browsers (ES6), possibly leading to
  infinite loops

When the migration to Vue took place, Vue3 was relatively new. The big UI
libraries for Vue2 at the time were Vuetify and Quasar, neither of which was
available for Vue3 yet. The reason to start migrating at the time regardless,
was to open up a way forward.

One of the first challenges worked on to migrate to Vue was the replacement
of the Dojo Tree menu component.  While development of a custom tree component
was tried as a proof of concept, the desire was to have a widget library to
leverage -- hopefully saving development effort.

Fast forward in time, the Vuetify and Quasar libraries are still the big widget
libraries for Vue (with many 'single' Vue widgets also available).  These were
evaluated, keeping the desire in mind to use a tree widget to build the menu with.
At this time, Quasar has a QTree widget. Vuetify has a VTree widget, but that is
only available as part of Vuetify Labs, its experimental incubator.

A proof of concept was conducted with the QTree component to replace the
existing menu.  While not straight forward (due to the lack of mouse events
with keyboard modifiers), it turned out existing behaviour could be maintained.
The same applies to the separator element between the menu and the main content
as well as the password expiration alert (popup) when logging in. With redesign
of the Preferences screen on the way. Benefits are - so far - mostly found on
layout components: dialogs, accordions, tab components, progress elements, etc.

On the down side, Quasar is a "Material Design" widget library, which means the
widgets are very different from the ones in use today with Dojo.  The selection
of Dojo2 or Vuetify would not make a difference, because both are "Material
Design" too. Using these widgets means that the technical difference between
the various screens, becomes very visible to users.


## Decision

The combination of Vue and Quasar provides a way forward to phasing out parts
of the Dojo Toolkit, especially in the area of application layout.

The UI will use Quasar as much as possible, but limited to those areas where
the difference in technical implementation doesn't bleed through into the UI.
This means that the "Material Design" form widgets won't be used until the
application can be converted entirely.


## Consequences

The LedgerSMB browser UI will depend on Vue and Quasar as well as on Dojo Toolkit
(v1) as long as the latter hasn't been entirely phased out. The styling of the
UI widgets will stay close to the styling of the Dojo Toolkit widgets. This does
not necessarily mean the use of the Dojo widgets themselves: As long as the project
is included, its CSS can be used to style other widgets the same way.

## Annotations

