# 0014 Creation of a REST web service API -- Custom REST service based on HATEOS

Date: October 2016

**Note**: This is derived from the fact that web services appeared on the roadmap
on 2016-12-11 for the first time.

## Status

Accepted

## Summary

Addresses the design decision regarding REST web service API, documented the API 
using OpenAPI, semantic versioning of the API, and thin client requirements. 

## Context

LedgerSMB's original API, inherited from SQL-Ledger, was simply the form
interfact used by the front-end. This has always been a nightmare to integrate
with -- typos in field names, multiple posts needed to build up an invoice, and
lots of challenges for a client developer to work against.

There has long been demand for a more formal, stable API, and this is something
the project has discussed for many years.

"REST" has been the current style of APIs for quite some time, and several
specific standards have emerged to help API developers reuse patterns that work
in other applications. We considered two of these standards before deciding to
"roll our own":

- GraphQL
- JSON:API

The goal of both of these approaches is to minimize the number of round-trips a
client app needs to make when exchanging data with the server, while providing
self-documentation within the API itself. Both of these are current favorite API
styles among developers at this writing (2023).

However, both suffer from crucial drawbacks for an accounting system. Looking at
an invoice as an example -- not only does it illustrate the problems, it also is
the most desired object to expose via an API.

First the key requirements:

* An invoice has several different formats to represent: json, xml, PDF, HTML.
* An invoice is composed of many different objects: customer account, line items
  referencing parts, line items with calculated amounts, fields on the invoice
itself, and a specific workflow state
* Some of these related objects are independent of the invoice, while others
  (line items) are wholly dependent on the invoice
* The server needs to define and enforce the allowed workflow transitions, and
  the client needs to know which transitions are available for a specific
invoice in a specific state for a specific user

While all of this is possible to do in either GraphQL or JSON:API, both require
a lot of boilerplate to get set up for both client and server for the complexity
of the relationships of the invoice object. These are general purpose tools
being applied to a very specific payload shape -- it's far easier to define the
shape of the payload to meet these requirements directly, than to build up all
the relationships using one of these standards.

So creating our own payload shape simplifies things for both clients and
server-side development.

We will base our API on principles as described in these resources:

- [Bob Jones from RedHat in his July 1st, 2020 blog on REST
  architecture](https://www.redhat.com/en/blog/rest-architecture)
- [Hypermedia as the Engine of Application State
  (HATEOAS)"](https://sookocheff.com/post/api/on-choosing-a-hypermedia-format/).

We will use the defacto standard for documenting web service APIs,
[Swagger/OpenAPI](https://swagger.io/specification/).



## Decision

The project will create a REST web services API with strong HATEOAS to make sure
the server is in control of the process a resource goes through.  The aim being
to keep clients thin and low on maintenance.  The API will be documented using
OpenAPI 3.0.x.  The API will *not* make use of the JSON:API standard, instead
opting to develop our own API practices.  These will include design of:

 * A consistent URL schema, which uses [semantic
   versioning](https://semver.org/) for version numbering
 * OpenAPI documentation of individual endpoints as well as common practices
 * A generic means to convey transitions (HATEOAS)

## Consequences

- A new namespace `/erp/api/` needs to be developed.
- API versioning will happen encoding major version numbers, on the
  `/erp/api/vXX` namespace (where XX is the version number).
- As per semantic versioning, `/erp/api/v0` is the "unstable" API; API endpoints
  will be promoted to `/erp/api/v1` (or higher) once the endpoint has been
sufficiently stabilized.
- Documentation can (and should) be distributed as rendered HTML from the
  OpenAPI documentation.
- Clients need to be 'thin': they will not include knowledge of the process and
  transitions available to mutate a resource -- the server will present these.
- The prior bullet allows for customization of resource specific processes using
  server code and/or server configuration, without impact on the client.

## Annotations
