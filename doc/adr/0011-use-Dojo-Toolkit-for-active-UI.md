# 0011 Use Dojo Toolkit for active UI

Date: During 1.3.42 development

## Status

Superseded by [ADR 0105](./0105-change-ui-from-dojo-to-quasar.md)

## Summary

Superseded by ADR 0105. Addresses the original design decision to use 
Dojo toolkit. No longer relevant.

## Context

LedgerSMB's UI is using standard HTML elements and tags, without
CSS for eye candy. People expect more than plain HTML elements these
days, minimally with some CSS for a professional look of their
web applications.

Dojo Toolkit has a lot of market share among web pages and web
applicatinos to achieve not only a professional look, but also an
interactive client, which updates the UI without the need for a
request/response to the server.

Updates to the UI require a full request/response cycle after user
input, which makes for a sluggish experience by modern standards.

## Decision

LedgerSMB will add a professional (by business standards) look and
client-side interactive user-interface.  For this purpose it will
use [Dojo Toolkit](https://dojotoolkit.org/).

In order to apply the new look on existing HTML pages, LedgerSMB
will use Dojo's "parse on page load" capability.  This way, HTML in
responses can be annotated, causing page elements to be converted
into Dojo widgets dynamically.

## Consequences

- Resulting HTML response pages will become dependent on potentially
  many JavaScript, image and CSS files, causing extra files to be
  loaded.
- Dojo Toolkit (which fortunately has no dependencies of its own)
  needs to be distributed with LedgerSMB.
- Resulting HTML response pages will be parsed by Dojo, replacing
  page elements with Dojo widgets, potentially causing flicker while
  the transformation takes place.
- All code and templates which contain HTML needs to be annotated
  with Dojo widget markers to ensure completeness of the parser results.
- All code and templates must ensure unique html-'id' attribute values
  to be assigned in the resulting HTML page: Dojo deals badly with
  duplicate ID values -- even if it might have generated these itself.

## Annotations

[ADR 0015 - JavaScript SPA client using Vue](./0015-js-spa-client-using-vue.md)
[ADR 0027 - Templating with custom web elements](./0027-templating-with-custom-web-elements.md)
[ADR 0105 - Change UI from Dojo to Quasar](./0105-change-ui-from-dojo-to-quasar.md)
