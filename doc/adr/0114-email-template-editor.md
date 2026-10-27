# 0114 Named email templates and editable email drafts

Date: 2026-10-26

## Status

Proposed

## Summary

Addresses the design decisions regarding named email templates with separate
subject and body fields, Template Toolkit rendering, placeholder previews,
and persistent Email drafts shared by the UI and API.

## Context

Issue [#2489](https://github.com/ledgersmb/LedgerSMB/issues/2489) requests
reusable email messages which populate the compose screen and can be edited
before sending. Different purposes, such as an initial invoice and a payment
reminder, require different templates for the same document type.

The document-template editor supports one text payload and a fixed list of
document names. Email needs arbitrary names and separate subject/body fields.
The compose screen already saves persistent Email workflows, with message data
in the `email` table and attachments stored separately. Existing body expansion
uses `<%name%>` substitution.

API clients need the same draft editing and sending capabilities as UI users.
Invoice-email automation discussed in
[#9934](https://github.com/ledgersmb/LedgerSMB/issues/9934) and draft PR
[#9939](https://github.com/ledgersmb/LedgerSMB/pull/9939) must distinguish
retrying delivery of an existing email from intentionally sending another email
for the same invoice.

## Decision

### Named, structured email templates

Add an Email template type, reusing template-management components where
practical without changing document-template semantics.

Email templates have stable identifiers, arbitrary user-assigned names,
separate subject and body source fields, a language, applicability to document
contexts, and active/archived status. Multiple templates may apply to the same
context.

Store subject, body and known metadata in relational fields, consistent with
[0107](./0107-using-postgresql-json-jsonb-data-type.md), rather than encoding a
`SUBJECT:` line in the body.

The initial scope is plain-text subject/body templates. Sender identity,
recipients and attachments remain properties of the Email resource and its
preparation workflow, not instructions embedded in template text.

### Template selection and discovery

Workflows may suggest a default, but users can always change to another
eligible template while composing. The server supplies template IDs, names,
languages and available actions for the draft, following
[0014](./0014-rest-api-not-using-jsonapi.md). UI and API clients do not maintain
their own template lists. Applying a template is a workflow action which
revalidates applicability and permissions.

### Drafts are snapshots, not live template references

Selecting a template copies its subject and body source into the Email draft
and records the template identity and revision used. Editing the draft does
not edit the reusable template. Editing or archiving a template does not change
an already prepared or sent email.

Populate the existing compose fields and allow source editing and rendered
preview. Ask before replacing customized content when changing templates;
API template application must also be explicit and version-checked.

Preserve draft source separately from rendered output. Sent emails are
immutable and retain the exact subject/body submitted to the transport.

### Template Toolkit and missing values

Use Template Toolkit (TT) for new subject/body templates. Preserve legacy
`<%name%>` messages with an explicitly identified legacy renderer.

Provide a documented, context-specific set of variables for authors. Required
variables which are absent produce rendering errors identifying the field and
variable. An explicit default makes a value optional; an empty-string default
intentionally permits no output. Numeric zero must remain a valid value rather
than accidentally selecting a fallback.

Validate syntax and variable references where statically possible. Saving may
retain an incomplete draft; preview reports errors and sending rejects them.
Verify TT's default and strict-variable behavior before choosing the precise
optional-value syntax.

### Placeholder-aware preview

Show a rendered preview of subject and body, with substituted values subtly
highlighted and accessible hover/focus tooltips identifying the originating
placeholder. Do not rely on color alone.

Produce preview provenance as part of server-side rendering, not by searching
the final message for matching values. Escape all displayed source and data.
Preview markup and tooltip metadata must never enter the outgoing email.

Compound TT expressions may involve several inputs; preview attribution must
reflect that without changing the rendered message.

### One Email resource for UI and API

Expose persistent Email resources and their workflow actions through the API.
Both interfaces use the same actions and business validation to:

1. Prepare a draft linked to a source document, selecting a template or using
   a suggested default and preparing the appropriate attachments.
2. Retrieve its editable source, preview, template selection, status and
   available actions.
3. Apply another eligible template or customize draft subject/body.
4. Save without sending, or send the reviewed draft through its workflow.

Drafts are interchangeable between UI and API. Expose editable business fields,
not arbitrary workflow context or internal delivery state. Use the resource
workflows described in
[0017](./0017-state-machines-for-resource-state-management.md) and
[0018](./0018-resource-state-machine-engine-with-dependency-injection.md), with
actions and persistence separated as in
[0101](./0101-separating-concerns-between-persisters-actions.md).

Use version/ETag preconditions to prevent concurrent edits from overwriting
each other. Send the reviewed version, including rendered inputs and attachment
selection, rather than silently regenerating changed content.

### Follow-ups and delivery retries

A follow-up creates a new Email workflow linked to the same invoice or other
source document. Each email has its own template snapshot, draft, attachments
and delivery history. There is no permanent one-email-per-invoice restriction.

A retry targets the same Email resource. Serialize send actions and persist
attempt state to prevent duplicate delivery after confirmed success.
Exactly-once SMTP delivery cannot be guaranteed by database transactions;
uncertain outcomes require reconciliation, not blind resending.

Existing recipient preferences, including "Do not email", and existing
authorization checks continue to apply. Templates do not override them.

## Consequences

* The editor and storage need extension for named, structured email templates.
* UI and API share draft editing and validation; template changes cannot alter
  prepared or historical messages.
* Rendering needs focused tests, a constrained data context, and no executable
  Perl or unrestricted file/template access. Reject header-injection characters.
* Template administration remains a separate privilege from draft editing;
  message and attachment access must respect existing permissions.
* Draft PR #9939 needs Email-scoped rather than invoice-scoped attempt tracking.

### Implementation questions remaining

* Which TT constructs provide strict required-value validation and explicit
  optional defaults while preserving zero? How do empty and undefined differ?
* How are language variants, fallback order, revisions and default selection
  represented and administered?
* How much TT expression provenance can the preview reliably expose, and how
  are compound expressions explained accessibly?
* Which existing saved drafts require migration, and how is their legacy
  renderer identified without changing content?
* How are reviewed expansion data and attachments versioned, and how are
  uncertain delivery outcomes reconciled safely?

Endpoint paths and the detailed schema are left to implementation review.
