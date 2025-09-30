# 0000 Use of Architecture Decision Records

Date: 2023-05-08

## Status

Accepted

## Summary

Addresses the design decision to use ADRs to describe 
most important decisions that impact the structure and future
direction of the code base. 

## Context

As in many Open Source projects, most of the important decisions
that have been taken over the years are knowledge of the long-time
contributors.  No other records of these decisions exist, but they
do explain the current structure and govern the development of the
software.

Oftentimes, changes of direction and introduction of new technologies
are being discussed in the chat channel, but those do not persist
and have too little structure to provide a clear record.

## Decision

We will use ADRs (architecture Decision Records) to describe the
most important decisions that impact the structure and future
direction of the code base.  We will use this process as historic
documentation and explanation to newcomers. The process will also
serve to structure desicion taking: to clarify reasons underlying
a proposal before the decision is taken.

The following process applies to the creation or amendment of an
ADR:
* A proposal is submitted by opening a pull request with the changes
* Comments to the proposal must be made to the pull request; in
  case a proposal is discussed through other channels, the conversation
  must be summarized and conclusion posted on the pull request
* The proposal can be amended based on the comments received
* The process of revision continues until
  * the project members explicitly reach consensus over the proposal; or
  * 72 hours expire without further comments (and all prior comments
    have been integrated); or
  * 7 days expire without resolution of (some of) the outstanding
    comments

In the first two cases the proposal is considered to be accepted. In the
last case, the proposal is considered to be rejected.  Discussion be
continued, even after the 7 days expire, if there's consensus among
contributors that it's beneficial to do so.

## Consequences

- Developers need to be aware of the formal decisioning process
- An ADR will need to be written and discussed/decided upon before
  new technology can be introduced in the code base
- Introduction of new design patterns may mean decommissioning of
  design patterns that were agreed upon in an earlier ADR, which
  means the old ADR needs to be marked Deprecated as part of the
  acceptance of the new ADR

